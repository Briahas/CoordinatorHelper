//
//  ProjectStructure.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 1/2/18.
//  Copyright © 2018 Mike Kholomeev. All rights reserved.
//

import Foundation
import Files
import PromiseKit

enum ProjectStructureError : Error {
    case localError(String)
}

enum CreateStates {
    case firstDir, coordDir, logicDir, router, assemblies
}

class ProjectStructure {

    let projectExt = "xcodeproj"
    let workspaceExt = "xcworkspace"
    let swiftExtension = ".swift"
    fileprivate let sourceFolderName = "Source"
    let coordinatorsFolderName = "Coordinators"
    let logicFolderName = "Logic"
    let routerFolderName = "Router"
    let assembliesFolderName = "Assemblies"
    let baseCoordinatorFolderName = "BaseCoordinator"
    
    let assemblyCoordName = "AssemblyCoordinator"
    let assemblyScreenName = "AssemblyScreen"
    let coordinatorFileName = "Coordinator"
    let appdelegateName = "AppDelegate"
    
    fileprivate let mainDir:Folder
//    var state:CreateStates = .firstDir
    fileprivate var projectName = ""
    fileprivate var coordinatorsFolder: Folder?
    fileprivate var coordAssFile: File?
    fileprivate var screenAssFile: File?

    init(with projectDir:Folder) throws {
        self.mainDir = projectDir

        let files = projectDir.subfolders.filter {
            guard
                let ext = $0.extension,
                ext == projectExt || ext == workspaceExt
                else { return false }
            return true
        }
        
        guard
            !files.isEmpty,
            let ff = files.first
            else { throw ProjectStructureError.localError("Not a project folder") }
        
        self.projectName = ff.nameExcludingExtension
    }

    // MARK: - Public
    var isCorrect: Bool {
        guard let _ = try? analyzeWith(creation: false) else { return false }
        
        return true
    }
    
    func performCorrection() throws {
        try analyzeWith(creation: true)
    }

    func isCorrectCoordinator(_ name:String) -> Bool {
        guard
            let parrent = coordinatorsFolder,
            parrent.containsSubfolder(named: name)
            else { return true }
        
        return false
    }

    // MARK: - Private
    fileprivate func analyzeWith(creation:Bool) throws {
        let projectFolder = try mainDir.subfolder(named:projectName, withCreation:creation)
        let sourceDir = try projectFolder.subfolder(named:sourceFolderName, withCreation:creation)
        let coordDir = try sourceDir.subfolder(named:coordinatorsFolderName, withCreation:creation)
        let logicDir = try sourceDir.subfolder(named:logicFolderName, withCreation:creation)
        let routerDir = try logicDir.subfolder(named:routerFolderName, withCreation:creation)
        let assembliesDir = try logicDir.subfolder(named:assembliesFolderName, withCreation:creation)
        let baseCoordinatorDir = try logicDir.subfolder(named:baseCoordinatorFolderName, withCreation:creation)
        
        let baseCoordinatorFile = try baseCoordinatorDir.file(named: baseCoordinatorFolderName+".swift", withCreation:creation)
        let protocolCoordinatorFile = try baseCoordinatorDir.file(named: coordinatorFileName+".swift", withCreation:creation)

        let coordAssFile = try assembliesDir.file(named: assemblyCoordName+".swift", withCreation:creation)
        let screenAssFile = try assembliesDir.file(named: assemblyScreenName+".swift", withCreation:creation)

        self.coordinatorsFolder = coordDir
        self.coordAssFile = coordAssFile
        self.screenAssFile = screenAssFile
    }

    // MARK: Assemblies
    fileprivate func assemblyScreenFileCreate() throws {
        guard let file = screenAssFile else { throw ProjectStructureError.localError("No FiLE \(screenAssFile?.name) 0_0???") }
        TextFunc.insert("1111", into: file)
    }

    fileprivate func assemblyCoordFileCreate(at assembliesDir:Folder) throws {
        guard let file = coordAssFile else { throw ProjectStructureError.localError("No FiLE \(coordAssFile?.name) 0_0???") }
        TextFunc.insert("2222", into: file)
    }
}

