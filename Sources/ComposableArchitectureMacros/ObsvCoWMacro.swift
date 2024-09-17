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

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum ObsvCoWMacro {
}

extension ObsvCoWMacro: AccessorMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: D,
    in context: C
  ) throws -> [AccessorDeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      property.isValidForCoW,
      let identifier = property.identifier?.trimmed
    else {
      return []
    }

    let initAccessor: AccessorDeclSyntax =
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
      _\(identifier) = CoWState(wrappedValue: initialValue)
      }
      """

    let getAccessor: AccessorDeclSyntax =
      """
      get {
      _$observationRegistrar.access(self, keyPath: \\.\(identifier))
      return _\(identifier).wrappedValue
      }
      """

    let setAccessor: AccessorDeclSyntax =
      """
      set {
      _$observationRegistrar.mutate(self, keyPath: \\.\(identifier), &_\(identifier).wrappedValue, newValue, _$isIdentityEqual)
      }
      """

    // TODO: _modify accessor?

    return [initAccessor, getAccessor, setAccessor]
  }
}

extension ObsvCoWMacro: PeerMacro {
  public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingPeersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    guard
      let property = declaration.as(VariableDeclSyntax.self),
      property.isValidForCoW
    else {
      return []
    }

    let wrapped = DeclSyntax(
      property.privateWrapped(addingAttribute: ObservableStateMacro.ignoredAttribute)
    )
//    let projected = DeclSyntax(property.projected)
      
    return [
//      projected,
      wrapped
    ]
  }
}

extension VariableDeclSyntax {
  fileprivate func privateWrapped(
    addingAttribute attribute: AttributeSyntax
  ) -> VariableDeclSyntax {
    var attributes = self.attributes
    for index in attributes.indices.reversed() {
      let attribute = attributes[index]
      switch attribute {
      case let .attribute(attribute):
        if attribute.attributeName.tokens(viewMode: .all).map(\.tokenKind) == [
          .identifier("ObsvCoW")
        ] {
          attributes.remove(at: index)
        }
      default:
        break
      }
    }
    let newAttributes = attributes + [.attribute(attribute)]
    return VariableDeclSyntax(
      leadingTrivia: leadingTrivia,
      attributes: newAttributes,
      modifiers: modifiers.privatePrefixed("_"),
      bindingSpecifier: TokenSyntax(
        bindingSpecifier.tokenKind, trailingTrivia: .space,
        presence: .present
      ),
      bindings: bindings.privateWrapped,
      trailingTrivia: trailingTrivia
    )
  }

  fileprivate var projected: VariableDeclSyntax {
    VariableDeclSyntax(
      leadingTrivia: leadingTrivia,
      modifiers: modifiers,
      bindingSpecifier: TokenSyntax(
        bindingSpecifier.tokenKind, trailingTrivia: .space,
        presence: .present
      ),
      bindings: bindings.projected,
      trailingTrivia: trailingTrivia
    )
  }

    fileprivate var isValidForCoW: Bool {
      !isComputed && isInstance && !isImmutable && identifier != nil
    }
  fileprivate var isValidForPresentation: Bool {
    !isComputed && isInstance && !isImmutable && identifier != nil
  }
}

extension PatternBindingListSyntax {
  fileprivate var privateWrapped: PatternBindingListSyntax {
    var bindings = self
    for index in bindings.indices {
      var binding = bindings[index]
        
        if let bindingTypeAnnotation = binding.typeAnnotation {
            binding.typeAnnotation = TypeAnnotationSyntax(
                type: " ComposableArchitecture.CoWState<\(raw: bindingTypeAnnotation.type)>" as TypeSyntax
              )
            
            
        }
        
//      if let optionalType = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) {
//        binding.typeAnnotation = nil
//        binding.initializer = InitializerClauseSyntax(
//          value: FunctionCallExprSyntax(
//            calledExpression: optionalType.wrappedType.cowWrapped,
//            leftParen: .leftParenToken(),
//            arguments: [
//              LabeledExprSyntax(
//                label: "wrappedValue",
//                expression: binding.initializer?.value ?? ExprSyntax(NilLiteralExprSyntax())
//              )
//            ],
//            rightParen: .rightParenToken()
//          )
//        )
//      } else {
//          if let bindingTypeAnnotation = binding.typeAnnotation {
//              binding.typeAnnotation = TypeAnnotationSyntax(
//                  type: " ComposableArchitecture.CoWState<\(raw: bindingTypeAnnotation.type)>" as TypeSyntax
//                )
//          }
//      }
        
//        else if let nonOptTypeAnnotation = binding.typeAnnotation {
//          binding.typeAnnotation = nil
//          binding.initializer = InitializerClauseSyntax(
//            value: FunctionCallExprSyntax(
//              calledExpression: nonOptTypeAnnotation.type.cowWrapped,
//              leftParen: .leftParenToken(),
//              arguments: [
//                LabeledExprSyntax(
//                  label: "wrappedValue", //BUG HERE!
//                  expression: binding.initializer?.value ?? ExprSyntax(NilLiteralExprSyntax())
//                )
//              ],
//              rightParen: .rightParenToken()
//            )
//          )
//      }
        
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        bindings[index] = PatternBindingSyntax(
          leadingTrivia: binding.leadingTrivia,
          pattern: IdentifierPatternSyntax(
            leadingTrivia: identifier.leadingTrivia,
            identifier: identifier.identifier.privatePrefixed("_"),
            trailingTrivia: identifier.trailingTrivia
          ),
          typeAnnotation: binding.typeAnnotation,
          initializer: binding.initializer,
          accessorBlock: binding.accessorBlock,
          trailingComma: binding.trailingComma,
          trailingTrivia: binding.trailingTrivia
        )
      }
    }

    return bindings
  }

  fileprivate var projected: PatternBindingListSyntax {
    var bindings = self
    for index in bindings.indices {
      var binding = bindings[index]
      if let optionalType = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) {
        binding.typeAnnotation?.type = TypeSyntax(
          IdentifierTypeSyntax(
            name: .identifier(optionalType.wrappedType.cowWrapped.trimmedDescription)
          )
        )
      } else {
          
      }
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        bindings[index] = PatternBindingSyntax(
          leadingTrivia: binding.leadingTrivia,
          pattern: IdentifierPatternSyntax(
            leadingTrivia: identifier.leadingTrivia,
            identifier: identifier.identifier.privatePrefixed("$"),
            trailingTrivia: identifier.trailingTrivia
          ),
          typeAnnotation: binding.typeAnnotation,
          accessorBlock: AccessorBlockSyntax(
            accessors: .accessors([
              """
              get {
              _$observationRegistrar.access(self, keyPath: \\.\(identifier))
              return _\(identifier.identifier).projectedValue
              }
              """,
              """
              set {
              _$observationRegistrar.mutate(self, keyPath: \\.\(identifier), &_\(identifier).projectedValue, newValue, _$isIdentityEqual)
              }
              """,
            ])
          )
        )
      }
    }

    return bindings
  }
}

extension TypeSyntax {
  fileprivate var cowWrapped: GenericSpecializationExprSyntax {
    GenericSpecializationExprSyntax(
      expression: MemberAccessExprSyntax(
        base: DeclReferenceExprSyntax(baseName: "ComposableArchitecture"),
        name: "CoWState"
      ),
      genericArgumentClause: GenericArgumentClauseSyntax(
        arguments: [
          GenericArgumentSyntax(
            argument: self
          )
        ]
      )
    )
  }
}
