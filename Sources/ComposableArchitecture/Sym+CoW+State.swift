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
// Created by: Ryan Mckinney on 6/13/24
//
////////////////////////////////////////////////////////////////////////////////
@_spi(Reflection) import CasePaths
import Combine


@dynamicMemberLookup
@propertyWrapper
public struct CoWState<State> {
  private class Storage: @unchecked Sendable {
    var state: State
    init(state: State) {
      self.state = state
    }
  }

  private var storage: Storage

  public init(wrappedValue: State) {
    self.storage = Storage(state: wrappedValue)
  }

  public var wrappedValue: State {
    get { self.storage.state }
    set {
      if !isKnownUniquelyReferenced(&self.storage) {
        self.storage = Storage(state: newValue)
      } else {
        self.storage.state = newValue
      }
    }
  }

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  public subscript<Case>(
    dynamicMember keyPath: CaseKeyPath<State, Case>
  ) -> CoWState<Case>?
  where State: CasePathable {
      guard let c = self.wrappedValue[case: keyPath] else {
        return nil
      }
      return CoWState<Case>(wrappedValue: c)
  }

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<State, Member>
  ) -> CoWState<Member> {
    CoWState<Member>(wrappedValue: self.wrappedValue[keyPath: keyPath])
  }

  /// Accesses the value associated with the given case for reading and writing.
  ///
  /// If you use the techniques of tree-based navigation (see <doc:TreeBasedNavigation>), then
  /// you will have a single enum that determines the destinations your feature can navigate to,
  /// and you will hold onto that state using the ``Presents()`` macro:
  ///
  /// ```swift
  /// @ObservableState
  /// struct State {
  ///   @Presents var destination: Destination.State
  /// }
  /// ```
  ///
  /// The `destination` property has a projected value of ``CoWState``, which gives you a
  /// succinct syntax for modifying the data in a particular case of the `Destination` enum, like
  /// so:
  ///
  /// ```swift
  /// state.$destination[case: \.detail]?.alert = AlertState {
  ///   Text("Delete?")
  /// }
  /// ```
  ///
  /// > Important: Accessing the wrong case will result in a runtime warning and test failure.
  public subscript<Case>(case path: CaseKeyPath<State, Case>) -> Case?
  where State: CasePathable {
    _read { yield self[case: AnyCasePath(path)] }
    _modify { yield &self[case: AnyCasePath(path)] }
  }

    @available(
      iOS,
      deprecated: 9999,
      message:
        "Use the version of this subscript with case key paths, instead. See the following migration guide for more information: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Using-case-key-paths"
    )
    @available(
      macOS,
      deprecated: 9999,
      message:
        "Use the version of this subscript with case key paths, instead. See the following migration guide for more information: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Using-case-key-paths"
    )
    @available(
      tvOS,
      deprecated: 9999,
      message:
        "Use the version of this subscript with case key paths, instead. See the following migration guide for more information: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Using-case-key-paths"
    )
    @available(
      watchOS,
      deprecated: 9999,
      message:
        "Use the version of this subscript with case key paths, instead. See the following migration guide for more information: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.4#Using-case-key-paths"
    )
    public subscript<Case>(case path: AnyCasePath<State, Case>) -> Case? {
        _read { yield path.extract(from: self.wrappedValue) }
      _modify {
        let root = self.wrappedValue
          
        var value = path.extract(from: root)
        let success = value != nil
        yield &value
        guard success else {
          var description: String?
          let root = root
          if let metadata = EnumMetadata(State.self),
            let caseName = metadata.caseName(forTag: metadata.tag(of: root))
          {
            description = caseName
          }
          runtimeWarn(
            """
            Can't modify unrelated case\(description.map { " \($0.debugDescription)" } ?? "")
            """
          )
          return
        }
          if let val = value {
              let embedded = path.embed(val)
              self.wrappedValue = embedded
          }
          
//        self.wrappedValue = value.map(path.embed)
      }
    }
    
  func sharesStorage(with other: Self) -> Bool {
    self.storage === other.storage
  }
}

extension CoWState: Equatable where State: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
      return lhs.wrappedValue == rhs.wrappedValue
//    lhs.sharesStorage(with: rhs)
//      || lhs.wrappedValue == rhs.wrappedValue
  }
}

extension CoWState: Hashable where State: Hashable {
  public func hash(into hasher: inout Hasher) {
    self.wrappedValue.hash(into: &hasher)
  }
}

extension CoWState: Sendable where State: Sendable {}

extension CoWState: Decodable where State: Decodable {
  public init(from decoder: Decoder) throws {
    self.init(wrappedValue: try decoder.singleValueContainer().decode(State.self))
  }
}

extension CoWState: Encodable where State: Encodable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.wrappedValue)
  }
}

extension CoWState: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(reflecting: self.wrappedValue)
  }
}
