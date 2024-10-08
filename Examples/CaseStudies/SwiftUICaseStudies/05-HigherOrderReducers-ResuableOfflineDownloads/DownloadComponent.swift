import ComposableArchitecture
import SwiftUI

@Reducer
struct DownloadComponent {
  @ObservableState
  struct State: Equatable {
    @Presents var alert: AlertState<Action.Alert>?
    let id: AnyHashable
    var mode: Mode = .notDownloaded
    let url: URL
  }

  enum Action {
    case alert(PresentationAction<Alert>)
    case buttonTapped
    case downloadClient(Result<DownloadClient.Event, any Error>)

    @CasePathable
    enum Alert {
      case deleteButtonTapped
      case stopButtonTapped
    }
  }

  @Dependency(\.downloadClient) var downloadClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .alert(.presented(.deleteButtonTapped)):
        state.mode = .notDownloaded
        return .none

      case .alert(.presented(.stopButtonTapped)):
        state.mode = .notDownloaded
        return .cancel(id: state.id)

      case .alert:
        return .none

      case .buttonTapped:
        switch state.mode {
        case .downloaded:
          state.alert = deleteAlert
          return .none

        case .downloading:
          state.alert = stopAlert
          return .none

        case .notDownloaded:
          state.mode = .startingToDownload

          return .run { [url = state.url] send in
            for try await event in self.downloadClient.download(url: url) {
              await send(.downloadClient(.success(event)), animation: .default)
            }
          } catch: { error, send in
            await send(.downloadClient(.failure(error)), animation: .default)
          }
          .cancellable(id: state.id)

        case .startingToDownload:
          state.alert = stopAlert
          return .none
        }

      case .downloadClient(.success(.response)):
        state.mode = .downloaded
        state.alert = nil
        return .none

      case let .downloadClient(.success(.updateProgress(progress))):
        state.mode = .downloading(progress: progress)
        return .none

      case .downloadClient(.failure):
        state.mode = .notDownloaded
        state.alert = nil
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }

  private var deleteAlert: AlertState<Action.Alert> {
    AlertState {
      TextState("Do you want to delete this map from your offline storage?")
    } actions: {
      ButtonState(role: .destructive, action: .send(.deleteButtonTapped, animation: .default)) {
        TextState("Delete")
      }
      self.nevermindButton
    }
  }

  private var stopAlert: AlertState<Action.Alert> {
    AlertState {
      TextState("Do you want to stop downloading this map?")
    } actions: {
      ButtonState(role: .destructive, action: .send(.stopButtonTapped, animation: .default)) {
        TextState("Stop")
      }
      self.nevermindButton
    }
  }

  private var nevermindButton: ButtonState<Action.Alert> {
    ButtonState(role: .cancel) {
      TextState("Nevermind")
    }
  }
}

enum Mode: Equatable {
  case downloaded
  case downloading(progress: Double)
  case notDownloaded
  case startingToDownload

  var progress: Double {
    if case let .downloading(progress) = self { return progress }
    return 0
  }

  var isDownloading: Bool {
    switch self {
    case .downloaded, .notDownloaded:
      return false
    case .downloading, .startingToDownload:
      return true
    }
  }
}

struct DownloadComponentView: View {
  @State var isVisible = false
  @Bindable var store: StoreOf<DownloadComponent>

  var body: some View {
    VStack {
      if isVisible {
        button
          .alert($store.scope(state: \.alert, action: \.alert))
      } else {
        button
      }
    }
    .onAppear { isVisible = true }
    .onDisappear { isVisible = false }
  }

  @MainActor
  private var button: some View {
    Button {
      store.send(.buttonTapped)
    } label: {
      if store.mode == .downloaded {
        Image(systemName: "checkmark.circle")
          .tint(.accentColor)
      } else if store.mode.progress > 0 {
        ZStack {
          CircularProgressView(value: store.mode.progress)
            .frame(width: 16, height: 16)
          Rectangle()
            .frame(width: 6, height: 6)
        }
      } else if store.mode == .notDownloaded {
        Image(systemName: "icloud.and.arrow.down")
      } else if store.mode == .startingToDownload {
        ZStack {
          ProgressView()
          Rectangle()
            .frame(width: 6, height: 6)
        }
      }
    }
    .buttonStyle(.borderless)
    .foregroundStyle(.primary)
  }
}

#Preview {
  DownloadComponentView(
    store: Store(
      initialState: DownloadComponent.State(
        id: "deadbeef",
        mode: .notDownloaded,
        url: URL(fileURLWithPath: "/")
      )
    ) {}
  )
}
