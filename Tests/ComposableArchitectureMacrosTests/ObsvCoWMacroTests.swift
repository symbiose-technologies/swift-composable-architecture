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
#if canImport(ComposableArchitectureMacros)
import ComposableArchitectureMacros
import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

/*
 
 static let cowMacroName = "ObsvCoW"
 static let cowStatePropertyWrapperName = "CoWState"
   
 
 
 
 static let presentsMacroName = "Presents"
 static let presentationStatePropertyWrapperName = "PresentationState"
 
 
 
 */


final class ObservationCoWMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            // isRecording: true,
            macros: [ObsvCoWMacro.self]
        ) {
            super.invokeTest()
        }
    }

    
    func testBasics() {
        assertMacro {
            """
            struct State {
                @ObsvCoW var state: SomeState
            }
            """
        } expansion: {
            #"""
            struct State {
                var state: SomeState {
                    @storageRestrictions(initializes: _state)
                    init(initialValue) {
                        _state = CoWState(wrappedValue: initialValue)
                    }
                    get {
                        _$observationRegistrar.access(self, keyPath: \.state)
                        return _state.wrappedValue
                    }
                    set {
                        _$observationRegistrar.mutate(self, keyPath: \.state, &_state.wrappedValue, newValue, _$isIdentityEqual)
                    }
                }
            
                @ObservationStateIgnored private var _state: ComposableArchitecture.CoWState<SomeState>
            }
            """#
        }
    }
    
    
    
    func testBasics2() {
        assertMacro {
            """
            struct State {
                @ObsvCoW var state: SomeState?
            }
            """
        } expansion: {
            #"""
            struct State {
                var state: SomeState? {
                    @storageRestrictions(initializes: _state)
                    init(initialValue) {
                        _state = CoWState(wrappedValue: initialValue)
                    }
                    get {
                        _$observationRegistrar.access(self, keyPath: \.state)
                        return _state.wrappedValue
                    }
                    set {
                        _$observationRegistrar.mutate(self, keyPath: \.state, &_state.wrappedValue, newValue, _$isIdentityEqual)
                    }
                }

                @ObservationStateIgnored private var _state: ComposableArchitecture.CoWState<SomeState?>
            }
            """#
        }
    }
    //                @ObservationStateIgnored private var _state = ComposableArchitecture.CoWState<SomeState>(wrappedValue: nil)

    
//    func testBasics() {
//        assertMacro {
//            """
//            struct State {
//                @ObsvCoW var state: SomeState
//            }
//            """
//        } expansion: {
//            #"""
//            struct State {
//                var state: SomeState {
//                    @storageRestrictions(initializes: _state)
//                    init(initialValue) {
//                        _state = CoWState(wrappedValue: initialValue)
//                    }
//                    get {
//                        _$observationRegistrar.access(self, keyPath: \.state)
//                        return _state.wrappedValue
//                    }
//                    set {
//                        _$observationRegistrar.mutate(self, keyPath: \.state, &_state.wrappedValue, newValue, _$isIdentityEqual)
//                    }
//                }
//
//                var $state: SomeState {
//                    get {
//                        _$observationRegistrar.access(self, keyPath: \.state)
//                        return _state.projectedValue
//                    }
//                    set {
//                        _$observationRegistrar.mutate(self, keyPath: \.state, &_state.projectedValue, newValue, _$isIdentityEqual)
//                    }
//                }
//
//                @ObservationStateIgnored private var _state = ComposableArchitecture.CoWState<SomeState>(wrappedValue: nil)
//            }
//            """#
//        }
//    }
//    
//    
//    
//    func testBasics2() {
//        assertMacro {
//            """
//            struct State {
//                @ObsvCoW var state: SomeState?
//            }
//            """
//        } expansion: {
//            #"""
//            struct State {
//                var state: SomeState? {
//                    @storageRestrictions(initializes: _state)
//                    init(initialValue) {
//                        _state = CoWState(wrappedValue: initialValue)
//                    }
//                    get {
//                        _$observationRegistrar.access(self, keyPath: \.state)
//                        return _state.wrappedValue
//                    }
//                    set {
//                        _$observationRegistrar.mutate(self, keyPath: \.state, &_state.wrappedValue, newValue, _$isIdentityEqual)
//                    }
//                }
//
//                var $state: SomeState? {
//                    get {
//                        _$observationRegistrar.access(self, keyPath: \.state)
//                        return _state.projectedValue
//                    }
//                    set {
//                        _$observationRegistrar.mutate(self, keyPath: \.state, &_state.projectedValue, newValue, _$isIdentityEqual)
//                    }
//                }
//
//                @ObservationStateIgnored private var _state = ComposableArchitecture.CoWState<SomeState>(wrappedValue: nil)
//            }
//            """#
//        }
//    }
}
#endif
