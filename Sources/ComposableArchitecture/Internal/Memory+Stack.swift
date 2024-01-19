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
// Created by: Ryan Mckinney on 1/18/24
//
////////////////////////////////////////////////////////////////////////////////

import Foundation



struct IMemStackState: CustomDebugStringConvertible {
  static var current: Self { .init() }
  static func print() { Swift.print(current) }

  let stackSize: Int
  let used: Int
  let available: Int
  init() {
    let thread = pthread_self()
    let stackSize = pthread_get_stacksize_np(thread)
    var used: Int = 0
    withUnsafeMutablePointer(to: &used) {
      let stackAddress = Int(bitPattern: pthread_get_stackaddr_np(thread))
      $0.pointee = stackAddress - Int(bitPattern: $0)
    }
    self.stackSize = stackSize
    self.used = used
    self.available = stackSize - used
  }

  var usedFraction: Double { Double(used) / Double(stackSize) }
  var availableFraction: Double { 1 - usedFraction }

    
  public var debugDescription: String {
    return """
      Stack state: \
      using \(used) bytes out of \(stackSize), \
      \(String(format: "%.2f%%", usedFraction * 100)) full.
      """
  }
}
