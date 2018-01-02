//
//  TextFunc.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 1/2/18.
//  Copyright © 2018 NixSolutions. All rights reserved.
//

import Foundation
import Files

class TextFunc {
    class func insert(_ text:String, into file:File) {
        let parser = Parser()
        
        guard
            let content = try? file.readAsString(),
            let index = parser.lastPosition(for: "}", at: content)
            else { return}
        
        var newContent = content
        let insertedIndex = content.index(before: index)
        newContent.insert(contentsOf:text, at: insertedIndex)
        
        do {
            try file.write(string: newContent)
        } catch {
            print(error)
        }
    }
}
