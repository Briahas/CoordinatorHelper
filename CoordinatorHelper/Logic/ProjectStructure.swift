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

enum ProjectStructureErrorr : Error {
    case error(String)
}

enum CreateStates {
    case firstDir, coordDir, logicDir, router, assemblies
}

class ProjectStructure {

    let projectExt = "xcodeproj"
    let workspaceExt = "xcworkspace"
    let swiftExtension = ".swift"
    let coordinatorsDirName = "Coordinators"
    let logicDirName = "Logic"
    let routerDirName = "Router"
    let assembliesDirName = "Assemblies"
    
    let assemblyCoordName = "AssemblyCoordinator"
    let assemblyScreenName = "AssemblyScreen"
    let appdelegateName = "AppDelegate"
    
    let projectDir:Folder
//    var state:CreateStates = .firstDir
    var projectName = ""
    
    init(with projectDir:Folder) throws {
        self.projectDir = projectDir

        let files = projectDir.files.filter {
            guard
                let ext = $0.extension,
                ext == projectExt,
                ext == workspaceExt
                else { return false }
            return true
        }
        
        guard
            !files.isEmpty,
            let ff = files.first
            else { throw ProjectStructureErrorr.error("Not a project folder") }
        
        self.projectName = ff.nameExcludingExtension
    }

    // MARK: - Public
    func create() throws {
        let firstDir = try projectDir.createSubfolderIfNeeded(withName: projectName)
        
        let coordDir = try firstDir.createSubfolderIfNeeded(withName: coordinatorsDirName)
        let logicDir = try firstDir.createSubfolderIfNeeded(withName: logicDirName)
        
        let routerDir = try logicDir.createSubfolderIfNeeded(withName: routerDirName)
        let assembliesDir = try logicDir.createSubfolderIfNeeded(withName: assembliesDirName)

        try assemblyCoordFileCreate(at: assembliesDir)
        try assemblyScreenFileCreate(at: assembliesDir)
        
        
        
//        let result =
//            mainDirCreate().then { mainDir in
//                self.logicDirCreate(mainDir).then { logicDir in
//                    self.routerDirCreate(logicDir)
//                        .then { routerDir in
//                            self.routerFileCreate(routerDir)
//                        }.then { routerDir in
//                            self.accembliesDirCreate(logicDir)
//                                .then { accembliesDir in
//                                    self.assemblyFileCreate(named: self.assemblyCoordName, at: accembliesDir)
//
//                                }.then { accembliesDir in
//                                    self.assemblyFileCreate(named: self.assemblyScreenName, at: accembliesDir)
//                            }
//                }
//        }
//
//        return result
    }

    // MARK: - Private
//    fileprivate func stateAnalyze() {
//        switch state {
//        case .firstDir:
//            firstDirCreate()
//        case .coordDir:
//            ()
//        case .logicDir:
//            ()
//        case .router:
//            ()
//        case .assemblies:
//            ()
//        }
//    }
    
    fileprivate func mainDirCreate() -> Promise<Folder> {
        let promise = Promise<Folder> { fulfill, _ in
            let firstDir = try projectDir.createSubfolderIfNeeded(withName: projectName)
            fulfill(firstDir)
        }
        
        return promise
    }

    fileprivate func logicDirCreate(_ mainDir:Folder) -> Promise<Folder> {
        let promise = Promise<Folder> { fulfill, error in
//            let coordDir = try firstDir.createSubfolderIfNeeded(withName: coordinatorsDirName)
            let logicDir = try mainDir.createSubfolderIfNeeded(withName: logicDirName)
            fulfill(logicDir)
        }
        
        return promise
    }

    // MARK: Router
    fileprivate func routerDirCreate(_ logicDir:Folder) -> Promise<Folder> {
        let promise = Promise<Folder> { fulfill, error in
            let routerDir = try logicDir.createSubfolderIfNeeded(withName: routerDirName)
            fulfill(routerDir)
        }
        
        return promise
    }
    
    fileprivate func routerFileCreate(_ routerDir:Folder) -> Promise<File> {
        let promise = Promise<File> { fulfill, error in
            let routerFileName = routerDirName + swiftExtension
            let routerFile = try routerDir.createFileIfNeeded(withName: routerFileName)
            fulfill(routerFile)
        }
        
        return promise
    }
    
    // MARK: Assemblies
    fileprivate func accembliesDirCreate(_ logicDir:Folder) -> Promise<Folder> {
        let promise = Promise<Folder> { fulfill, error in
            let assembliesDir = try logicDir.createSubfolderIfNeeded(withName: assembliesDirName)
            fulfill(assembliesDir)
        }
        
        return promise
    }

    fileprivate func assemblyScreenFileCreate(at assembliesDir:Folder) throws {
        let file = try assemblyFileCreate(named: assemblyScreenName, at: assembliesDir)
        
        TextFunc.insert("1111", into: file)
    }

    fileprivate func assemblyCoordFileCreate(at assembliesDir:Folder) throws {
        let file = try assemblyFileCreate(named: assemblyCoordName, at: assembliesDir)

        TextFunc.insert("2222", into: file)
    }

    fileprivate func assemblyFileCreate(named:String, at assembliesDir:Folder) throws -> File {
        let assemblyFileName = named + swiftExtension
        return try assembliesDir.createFileIfNeeded(withName: assemblyFileName)
    }
}

