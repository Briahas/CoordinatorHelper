//
//  Extentions.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 NixSolutions. All rights reserved.
//

import Cocoa

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
