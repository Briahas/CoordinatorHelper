//
//  Parser.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/14/17.
//  Copyright © 2017 Mike Kholomeev. All rights reserved.
//

import Foundation

class Parser {
    
    func lastPosition(for char:Character, at content:String) -> String.Index? {
        let insertIndex = content.reversed().index(of: char)?.base
        return insertIndex
    }
}
