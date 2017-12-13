//
//  DiskScaner.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 NixSolutions. All rights reserved.
//

import Foundation
import PromiseKit
import Files

class DiskScaner {
    fileprivate let queue = OperationQueue()
    fileprivate let disk = FileManager.default
    fileprivate let projectExtention = "xcodeproj"
    fileprivate let excludeProject = "Pods"
    fileprivate lazy var searchURLs = {
        [userDirURL]
    }()

    init() {
        queue.name = "DiskScanQueue"
    }
    
    lazy var documentDirURL = {
        return try? disk.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }()

    lazy var userDirURL : URL? = {
        disk.homeDirectoryForCurrentUser
    }()

    lazy var developerDirURL = {
        return try? disk.url(for: .developerDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }()

    func projects() -> Promise<Array<Folder>> {
        var urls:[Folder] = []
        let start = CACurrentMediaTime()
//        let backgroundQ = DispatchQueue.global(qos: .background)

        return Promise { fulfill, reject in
            guard
                let url = self.documentDirURL,
                let folder = try? Folder(path:url.path)
                else { return }
            
            folder.makeSubfolderSequence(recursive: true).forEach { folder in
                let list = folder.subfolders.filter({
                    $0.extension == self.projectExtention && $0.nameExcludingExtension != self.excludeProject
                }).flatMap { $0.parent }
                urls += list
            }
            print(CACurrentMediaTime()-start)
            
            fulfill(urls)
        }
    }
}
