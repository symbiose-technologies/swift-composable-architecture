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
// Created by: Ryan Mckinney on 1/29/24
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
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
    public var body: some View {
      self.content
    }
}


public struct ForEachStoreWithID<
  EachState, EachAction, Data: Collection, ID: Hashable, Content: View
>: DynamicViewContent {
  public let data: Data
  let content: Content

  /// Initializes a structure that computes views on demand from a store on a collection of data and
  /// an identified action.
  ///
  /// - Parameters:
  ///   - store: A store on an identified array of data and an identified action.
  ///   - content: A function that can generate content given a store of an element.
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
        content(id,
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

  @available(
    iOS,
    deprecated: 9999,
    message:
      "Use an 'IdentifiedAction', instead. See the following migration guide for more information:\n\nhttps://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Identified-actions"
  )
  @available(
    macOS,
    deprecated: 9999,
    message:
      "Use an 'IdentifiedAction', instead. See the following migration guide for more information:\n\nhttps://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Identified-actions"
  )
  @available(
    tvOS,
    deprecated: 9999,
    message:
      "Use an 'IdentifiedAction', instead. See the following migration guide for more information:\n\nhttps://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Identified-actions"
  )
  @available(
    watchOS,
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
        content(id,
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


extension Case {
  fileprivate subscript<ID: Hashable, Action>(id id: ID) -> Case<Action>
  where Value == (id: ID, action: Action) {
    Case<Action>(
      embed: { (id: id, action: $0) },
      extract: { $0.id == id ? $0.action : nil }
    )
  }
}
