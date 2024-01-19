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
// Created by: Ryan Mckinney on 7/7/23
//
////////////////////////////////////////////////////////////////////////////////
import OrderedCollections
import SwiftUI
import IdentifiedCollections

extension IdentifiedArray {
    func reversedCp() -> Self {
        var cp = self
        cp.reverse()
        return cp
    }
}


public struct ForEachStoreReversed<
    EachState, EachAction, Data: Collection, ID: Hashable, Content: View
>: DynamicViewContent {
    public let data: Data
    let content: Content

    public init<EachContent>(
        _ store: Store<IdentifiedArray<ID, EachState>, IdentifiedAction<ID, EachAction>>,
        @ViewBuilder content: @escaping (_ store: Store<EachState, EachAction>) -> EachContent
    )
    where
        Data == IdentifiedArray<ID, EachState>,
        Content == WithViewStore<
            IdentifiedArray<ID, EachState>, IdentifiedAction<ID, EachAction>,
            ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>
        >
    {
        self.data = store.withState { $0 }
        self.content = WithViewStore(
            store,
            observe: { $0.reversedCp() },
            removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
        ) { viewStore in
            // Convert the reversed collection into an Array
            ForEach(viewStore.state, id: viewStore.state.id) { element in
                let id = element[keyPath: viewStore.state.id]
                var element = element
                content(
                    store.scope(
                        id: store.id(state: \.[id: id]!, action: \.[id: id]),
                        state: ToState {
                            element = $0[id: id] ?? element
                            return element
                        },
                        action: { .element(id: id, action: $0) },
                        isInvalid: { !$0.ids.contains(id) }
                    )
                )
            }
        }
    }
    
//    public init<EachContent>(
//        _ store: Store<IdentifiedArray<ID, EachState>, IdentifiedAction<ID, EachAction>>,
//        @ViewBuilder content: @escaping (_ store: Store<EachState, EachAction>) -> EachContent
//    )
//    where
//        Data == IdentifiedArray<ID, EachState>,
//        Content == WithViewStore<
//            IdentifiedArray<ID, EachState>, IdentifiedAction<ID, EachAction>,
//            ForEach<ReversedCollection<ID>, ID, EachContent> // Changed from [EachState] to [ID]
//        >
//    {
//        self.data = store.withState { $0 }
//        self.content = WithViewStore(
//            store,
//            observe: { $0 },
//            removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
//        ) { viewStore in
//            let t = viewStore.state.ids.
////            let reversedIDs = viewStore.state.ids.elements.reversed() // Changed to iterate over IDs
//            ForEach(t, id: \.self) { id in // Iterate over IDs
//                guard let element = viewStore.state[id] else { EmptyView() } // Safely unwrap element
//                var elementCopy = element // Copy of element for mutation
//                content(
//                    store.scope(
//                        id: store.id(state: \.[id: id]!, action: \.[id: id]),
//                        state: ToState {
//                            elementCopy = $0[id] ?? elementCopy
//                            return elementCopy
//                        },
//                        action: { .element(id: id, action: $0) },
//                        isInvalid: { !$0.ids.contains(id) }
//                    )
//                )
//            }
//        }
//    }
    
    
    public var body: some View {
      self.content
    }
}

public struct ForEachStoreWithID<
  EachState, EachAction, Data: Collection, ID: Hashable, Content: View
>: DynamicViewContent {
  public let data: Data
  let content: Content

  public init<EachContent>(
    _ store: Store<IdentifiedArray<ID, EachState>, IdentifiedAction<ID, EachAction>>,
    @ViewBuilder content: @escaping (_ id: ID, _ store: Store<EachState, EachAction>) -> EachContent
  )
  where
    Data == IdentifiedArray<ID, EachState>,
    Content == WithViewStore<
      IdentifiedArray<ID, EachState>, IdentifiedAction<ID, EachAction>,
      ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>
    >
  {
    self.data = store.withState { $0 }
    self.content = WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
    ) { viewStore in
      ForEach(viewStore.state, id: viewStore.state.id) { element in
        let id = element[keyPath: viewStore.state.id]
        var element = element
        content(
          id,
          store.scope(
            id: store.id(state: \.[id:id]!, action: \.[id:id]),
            state: ToState {
              element = $0[id: id] ?? element
              return element
            },
            action: { .element(id: id, action: $0) },
            isInvalid: { !$0.ids.contains(id) }
          )
        )
      }
    }
  }

  // Copy of the deprecated initializer, modified to include ID in the content closure
    @available(
      iOS,
      deprecated: 9999,
      message:
        "Use an 'IdentifiedAction', instead. See the following migration guide for more information:\n\nhttps://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Identified-actions"
    )
    public init<EachContent>(
    _ store: Store<IdentifiedArray<ID, EachState>, (id: ID, action: EachAction)>,
    @ViewBuilder content: @escaping (_ id: ID, _ store: Store<EachState, EachAction>) -> EachContent
  )
  where
    Data == IdentifiedArray<ID, EachState>,
    Content == WithViewStore<
      IdentifiedArray<ID, EachState>, (id: ID, action: EachAction),
      ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>
    >
  {
    self.data = store.withState { $0 }
    self.content = WithViewStore(
      store,
      observe: { $0 },
      removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
    ) { viewStore in
      ForEach(viewStore.state, id: viewStore.state.id) { element in
        var element = element
        let id = element[keyPath: viewStore.state.id]
        content(
          id,
          store.scope(
            id: store.id(state: \.[id:id]!, action: \.[id:id]),
            state: ToState {
              element = $0[id: id] ?? element
              return element
            },
            action: { (id, $0) },
            isInvalid: { !$0.ids.contains(id) }
          )
        )
      }
    }
  }

  public var body: some View {
    self.content
  }
}


//public struct ForEachStoreWithID<
//  EachState, EachAction, Data: Collection, ID: Hashable, Content: View
//>: DynamicViewContent {
//    public let data: Data
//    let content: Content
//    public init<EachContent>(
//        _ store: Store<IdentifiedArray<ID, EachState>, (id: ID, action: EachAction)>,
//        @ViewBuilder content: @escaping (ID, Store<EachState, EachAction>) -> EachContent
//    )
//    where
//    Data == IdentifiedArray<ID, EachState>,
//    Content == WithViewStore<
//        IdentifiedArray<ID, EachState>, (id: ID, action: EachAction),
//        ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>
//  >
//    {
//        self.data = store.withState { $0 }
//        self.content = WithViewStore(
//          store,
//          observe: { $0 },
//          removeDuplicates: { areOrderedSetsDuplicates($0.ids, $1.ids) }
//        ) { viewStore in
//          ForEach(viewStore.state, id: viewStore.state.id) { element in
//            let id = element[keyPath: viewStore.state.id]
//            var element = element
//              content(id,
//                store.scope(
//                  id: store.id(state: \.[id:id]!, action: \.[id:id]),
//                  state: ToState {
//                    element = $0[id: id] ?? element
//                    return element
//                  },
//                  action: { (id, $0) },
//                  isInvalid: { !$0.ids.contains(id) }
//                )
//              )
//          }
//        }
//        
//    }
// 
//    
//    public var body: some View {
//      self.content
//    }
//    
//    
//}
    
    
extension Case {
  fileprivate subscript<ID: Hashable, Action>(id id: ID) -> Case<Action>
  where Value == (id: ID, action: Action) {
    Case<Action>(
      embed: { (id: id, action: $0) },
      extract: { $0.id == id ? $0.action : nil }
    )
  }
}



