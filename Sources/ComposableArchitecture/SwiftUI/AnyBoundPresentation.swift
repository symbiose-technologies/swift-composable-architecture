//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/15/23.
//

import Foundation
import SwiftUI

extension View {
  public func boundPresentation<State, Action, Content: View>(
    store: Store<PresentationState<State>, PresentationAction<Action>>,
    @ViewBuilder content: @escaping (Store<State, Action>, Binding<Bool>) -> Content
  ) -> some View {
    self.boundPresentation(store: store, state: { $0 }, action: { $0 }, content: content)
  }

  public func boundPresentation<State, Action, DestinationState, DestinationAction, Content: View>(
    store: Store<PresentationState<State>, PresentationAction<Action>>,
    state toDestinationState: @escaping (State) -> DestinationState?,
    action fromDestinationAction: @escaping (DestinationAction) -> Action,
    @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>, Binding<Bool>) -> Content
  ) -> some View {
    self.modifier(
        AnyBoundPresentationModifier(
        store: store,
        state: toDestinationState,
        action: fromDestinationAction,
        content: content
      )
    )
  }
}

private struct AnyBoundPresentationModifier<
  State,
  Action,
  DestinationState,
  DestinationAction,
  BoundContent: View
>: ViewModifier {
  let store: Store<PresentationState<State>, PresentationAction<Action>>
  @ObservedObject var viewStore: ViewStore<PresentationState<State>, PresentationAction<Action>>
  let toDestinationState: (State) -> DestinationState?
  let fromDestinationAction: (DestinationAction) -> Action
  let boundContent: (Store<DestinationState, DestinationAction>, Binding<Bool>) -> BoundContent

  init(
    store: Store<PresentationState<State>, PresentationAction<Action>>,
    state toDestinationState: @escaping (State) -> DestinationState?,
    action fromDestinationAction: @escaping (DestinationAction) -> Action,
    content boundContent: @escaping (Store<DestinationState, DestinationAction>, Binding<Bool>) -> BoundContent
  ) {
    let filteredStore = store.filterSend { state, _ in state.wrappedValue != nil }
    self.store = filteredStore
    self.viewStore = ViewStore(
      filteredStore,
      removeDuplicates: { $0.id == $1.id }
    )
    self.toDestinationState = toDestinationState
    self.fromDestinationAction = fromDestinationAction
    self.boundContent = boundContent
  }

  func body(content: Content) -> some View {
    let id = self.viewStore.id
      
      content
//    content.sheet(
//      item: Binding( // TODO: do proper binding
//        get: {
//          self.viewStore.wrappedValue.flatMap(self.toDestinationState) != nil
//          ? self.viewStore.id
//          : nil
//        },
//        set: { newState in
//          if newState == nil, self.viewStore.wrappedValue != nil, self.viewStore.id == id {
//            self.viewStore.send(.dismiss)
//          }
//        }
//      )
//    ) { _ in
//      IfLetStore(
//        self.store.scope(
//          state: returningLastNonNilValue { $0.wrappedValue.flatMap(self.toDestinationState) },
//          action: { .presented(self.fromDestinationAction($0)) }
//        ),
//        then: self.sheetContent
//      )
//    }
  }
}
