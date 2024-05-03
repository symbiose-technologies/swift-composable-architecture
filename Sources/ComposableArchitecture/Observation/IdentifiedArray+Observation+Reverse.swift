//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// 
// Created by: Ryan Mckinney on 1/30/24
//
////////////////////////////////////////////////////////////////////////////////
#if canImport(Perception)
  import OrderedCollections
  import SwiftUI


extension Store where State: ObservableState {

    // New reverse scope function
    public func reverseScope<ElementID, ElementState, ElementAction>(
      state: KeyPath<State, IdentifiedArray<ElementID, ElementState>>,
      action: CaseKeyPath<Action, IdentifiedAction<ElementID, ElementAction>>
    ) -> _ReverseStoreCollection<ElementID, ElementState, ElementAction> {
      #if DEBUG
        if !self.canCacheChildren {
          runtimeWarn(
            """
            Scoping from uncached \(self) in reverse is not compatible with observation. Ensure that all \
            parent store scoping operations take key paths and case key paths instead of transform \
            functions, which have been deprecated.
            """
          )
        }
      #endif
      return _ReverseStoreCollection(self.scope(state: state, action: action))
    }
}

public struct _ReverseStoreCollection<ID: Hashable, State, Action>: RandomAccessCollection {
  private let store: Store<IdentifiedArray<ID, State>, IdentifiedAction<ID, Action>>
  private let data: IdentifiedArray<ID, State>

  fileprivate init(_ store: Store<IdentifiedArray<ID, State>, IdentifiedAction<ID, Action>>) {
    self.store = store
      self.data = store.withState { $0.reversedCp() }
  }

  public var startIndex: Int { self.data.startIndex }
  public var endIndex: Int { self.data.endIndex }
  public subscript(position: Int) -> Store<State, Action> {
    guard self.data.indices.contains(position)
    else {
      return Store()
    }
    let id = self.data.ids[position]
    var element = self.data[position]
    return self.store.scope(
      id: self.store.id(state: \.[id:id]!, action: \.[id:id]),
      state: ToState {
        element = $0[id: id] ?? element
        return element
      },
      action: { .element(id: id, action: $0) },
      isInvalid: { !$0.ids.contains(id) }
    )
  }
}
//public struct _ReverseStoreCollection<ID: Hashable, State, Action>: RandomAccessCollection {
//    private let store: Store<IdentifiedArray<ID, State>, IdentifiedAction<ID, Action>>
//    private let data: [State]
//    private let ids: [ID]
//
//    fileprivate init(_ store: Store<IdentifiedArray<ID, State>, IdentifiedAction<ID, Action>>) {
//        let dataArray = store.withState { $0.array }
//        self.store = store
//        self.data = dataArray.reversed()
//        self.ids = dataArray.map { $0.id }.reversed()
//    }
//
//    public var startIndex: Int { data.startIndex }
//    public var endIndex: Int { data.endIndex }
//
//    public subscript(position: Int) -> Store<State, Action> {
//        guard data.indices.contains(position)
//        else {
//            return Store()
//        }
//        let id = ids[position]
//        var element = data[position]
//        return self.store.scope(
//            id: self.store.id(state: \.[id:id]!, action: \.[id:id]),
//            state: ToState {
//                element = $0[id: id] ?? element
//                return element
//            },
//            action: { .element(id: id, action: $0) },
//            isInvalid: { !$0.ids.contains(id) }
//        )
//    }
//}

#endif
