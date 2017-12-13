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
