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
// Created by: Ryan Mckinney on 6/8/24
//
////////////////////////////////////////////////////////////////////////////////

import Foundation

#if canImport(Observation)


@usableFromInline final class Ref<T: Equatable>: Equatable {
    public var val: T
    public init(_ v: T) {
        self.val = v
    }

    public static func == (lhs: Ref<T>, rhs: Ref<T>) -> Bool {
        lhs.val == rhs.val
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@propertyWrapper
public struct ObservedBox<T: Equatable>: Equatable, Observable, Perceptible {
    
    @usableFromInline internal var ref: Ref<T>

    @inlinable
    public init(wrappedValue: T) {
        self.ref = Ref(wrappedValue)
    }

    @inlinable
    public static func == (lhs: ObservedBox<T>, rhs: ObservedBox<T>) -> Bool {
        if lhs.ref === rhs.ref {
            return true
        } else {
            return lhs.wrappedValue == rhs.wrappedValue
        }
    }

    @inlinable
    public var wrappedValue: T {
        get {
            access(keyPath: \.ref)
            return ref.val
        }
        set {
            withMutation(keyPath: \.ref) {
                if !isKnownUniquelyReferenced(&ref) {
                    ref = Ref(newValue)
                    return
                }
                ref.val = newValue
            }
        }
    }
    
    // Updated to use ObservationRegistrar instead of PerceptionRegistrar
    private let _$observationRegistrar = ObservationRegistrar()
    
    @usableFromInline
    internal nonisolated func access<Member>(
        keyPath: KeyPath<Self, Member>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        _$observationRegistrar.access(self, keyPath: keyPath)
    }

    @usableFromInline
    internal nonisolated func withMutation<Member, MutationResult>(
        keyPath: KeyPath<Self, Member>,
        _ mutation: () throws -> MutationResult
    ) rethrows -> MutationResult {
        try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }
}


//@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
//@propertyWrapper
//public struct ObservedBox<T: Equatable>: Equatable, Observable, Perceptible {
//    
//    @usableFromInline internal var ref: Ref<T>
//
//    @inlinable
//    public init(wrappedValue: T) {
//        self.ref = Ref(wrappedValue)
//    }
//
//    @inlinable
//    public static func == (lhs: ObservedBox<T>, rhs: ObservedBox<T>) -> Bool {
//        if lhs.ref === rhs.ref {
//            return true
//        } else {
//            return lhs.wrappedValue == rhs.wrappedValue
//        }
//    }
//
//    @inlinable
//    public var wrappedValue: T {
//        get {
//            access(keyPath: \.ref)
//            return ref.val
//        }
//        set {
//            withMutation(keyPath: \.ref) {
//                if !isKnownUniquelyReferenced(&ref) {
//                    ref = Ref(newValue)
//                    return
//                }
//                ref.val = newValue
//            }
//        }
//    }
//    
//    private let _$perceptionRegistrar = Perception.PerceptionRegistrar()
////    private let _$perceptionRegistrar = ObservationRegistrar()
//    
//    @usableFromInline
//    internal nonisolated func access<Member>(
//        keyPath: KeyPath<Self, Member>,
//        file: StaticString = #file,
//        line: UInt = #line
//    ) {
//        _$perceptionRegistrar.access(self, keyPath: keyPath, file: file, line: line)
//    }
//
//    @usableFromInline
//    internal nonisolated func withMutation<Member, MutationResult>(
//        keyPath: KeyPath<Self, Member>,
//        _ mutation: () throws -> MutationResult
//    ) rethrows -> MutationResult {
//        try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
//    }
//}

#endif
