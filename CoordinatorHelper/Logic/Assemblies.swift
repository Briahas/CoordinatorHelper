//
//  Assemblies.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/14/17.
//  Copyright © 2017 Mike Kholomeev. All rights reserved.
//

import Foundation
import Files

class Assemblies {
    let coordinatorAssemblyFile:File
    let screenAssemblyFile:File

    init(coordinatorAssemblyFile:File, screenAssemblyFile:File) {
        self.coordinatorAssemblyFile = coordinatorAssemblyFile
        self.screenAssemblyFile = screenAssemblyFile
    }

    func addCoordinator(with name:String) {
        let insertedCoordinatorText = coordinatorText(with: name)
        let insertedScreenText = screenText(with: name)

        TextFunc.insert(insertedCoordinatorText,
                        into: coordinatorAssemblyFile)
        TextFunc.insert(insertedScreenText,
                        into: screenAssemblyFile)
    }
    
    // MARK: - Private
    fileprivate func coordinatorText(with name:String) -> String {
        let smallName = name.lowercasingFirstLetter()
        let bigName = name.capitalizingFirstLetter()
        
        let importText = """
        //MARK - \(bigName)Coordinator
            lazy var \(smallName)Coordinator: \(bigName)Coordinator = {
                let coordinator = \(bigName)Coordinator(router, assembly:self, screenAssembly:screenAssembly)
                return coordinator
            }()

        """
        
        return importText
    }
    
    fileprivate func screenText(with name:String) -> String {
        let smallName = name.lowercasingFirstLetter()
        let bigName = name.capitalizingFirstLetter()
        
        let importText = """
        //MARK - \(bigName)Screen
            lazy var \(smallName)Screen: \(bigName)Screen = {
                let vc = \(bigName)Screen.instantiateFromStoryboard()
                vc.delegate = delegate
            return vc
            }()
        
        """
        
        return importText
    }
}
