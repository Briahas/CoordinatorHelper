//
//  Extentions.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 Mike Kholomeev. All rights reserved.
//

import Cocoa
import Files

extension NSTextField {
    open override var isEnabled: Bool {
        didSet {
            self.textColor = (isEnabled) ? NSColor.black : NSColor.gray
        }
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    mutating func lowercaseFirstLetter() {
        self = self.lowercasingFirstLetter()
    }
}

extension Folder {
    func subfolder(named:String, withCreation:Bool = false) throws -> Folder {
        if withCreation {
            return try self.createSubfolderIfNeeded(withName:named)
        } else {
            return try self.subfolder(named:named)
        }
    }

    func file(named:String, withCreation:Bool = false) throws -> File {
        if withCreation {
            return try self.createFileIfNeeded(withName:named)
        } else {
            return try self.file(named:named)
        }
    }
}
