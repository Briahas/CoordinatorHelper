//
//  ManagerFlow.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/15/17.
//  Copyright © 2017 NixSolutions. All rights reserved.
//

import Foundation
import Files
import PromiseKit

class ManagerFlow {
    fileprivate let swiftExtention = "swift"
    fileprivate let storyboardExtention = "storyboard"
    
    fileprivate let allFlowsDir:Folder
    fileprivate var flowName = ""
    
    init(in allFlowsDir:Folder) {
        self.allFlowsDir = allFlowsDir
    }
    
    // MARK: - Public
    func create(flow name:String, complition:(Bool)->()) {
        flowName = name
        guard
            flowName.count > 0,
            let folder = try? allFlowsDir.createSubfolder(named: bigName),
            let _ = try? folder.createFile(named: coordFileFullName, contents: coordinatorText()),
            let _ = try? folder.createFile(named: vcFileFullName, contents: vcText())
            else { return complition(false) }
        
        return complition(true)
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
    
    fileprivate func coordinatorText() -> String {
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

        class \(bigName)Coordinator: BaseCoordinator, Coordinator, CoordinatorOutput, \(bigName)CoordinatorDelegate {
        
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
    
    fileprivate func vcText() -> String {
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

        protocol \(bigName)CoordinatorDelegate {
            func didCloseScreen()
        }

        class \(bigName)Screen: UIViewController {
        
            var delegate: \(bigName)CoordinatorDelegate?
        
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
