//
//  ViewController.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 NixSolutions. All rights reserved.
//

import Cocoa
import Files

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var infoView: NSView!
    @IBOutlet weak var flowDirLabel: NSTextField!
    @IBOutlet weak var coordinatorAssemblyLabel: NSTextField!
    @IBOutlet weak var screenAssemblyLabel: NSTextField!
    
    @IBOutlet weak var flowDirCreateButton: NSButton!
    @IBOutlet weak var coordinatorAssemblyCreateButton: NSButton!
    @IBOutlet weak var screenAssemblyCreateButton: NSButton!
    
    fileprivate let scaner = DiskScaner()
    fileprivate var projects: [Folder] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
    
    // MARK: - Private
    fileprivate func initialStateUI() {
        flowDirLabel.isEnabled = false
        coordinatorAssemblyLabel.isEnabled = false
        screenAssemblyLabel.isEnabled = false
    }

    fileprivate func reloadProjectList() {
        initialStateUI()
        scaner.projects().then { (data) -> Void in
            self.projects = data
            self.tableView.reloadData()
        }
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
        initialStateUI()
        let row = tableView.selectedRow
//        guard let folder = projects[row] else { return }
        let folder = projects[row]
        guard
            let sub1 = try? folder.subfolder(named: folder.name),
            let dirSource = try? sub1.subfolder(named: "Source")
            else { return }
        
        let dirFlow = try? dirSource.subfolder(named: "Flow")
        flowDirLabel.isEnabled = (dirFlow != nil)
        
        guard
            let dirLogic = try? dirSource.subfolder(named: "Logic")
            else { return }
        
        let coordAssFile = try? dirLogic.file(named: "AssemblyCoordinator.swift")
        coordinatorAssemblyLabel.isEnabled = (coordAssFile != nil)

    }
}

