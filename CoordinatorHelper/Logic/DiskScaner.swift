//
//  DiskScaner.swift
//  CoordinatorHelper
//
//  Created by Mike Kholomeev on 12/13/17.
//  Copyright © 2017 Mike Kholomeev. All rights reserved.
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

    func projects() -> Promise<[Folder]> {
        var urls:[Folder] = []
        let start = CACurrentMediaTime()
        let disk = FileManager.default

        guard
            let url = self.documentDirURL
            else { return Promise { fulfill, _ in fulfill(urls) }
        }

        let promise = Promise<[Folder]> { fulfill, _ in
            let queue = OperationQueue()

            queue.addOperation {
                guard let files = try? disk.subpathsOfDirectory(atPath: url.path) else {return}
                let list = files
                    .filter({ $0.hasSuffix(self.projectExtention) && !($0.contains(self.excludeProject) || $0.contains("Vendor")) })
                    .map({ url.appendingPathComponent($0).deletingLastPathComponent().path })
                    .flatMap({ try? Folder(path:$0) })
                urls = list
            }

            queue.waitUntilAllOperationsAreFinished()
            print(CACurrentMediaTime()-start)

            fulfill(urls)
        }
        
        
        return promise
    }
}
