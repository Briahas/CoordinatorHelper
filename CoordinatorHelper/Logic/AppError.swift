//
//  AppError.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 1/3/18.
//  Copyright © 2018 NixSolutions. All rights reserved.
//

import Foundation

enum AppError : Error {
    case EmptyName
    case NoFiles
    case NoAppDelegateFile
}
