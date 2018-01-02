//
//  ViewController.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 Mike Kholomeev. All rights reserved.
//

import Cocoa
import Files

enum State {
    case initial, correctStructure, correctFlowName, flowAddingStart, flowAdding(result: Bool)
}

class ViewController: NSViewController, NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource {
//    fileprivate let sourceFolderName = "Source"
//    fileprivate let flowFolderName = "Flow"
//    fileprivate let logicFolderName = "Logic"
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var infoView: NSView!
    @IBOutlet weak var correctProjectStructureLabel: NSTextField!
    @IBOutlet weak var flowDirFixButton: NSButton!

    @IBOutlet weak var flowAddView: NSView!
    @IBOutlet weak var flowNameTextField: NSTextField!
    @IBOutlet weak var flowAddButton: NSButton!
    
    @IBOutlet weak var addinFlowResultTextField: NSTextField!
    @IBOutlet weak var addinFlowIndocator: NSProgressIndicator!
    @IBOutlet weak var scanninDiskIndocator: NSProgressIndicator!

    
    fileprivate let dickScaner = DiskScaner()
    fileprivate var projectStructure: ProjectStructure?
    fileprivate var projects: [Folder] = []
    fileprivate var selectedFolder: Folder?

    
    fileprivate var state = State.initial {
        didSet { repformState() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        flowNameTextField.delegate = self
        
        reloadProjectList()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - Actions
    @IBAction func refresh(_ sender: Any) {
        reloadProjectList()
    }
    
    @IBAction func fixProjectStructure(_ sender: NSButton) {
        guard let projectStructure = self.projectStructure else { return }
        
        do { try projectStructure.performCorrection() }
        catch { print(error.localizedDescription) }
    }
    
    @IBAction func addFlow(_ sender: NSButton) {
//        state = .flowAddingStart
//
//        let flowName = flowNameTextField.stringValue
//        guard
//            flowName.count > 0,
//            let allFlowsDir = allFlowsDir,
//            let fileC = coordAssFile,
//            let fileS = screenAssFile
//            else { state = .flowAdding(result:false); return }
//
//        let managerAssemblies = Assemblies(coordinatorAssemblyFile: fileC,
//                                                  screenAssemblyFile: fileS)
//        managerAssemblies.addCoordinator(with:flowName)
//
//        let managerFlows = Flows(in: allFlowsDir)
//        managerFlows.create(flow: flowName) { state = .flowAdding(result:$0); return }
        
    }
    
    // MARK: - Private
    // MARK: Analyzing
    fileprivate func analyseSelected(_ folder:Folder) {
        self.selectedFolder = folder

        do {
            let projectStructure = try ProjectStructure(with: folder)
            state = projectStructure.isCorrect ? .correctStructure : .initial
            self.projectStructure = projectStructure
        }
        catch let error as ProjectStructureError { print(error) }
        catch { print(error.localizedDescription) }
    }

    fileprivate func analyseEntered(_ name:String) {
        guard let projectStructure = self.projectStructure else { return }

        state = projectStructure.isCorrectCoordinator(name) ? .correctFlowName : .correctStructure
    }
    // MARK: State
    fileprivate func repformState() {
        switch state {
        case .initial:
            setupInitialUI()
        case .correctStructure:
            setupCorrectStructureUI()
        case .correctFlowName:
            setupCorrectFlowNameUI()
        case .flowAddingStart:
            setupFlowAddingStart()
        case .flowAdding(let result):
            setupFlowAdding(result)
        }
    }
// MARK: Setup State UI
    fileprivate func setupInitialUI() {
        correctProjectStructureLabel.stringValue = "incorrect"
        flowDirFixButton.isEnabled = true
        flowAddView.isHidden = true
    }

    fileprivate func setupCorrectStructureUI() {
        correctProjectStructureLabel.stringValue = "correct"
        flowDirFixButton.isEnabled = false
        flowAddView.isHidden = false
        flowAddButton.isEnabled = false
        flowNameTextField.becomeFirstResponder()
    }
    
    fileprivate func setupCorrectFlowNameUI() {
        flowAddButton.isEnabled = true
        addinFlowResultTextField.isHidden = true
        addinFlowIndocator.stopAnimation(nil)
    }
    fileprivate func setupFlowAddingStart() {
        flowAddButton.isEnabled = false
        addinFlowResultTextField.isHidden = true
        addinFlowIndocator.startAnimation(nil)
    }
    fileprivate func setupFlowAdding(_ result:Bool) {
        flowAddButton.isEnabled = true
        addinFlowResultTextField.isHidden = false
        addinFlowIndocator.stopAnimation(nil)

        addinFlowResultTextField.stringValue = result ? "Success" : "Failure"
    }

    // MARK: reload
    fileprivate func reloadProjectList() {
        state = .initial
        dickScaner.projects().then { (data) -> Void in
            self.projects = data
            self.tableView.reloadData()
        }
    }
    
    // MARK: - NSTextFieldDelegate
    override func controlTextDidChange(_ obj: Notification) {
        analyseEntered(flowNameTextField.stringValue)
    }
    // MARK: - NSTableViewDelegate, NSTableViewDataSource
    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
        guard projects.count >= row else { return nil }
        let text = projects[row].nameExcludingExtension
        
        return text
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        let folder = projects[row]
        analyseSelected(folder)
    }
}

