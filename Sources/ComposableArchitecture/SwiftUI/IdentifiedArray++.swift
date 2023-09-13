//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 2/10/23.
//

import Foundation
import IdentifiedCollections

extension IdentifiedArray {
    
    func previousElementFor(id: ID) -> Element? {
        if let elementIdx = self.index(id: id), elementIdx > 0 {
            return elements[elementIdx - 1]
        }
        return nil
    }
    
}
