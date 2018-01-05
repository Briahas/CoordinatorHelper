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

class ProjectStructure {

    fileprivate let projectExt = "xcodeproj"
    fileprivate let workspaceExt = "xcworkspace"
    fileprivate let swiftExtension = ".swift"
    fileprivate let sourceFolderName = "Source"
    fileprivate let coordinatorsFolderName = "Coordinators"
    fileprivate let logicFolderName = "Logic"
    fileprivate let routerFolderName = "Router"
    fileprivate let assembliesFolderName = "Assemblies"
    fileprivate let baseCoordinatorFolderName = "BaseCoordinator"
    
    fileprivate let assemblyCoordName = "AssemblyCoordinator"
    fileprivate let assemblyScreenName = "AssemblyScreen"
    fileprivate let coordinatorFileName = "Coordinator"
    fileprivate let appdelegateName = "AppDelegate"
    
    fileprivate let mainDir:Folder
    fileprivate var projectName = ""
    
    fileprivate var sourceFolder: Folder?
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
        return (try? analyze()) ?? false
    }
    
    func performCorrection() throws {
        try createCorrectStructure()
        
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
        
        guard let sourceFolder = self.sourceFolder else { throw ProjectStructureError.localError("No Source folder") }
        let projectImporter = ProjectImporter(projectDirURL: URL(fileURLWithPath:mainDir.path),
                                              importedDirURL: URL(fileURLWithPath:sourceFolder.path))
        projectImporter.importFilesIntoProject()
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
    fileprivate func analyze() throws -> Bool {
        return try analyzeWith(creation: false)
    }
    fileprivate func createCorrectStructure() throws -> Bool {
        return try analyzeWith(creation: true)
    }
    
    fileprivate func analyzeWith(creation:Bool) throws -> Bool {
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

        self.sourceFolder = sourceDir
        self.coordinatorsFolder = coordDir
        
        self.assembliesFolder = assembliesDir
        self.coordAssFile = coordAssFile
        self.screenAssFile = screenAssFile
        
        self.routerFolder = routerDir
        self.routerFile = routerFile
        
        self.baseCoordinatorFolder = baseCoordinatorDir
        self.baseCoordinatorFile = baseCoordinatorFile
        self.protocolCoordinatorFile = protocolCoordinatorFile
        
        return true
    }

    // MARK: - texts
    fileprivate var appDelegateSubstitutedText:String {
        return "func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {\n        // Override point for customization after application launch.\n        return true\n    }"
    }
    fileprivate var appDelegateText:String {
        let text = """
//MARK - AUTOGENERATED via CoordinatorHelper
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
    //MARK - AUTOGENERATED via CoordinatorHelper END

    //func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    //    // Override point for customization after application launch.
    //    return true
    //}
"""
        return text
    }
    fileprivate var baseCoordinatorText:String {
        let text = """
        //MARK - AUTOGENERATED via CoordinatorHelper
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
        //MARK - AUTOGENERATED via CoordinatorHelper END
        """
        return text
    }
    fileprivate var protocolCoordinatorText:String {
        let text = """
        //MARK - AUTOGENERATED via CoordinatorHelper
        import Foundation

        protocol Coordinator {
            func start()
        }

        protocol CoordinatorOutput {
            var finishFlow: ((Any) -> Void)? { get set }
        }
        //MARK - AUTOGENERATED via CoordinatorHelper END
        """
        return text
    }
    fileprivate var routerText:String {
        let text = """
        //MARK - AUTOGENERATED via CoordinatorHelper
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
        //MARK - AUTOGENERATED via CoordinatorHelper END
        """
        return text
    }
    fileprivate var textAssemblyCoordinator: String {
        let text = """
        //MARK - AUTOGENERATED via CoordinatorHelper
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
        //MARK - AUTOGENERATED via CoordinatorHelper END
        """
        return text
    }
    fileprivate var textAssemblyScreen: String {
        let text = """
        //MARK - AUTOGENERATED via CoordinatorHelper
        import Foundation
        import UIKit

        extension UIViewController {
            class func instantiateFromStoryboard() -> Self {
                return instantiateFromStoryboardHelper(type: self, storyboardName: String(describing: self))
            }
            
            class func instantiateFromStoryboard(storyboardName: String) -> Self {
                return instantiateFromStoryboardHelper(type: self, storyboardName: storyboardName)
            }
            
            private class func instantiateFromStoryboardHelper<T>(type: T.Type, storyboardName: String) -> T {
                let storyboad = UIStoryboard(name: storyboardName, bundle: nil)
                let controller = storyboad.instantiateViewController(withIdentifier: storyboardName) as! T
                
                return controller
            }
        }

        class AssemblyScreen {

            func mainScreen(delegate:MainCoordinator) -> MainScreen {
                let vc = MainScreen.instantiateFromStoryboard()
                vc.delegate = delegate
                return vc
            }
        }
        //MARK - AUTOGENERATED via CoordinatorHelper END
        """
        return text
    }
}

