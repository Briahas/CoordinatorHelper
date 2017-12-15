//
//  ViewController.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 NixSolutions. All rights reserved.
//

import Cocoa
import Files

enum State {
    case initial, correctStructure, correctCoordinatorName
}

class ViewController: NSViewController, NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var infoView: NSView!
    @IBOutlet weak var correctProjectStructureLabel: NSTextField!
    @IBOutlet weak var flowDirCreateButton: NSButton!

    @IBOutlet weak var coordinatorAddView: NSView!
    @IBOutlet weak var coordinatorNameTextField: NSTextField!
    @IBOutlet weak var coordinatorAddButton: NSButton!
    
    fileprivate let scaner = DiskScaner()
    fileprivate var projects: [Folder] = []
    fileprivate var dirFlow: Folder?
    fileprivate var coordAssFile: File?
    fileprivate var screenAssFile: File?
    
    fileprivate var state = State.initial {
        didSet { repformState() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        coordinatorNameTextField.delegate = self
        
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
    
    @IBAction func addCoordinator(_ sender: NSButton) {
        guard
            let fileC = coordAssFile,
            let fileS = screenAssFile
            else { return }
        
        let manager = ManagerAssemblies()
        manager.operate(coordinator: fileC,
                        screen: fileS,
                        withCoordinatorName: coordinatorNameTextField.stringValue)
    }
    
    // MARK: - Private
    // MARK: analyzing
    fileprivate func analyseSelected(_ folder:Folder) {
        self.dirFlow = nil
        self.coordAssFile = nil
        self.screenAssFile = nil

        guard
            let sub1 = try? folder.subfolder(named: folder.name),
            let dirSource = try? sub1.subfolder(named: "Source"),
            let dirFlow = try? dirSource.subfolder(named: "Flow"),
            let dirLogic = try? dirSource.subfolder(named: "Logic"),
            let coordAssFile = try? dirLogic.file(named: "AssemblyCoordinator.swift"),
            let screenAssFile = try? dirLogic.file(named: "AssemblyScreen.swift")
            else {
                state = .initial
                return
        }
        
        state = .correctStructure
        self.dirFlow = dirFlow
        self.coordAssFile = coordAssFile
        self.screenAssFile = screenAssFile
    }

    fileprivate func analyseEntered(_ name:String) {
        guard
            let isNewName = dirFlow?.subfolders.filter({ $0.name == name }).isEmpty,
            isNewName
            else  {
                state = .correctStructure
                return
        }
        
        state = .correctCoordinatorName
    }
    // MARK: state
    fileprivate func repformState() {
        switch state {
        case .initial:
            setupInitialUI()
        case .correctStructure:
            setupCorrectStructureUI()
        case .correctCoordinatorName:
            setupCorrectCoordinatorNameUI()
        }
    }

    fileprivate func setupInitialUI() {
        correctProjectStructureLabel.isEnabled = false
        flowDirCreateButton.isEnabled = true
        coordinatorAddView.isHidden = true
    }

    fileprivate func setupCorrectStructureUI() {
        let enable = true
        correctProjectStructureLabel.isEnabled = true
        flowDirCreateButton.isEnabled = false
        coordinatorAddView.isHidden = false
        coordinatorAddButton.isEnabled = false
        coordinatorNameTextField.becomeFirstResponder()
    }
    
    fileprivate func setupCorrectCoordinatorNameUI() {
        coordinatorAddButton.isEnabled = true
    }

    // MARK: reload
    fileprivate func reloadProjectList() {
        state = .initial
        scaner.projects().then { (data) -> Void in
            self.projects = data
            self.tableView.reloadData()
        }
    }
    
    // MARK: - NSTextFieldDelegate
    override func controlTextDidChange(_ obj: Notification) {
        analyseEntered(coordinatorNameTextField.stringValue)
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

