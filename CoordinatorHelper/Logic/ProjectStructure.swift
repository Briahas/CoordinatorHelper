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
    fileprivate var projectName = ""
    
    fileprivate var coordinatorsFolder: Folder?
    
    fileprivate var assembliesFolder: Folder?
    fileprivate var coordAssFile: File?
    fileprivate var screenAssFile: File?
    
    fileprivate var routerFolder: Folder?
    fileprivate var routerFile: File?
    
    fileprivate var baseCoordinatorFolder: Folder?
    fileprivate var baseCoordinatorFile: File?
    fileprivate var protocolCoordinatorFile: File?

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
        guard let coordsDir = coordinatorsFolder else { throw AppError.NoFiles }
        try routerFile?.write(string: routerText)
        try baseCoordinatorFile?.write(string: baseCoordinatorText)
        try protocolCoordinatorFile?.write(string: protocolCoordinatorText)
        try coordAssFile?.write(string: textAssemblyCoordinator)
        try screenAssFile?.write(string: textAssemblyScreen)
        try Flows(in: coordsDir).createInitialFlows()

        guard
            let appDelegate = mainDir.makeFileSequence(recursive: true, includeHidden: false)
                .filter({ $0.nameExcludingExtension == appdelegateName }).first
            else { throw AppError.NoAppDelegateFile }
        try TextFunc.insert(appDelegateText, into: appDelegate, insteadOf:appDelegateSubstitutedText)
    }

    func isValidCoordinator(_ name:String) -> Bool {
        guard
            let parrent = coordinatorsFolder,
            parrent.containsSubfolder(named: name)
            else { return true }
        
        return false
    }

    func add(coordinator name:String) throws {
        guard
            let allFlowsDir = coordinatorsFolder,
            let fileC = coordAssFile,
            let fileS = screenAssFile
            else { throw AppError.NoFiles }
        
        let managerAssemblies = Assemblies(coordinatorAssemblyFile: fileC,
                                           screenAssemblyFile: fileS)
        try managerAssemblies.addCoordinatorScreenCreation(named:name)
        try Flows(in: allFlowsDir).create(flow: name)
    }
    
    // MARK: - Private
    fileprivate func analyzeWith(creation:Bool) throws {
        let projectFolder = try mainDir.subfolder(named:projectName, withCreation:creation)
        let sourceDir = try projectFolder.subfolder(named:sourceFolderName, withCreation:creation)
        let coordDir = try sourceDir.subfolder(named:coordinatorsFolderName, withCreation:creation)
        let logicDir = try sourceDir.subfolder(named:logicFolderName, withCreation:creation)
        
        let routerDir = try logicDir.subfolder(named:routerFolderName, withCreation:creation)
        let routerFile = try routerDir.file(named: routerFolderName+".swift", withCreation:creation)

        let assembliesDir = try logicDir.subfolder(named:assembliesFolderName, withCreation:creation)
        let coordAssFile = try assembliesDir.file(named: assemblyCoordName+".swift", withCreation:creation)
        let screenAssFile = try assembliesDir.file(named: assemblyScreenName+".swift", withCreation:creation)

        let baseCoordinatorDir = try logicDir.subfolder(named:baseCoordinatorFolderName, withCreation:creation)
        let baseCoordinatorFile = try baseCoordinatorDir.file(named: baseCoordinatorFolderName+".swift", withCreation:creation)
        let protocolCoordinatorFile = try baseCoordinatorDir.file(named: coordinatorFileName+".swift", withCreation:creation)


        self.coordinatorsFolder = coordDir
        
        self.assembliesFolder = assembliesDir
        self.coordAssFile = coordAssFile
        self.screenAssFile = screenAssFile
        
        self.routerFolder = routerDir
        self.routerFile = routerFile
        
        self.baseCoordinatorFolder = baseCoordinatorDir
        self.baseCoordinatorFile = baseCoordinatorFile
        self.protocolCoordinatorFile = protocolCoordinatorFile
    }

    // MARK: - texts
    fileprivate var appDelegateSubstitutedText:String {
        return """
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {\n        // Override point for customization after application launch.\n        return true\n    }
        """
    }
    fileprivate var appDelegateText:String {
        let text = """
var appCoordinator: Coordinator!
    var coordinatorAssembly:AssemblyCoordinator!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let rootViewController = UINavigationController();
        let router = Router(navController:rootViewController)
        coordinatorAssembly = AssemblyCoordinator(router)
        appCoordinator = coordinatorAssembly.appCoordinator
        
        window = UIWindow.init(frame:UIScreen.main.bounds);
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        appCoordinator.start()
        
        return true
    }
"""
        return text
    }
    fileprivate var baseCoordinatorText:String {
        let text = """
        import Foundation

        class BaseCoordinator:Equatable {
            var childCoordinators: [BaseCoordinator] = []
            
            func addDependency(_ coordinator: BaseCoordinator) {
                guard notContains(coordinator) else { return }
                
                childCoordinators.append(coordinator)
            }
            
            func removeDependency(_ coordinator: BaseCoordinator?) {
                guard
                    let coordinator = coordinator,
                    let index = childCoordinators.index(of: coordinator)
                    else { return }
                
                childCoordinators.remove(at: index)
            }
            
            // MARK: - Equatable
            static func ==(lhs: BaseCoordinator, rhs: BaseCoordinator) -> Bool {
                return type(of: lhs) == type(of: rhs)
            }
            
            // MARK: - Private
            fileprivate func contains(_ coordinator:BaseCoordinator) -> Bool {
                return childCoordinators.contains{ $0 == coordinator }
            }
            fileprivate func notContains(_ coordinator:BaseCoordinator) -> Bool {
                return !contains(coordinator)
            }
        }
        """
        return text
    }
    fileprivate var protocolCoordinatorText:String {
        let text = """
        import Foundation

        protocol Coordinator {
            func start()
        }

        protocol CoordinatorOutput {
            var finishFlow: ((Any) -> Void)? { get set }
        }
        """
        return text
    }
    fileprivate var routerText:String {
        let text = """
        import Foundation
        import UIKit

        class Router:NSObject, UIPopoverPresentationControllerDelegate {
            fileprivate let navController: UINavigationController
            fileprivate var modalVC:UIViewController?
            
            init(navController:UINavigationController) {
                self.navController = navController
            }
            
            func presentModaly(_ vc:UIViewController, sourceView:UIView? = nil, barButtonItem:UIBarButtonItem? = nil, animated:Bool = true)  {
                vc.modalPresentationStyle = UIModalPresentationStyle.popover
                
                // set up the popover presentation controller
                vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
                vc.popoverPresentationController?.delegate = self
                if let barItem = barButtonItem {
                    vc.popoverPresentationController?.barButtonItem = barItem
                } else if let view = sourceView {
                    vc.popoverPresentationController?.sourceView = view
                } else {
                    assertionFailure("Not specified sourceView or barButtonItem for menu popover")
                }
                
                // present the popover
                modalVC = vc
                navController.present(vc, animated: animated, completion: {
                    vc.view.superview?.layer.cornerRadius = 4
                })
            }
            
            func push(_ vc:UIViewController, animated:Bool = true)  {
                navController.pushViewController(vc, animated: animated)
            }
            func dismissTopScreen(animated:Bool = true) {
                navController.popViewController(animated: animated)
            }
            
            func dismissPopoverScreen(animated:Bool = true) {
                navController.presentedViewController?.dismiss(animated: animated, completion: nil)
            }
            
            // MARK: - UIPopoverPresentationControllerDelegate
            func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
                return UIModalPresentationStyle.none
            }
        }
        """
        return text
    }
    fileprivate var textAssemblyCoordinator: String {
        let text = """
        import Foundation
        import UIKit

        class AssemblyCoordinator {
            fileprivate let router: Router
            fileprivate let screenAssembly = AssemblyScreen()

            init(_ router:Router) {
                self.router = router
            }

            lazy var appCoordinator: AppCoordinator = {
                return AppCoordinator(router, self)
            }()

            lazy var mainCoordinator: MainCoordinator = {
                let coordinator = MainCoordinator(router, assembly:self, screenAssembly:screenAssembly)
                return coordinator
            }()
        }
        """
        return text
    }
    fileprivate var textAssemblyScreen: String {
        let text = """
        import Foundation

        class AssemblyScreen {

            func mainScreen(delegate:MainCoordinator) -> MainScreen {
                let vc = MainScreen.instantiateFromStoryboard()
                vc.delegate = delegate
                return vc
            }
        }
        """
        return text
    }
}

