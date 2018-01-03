//
//  Flows.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/15/17.
//  Copyright © 2017 Mike Kholomeev. All rights reserved.
//

import Foundation
import Files
import PromiseKit

class Flows {
    fileprivate let swiftExtention = "swift"
    fileprivate let storyboardExtention = "storyboard"
    fileprivate let appFlowName = "App"
    fileprivate let mainFlowName = "Main"
    
    fileprivate let allFlowsDir:Folder
    fileprivate var flowName = ""
    
    init(in allFlowsDir:Folder) {
        self.allFlowsDir = allFlowsDir
    }
    
    // MARK: - Public
    func create(flow name:String) throws {
        flowName = name
        guard
            flowName.count > 0
            else { throw AppError.EmptyName }
        let folder = try allFlowsDir.createSubfolder(named: bigName)
        try folder.createFile(named: coordFileFullName, contents: coordinatorText)
        try folder.createFile(named: vcFileFullName, contents: vcText)
    }
    
    func createInitialFlows() throws {
        flowName = appFlowName
        let appFolder = try allFlowsDir.createSubfolder(named: bigName)
        try appFolder.createFile(named: coordFileFullName, contents: appCoordinatorText)
        try create(flow: mainFlowName)
    }
    
    // MARK: - Private
    fileprivate var smallName:String {
        return flowName.lowercasingFirstLetter()
    }
    fileprivate var bigName:String {
        return flowName.capitalizingFirstLetter()
    }
    fileprivate var coordFileFullName:String {
        return bigName + "Coordinator" + "." + swiftExtention
    }
    fileprivate var vcFileFullName:String {
        return bigName + "Screen" + "." + swiftExtention
    }
    
    fileprivate var appCoordinatorText:String {
        let importText = """
        import Foundation

        enum AppState {
            case main
        }

        final class AppCoordinator: BaseCoordinator, Coordinator {
            fileprivate let router: Router
            fileprivate let assembly: AssemblyCoordinator
            
            fileprivate var state: AppState
            
            init(_ router: Router, _ assembly: AssemblyCoordinator) {
                self.router = router
                self.assembly = assembly
                state = .main
            }
            
            func start() {
                switch state {
                case .main:
                    runMainFlow()
                }
            }
            
            fileprivate func runMainFlow() {
                let mainCoordinator = assembly.mainCoordinator
                addDependency(mainCoordinator)
                
                mainCoordinator.finishFlow = { [weak self, weak mainCoordinator] item in
                    self?.router.dismissTopScreen()
                    self?.removeDependency(mainCoordinator)
                    self?.start()
                }
                
                mainCoordinator.start()
            }
        }
        """
        return importText
    }
    
    fileprivate var coordinatorText:String {
        let importText = """
        //
        //  \(bigName)Coordinator.swift
        //  MUSTREPLACENAME
        //
        //  Created by Mike Kholomeev on 12/15/17.
        //  Copyright © 2017 Mike Kholomeev. All rights reserved.
        //

        import Foundation
        import UIKit

        class \(bigName)Coordinator: BaseCoordinator, Coordinator, CoordinatorOutput, \(bigName)ScreenDelegate {
        
            var finishFlow: ((Any) -> Void)?
        
            fileprivate let router: Router
            fileprivate let assembly:AssemblyCoordinator
            fileprivate let screenAssembly: AssemblyScreen
            fileprivate let sourceView: UIView?
        
            init(_ router: Router, assembly: AssemblyCoordinator, screenAssembly: AssemblyScreen, sourceView: UIView) {
                self.router = router
                self.assembly = assembly
                self.screenAssembly = screenAssembly
                self.sourceView = sourceView
            }
        
            fileprivate lazy var \(smallName)VC: \(bigName)Screen = {
                let vc = self.screenAssembly.\(smallName)Screen(delegate:self)
                return vc
            }()
        
            func start() {
                //router.presentModaly(\(smallName)VC, sourceView:sourceView)
                //router.push(\(smallName)VC)
            }
        
            // MARK: - \(bigName)CoordinatorDelegate
            internal func didCloseScreen() {
                finishFlow?(false)
            }
        }
        """
        
        return importText
    }
    
    fileprivate var vcText:String {
        let importText = """
        //
        //  \(bigName)Screen.swift
        //  MUSTREPLACENAME
        //
        //  Created by Mike Kholomeev on 12/15/17.
        //  Copyright © 2017 Mike Kholomeev. All rights reserved.
        //

        import Foundation
        import UIKit

        protocol \(bigName)ScreenDelegate {
            func didCloseScreen()
        }

        class \(bigName)Screen: UIViewController {
        
            var delegate: \(bigName)ScreenDelegate?
        
            @IBOutlet weak var sendButton: UIButton!
            @IBOutlet weak var textLabel: UILabel!
        
            override func viewDidLoad() {
                super.viewDidLoad()
            }
        
            override func viewDidDisappear(_ animated: Bool) {
                delegate?.didCloseScreen()
            }
        
            @IBAction func send(_ sender: Any) {
            }
        
        }
        """
        
        return importText
    }

}
