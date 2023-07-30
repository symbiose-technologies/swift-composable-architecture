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
    _ store: Store<IdentifiedArray<ID, EachState>, (ID, EachAction)>,
    @ViewBuilder content: @escaping (ID, Store<EachState, EachAction>) -> EachContent
  )
  where
    Data == IdentifiedArray<ID, EachState>,
    Content == WithViewStore<
      IdentifiedArray<ID, EachState>, (ID, EachAction),
      ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>
    >
  {
    self.data = store.state.value
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
            state: {
              element = $0[id: id] ?? element
              return element
            },
            action: { (id, $0) }
          )
        )
      }
    }
  }

  public var body: some View {
    self.content
  }
}





public struct ForEachStorePairs<
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
    _ store: Store<IdentifiedArray<ID, EachState>, (ID, EachAction)>,
    @ViewBuilder content: @escaping (ID, Store<EachState, EachAction>) -> EachContent
  )
  where
    Data == IdentifiedArray<ID, EachState>,
    Content == WithViewStore<
      IdentifiedArray<ID, EachState>, (ID, EachAction),
      ForEach<IdentifiedArray<ID, EachState>, ID, EachContent>
    >
  {
    self.data = store.state.value
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
            state: {
              element = $0[id: id] ?? element
              return element
            },
            action: { (id, $0) }
          )
        )
      }
    }
  }

  public var body: some View {
    self.content
  }
}
