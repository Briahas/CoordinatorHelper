//
//  ProjectManipulator.swift
//  CoordinatorHelper
//
//  Created by anconaesselmann, modified by Mike Kholomeev on 1/4/18.
//  Copyright © 2018 Mike Kholomeev. All rights reserved.
//

import Foundation
import Files

class ProjectImporter {

    // MARK: - Adding source files to Xcode project
    class XcodeEntry {
        let name: String
        var id: String
        var id2: String
        
        init(name: String) {
            self.name = name
            id = XcodeEntry.generateId()
            id2 = XcodeEntry.generateId()
        }
        
        private static func generateId() -> String {
            let uuid = UUID().uuidString
            let index1 = uuid.index(uuid.startIndex, offsetBy: 8)
            let index2 = uuid.index(index1, offsetBy: 1)
            let index3 = uuid.index(index2, offsetBy: 4)
            let index4 = uuid.index(index1, offsetBy: 16)
            let range = index2..<index3
            return uuid.substring(to: index1) + uuid.substring(with: range) + uuid.substring(from: index4)
        }
    }
    
    class XcodeFolder: XcodeEntry {
        let url: URL
        let files: [XcodeEntry]
        let subFolders: [XcodeFolder]
        
        init(url: URL) {
            self.url = url
            let folder = try? Folder(path: url.path)
            self.files = folder?.files.flatMap({ XcodeEntry(name: $0.name) }) ?? []
            self.subFolders = folder?.subfolders.flatMap({
                let subUrl = url.appendingPathComponent($0.name)
                return XcodeFolder(url: subUrl)
            }) ?? []
            super.init(name: url.lastPathComponent)
        }
    }
    
    let encoding: String.Encoding = .utf8

    let targetDir: URL
    let xcodeProjectUrl: URL
    let tempXcodeProjectUrl: URL
    let folders: [XcodeFolder]
    let projectName:String
    let xcodeProjectFileHandle: FileHandle
    let tempXcodeProjectFileHandle: FileHandle
    
    init(projectDirURL:URL, importedDirURL:URL) {
        self.targetDir = projectDirURL
        let disk = FileManager.default
        
        projectName = try! disk.contentsOfDirectory(at: projectDirURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            .filter({$0.pathExtension == "xcodeproj"})[0]
            .lastPathComponent
            .components(separatedBy: ".")[0]

        xcodeProjectUrl = projectDirURL.appendingPathComponent("\(projectName).xcodeproj/project.pbxproj")
        xcodeProjectFileHandle = try! FileHandle(forReadingFrom: xcodeProjectUrl)

        tempXcodeProjectUrl = projectDirURL.appendingPathComponent("\(projectName).xcodeproj/_project.pbxproj")
        disk.createFile(atPath: tempXcodeProjectUrl.relativePath, contents: nil, attributes: nil)
        tempXcodeProjectFileHandle = try! FileHandle(forWritingTo: tempXcodeProjectUrl)
        
        folders = [XcodeFolder(url: importedDirURL)]
    }
    
    let chunkSize = 4096
    var buffer = Data(capacity: 4096)
    var atEof = false

    func readLine() -> String? {
        let delimData:Data =  "\n".data(using: encoding)!
        while !atEof {
            if let range = buffer.range(of: delimData) {
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            let tmpData = xcodeProjectFileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                atEof = true
                if buffer.count > 0 {
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }
    
    
    enum XcodeSection {
        case pbxGroup
        case pbxSourcesBuildPhase
        case pbxResourcesBuildPhase
        case none
    }
    
    var xcodeSection: XcodeSection = .none
    
    var matchingConditions = 0
    
//    func getFolderEntry(for xCodeEntry: XcodeEntry) -> String {
//        return "\t\t\t\t\(xCodeEntry.id2) /* \(xCodeEntry.name) */,\n"
//    }
    
    func getChildEntry(for xCodeEntry: XcodeEntry) -> String {
        return "\t\t\t\t\(xCodeEntry.id2) /* \(xCodeEntry.name) */,"
    }
    
    func getFolderDefinition(for folder: XcodeFolder) -> String {
        let foldersChildren = folder.subFolders.flatMap({getChildEntry(for:$0)}).joined(separator: "\n")
        let filesChildren = folder.files.flatMap({getChildEntry(for:$0)}).joined(separator: "\n")
        let children = foldersChildren+filesChildren
        return "\t\t\(folder.id2) /* \(folder.name) */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\(children)\n\t\t\t);\n\t\t\tpath = \(folder.name);\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n"
    }
    
    func getPbxBuildFileEntry(for xCodeEntry: XcodeEntry) -> String {
        guard !xCodeEntry.name.hasSuffix(".h") else {
            return ""
        }
        return "\t\t\(xCodeEntry.id) /* \(xCodeEntry.name) in Sources */ = {isa = PBXBuildFile; fileRef = \(xCodeEntry.id2) /* \(xCodeEntry.name) */; };\n"
    }
    
    func getPbxFileReferenceEnry(for xCodeEntry: XcodeEntry) -> String {
        let fileType: String
        if xCodeEntry.name.hasSuffix(".swift") {
            fileType = "sourcecode.swift"
        } else if xCodeEntry.name.hasSuffix(".h") {
            fileType = "sourcecode.c.h"
        } else if xCodeEntry.name.hasSuffix(".m") {
            fileType = "sourcecode.c.objc"
        } else if xCodeEntry.name.hasSuffix(".storyboard") {
            fileType = "file.storyboard"
        }else {
            print("Error, wrong file type")
            fileType = ""
        }
        return "\t\t\(xCodeEntry.id2) /* \(xCodeEntry.name) */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = \(fileType); path = \(xCodeEntry.name); sourceTree = \"<group>\"; };\n"
    }
    
    func getPbxSourcesBuildPhase(for xCodeEntry: XcodeEntry) -> String {
        guard !xCodeEntry.name.hasSuffix(".h") else {
            return ""
        }
        return "\t\t\t\t\(xCodeEntry.id) /* \(xCodeEntry.name) in Sources */,\n"
    }
    
    func getPbxResourcesBuildPhase(for xCodeEntry: XcodeEntry) -> String {
        guard !xCodeEntry.name.hasSuffix(".h") else {
            return ""
        }
        return "\t\t\t\t\(xCodeEntry.id) /* \(xCodeEntry.name) in Resources */,\n"
    }
    
    func createPbxBuildFile(for folder:XcodeFolder) {
        folder.files.forEach {
            let pbxBuildFileEntry = getPbxBuildFileEntry(for: $0)
            tempXcodeProjectFileHandle.write((pbxBuildFileEntry).data(using: encoding)!)
        }
        folder.subFolders.forEach { createPbxBuildFile(for: $0) }
    }
    
    func createPbxFileReference(for folder:XcodeFolder) {
        folder.files.forEach {
            let pbxFileReferenceEnry = getPbxFileReferenceEnry(for: $0)
            tempXcodeProjectFileHandle.write((pbxFileReferenceEnry).data(using: encoding)!)
        }
        folder.subFolders.forEach { createPbxFileReference(for:$0) }
    }
    
    func createPbxGroup(for folder:XcodeFolder) {
        let folderDefinition = getFolderDefinition(for: folder)
        tempXcodeProjectFileHandle.write((folderDefinition).data(using: encoding)!)
        folder.subFolders.forEach { createPbxGroup(for:$0) }
    }

    func createPbxSourcesBuildPhase(for folder:XcodeFolder) {
        folder.files.forEach {
            guard !$0.name.hasSuffix(".storyboard") else { return }
            let sourceBuildPhase = getPbxSourcesBuildPhase(for: $0)
            tempXcodeProjectFileHandle.write((sourceBuildPhase).data(using: encoding)!)
        }
        folder.subFolders.forEach { createPbxSourcesBuildPhase(for:$0) }
    }

    func createPbxResourcesBuildPhase(for folder:XcodeFolder) {
        folder.files.forEach {
            guard $0.name.hasSuffix(".storyboard") else { return }
            let resourceBuildPhase = getPbxResourcesBuildPhase(for: $0)
            tempXcodeProjectFileHandle.write((resourceBuildPhase).data(using: encoding)!)
        }
        folder.subFolders.forEach { createPbxResourcesBuildPhase(for:$0) }
    }

    func importFilesIntoProject() {
        while let line = readLine() {
            defer {
                tempXcodeProjectFileHandle.write((line + "\n").data(using: encoding)!)
            }
            
            switch line {
            case "/* End PBXBuildFile section */":
                folders.forEach { createPbxBuildFile(for:$0) }
                
            case "/* End PBXFileReference section */":
                folders.forEach { createPbxFileReference(for:$0) }

            case "/* Begin PBXGroup section */":
                xcodeSection = .pbxGroup
                
            case "/* End PBXGroup section */":
                folders.forEach { createPbxGroup(for:$0) }
                xcodeSection = .none
                
            case "/* Begin PBXSourcesBuildPhase section */":
                xcodeSection = .pbxSourcesBuildPhase

            case "/* Begin PBXResourcesBuildPhase section */":
                xcodeSection = .pbxResourcesBuildPhase

            default: ()
            }
            
            
            switch xcodeSection {
            case .pbxGroup:
                guard let folder = folders.first else { continue }
                let parrentDirName = folder.url.deletingLastPathComponent().lastPathComponent
                
                if line.hasSuffix("/* \(parrentDirName) */ = {") {
                    matchingConditions += 1
                } else if matchingConditions > 0 && line.hasSuffix("children = (") {
                    matchingConditions += 1
                } else if matchingConditions == 2 {
                    folders.forEach {
                        let folderEntry = getChildEntry(for: $0)
                        tempXcodeProjectFileHandle.write((folderEntry).data(using: encoding)!)
                    }
                    matchingConditions = 0
                }
            case .pbxSourcesBuildPhase:
                if line.hasSuffix("files = (") {
                    matchingConditions += 1
                } else if matchingConditions > 0 {
                    folders.forEach { createPbxSourcesBuildPhase(for:$0) }
                    matchingConditions = 0
                    xcodeSection = .none
                }
            case .pbxResourcesBuildPhase:
                if line.hasSuffix("files = (") {
                    matchingConditions += 1
                } else if matchingConditions > 0 {
                    folders.forEach { createPbxResourcesBuildPhase(for:$0) }
                    matchingConditions = 0
                    xcodeSection = .none
                }
            default: ()
            }
        }
        
        tempXcodeProjectFileHandle.closeFile()
        tempXcodeProjectFileHandle.closeFile()
        
        do {
//            try FileManager.default.removeItem(at: xcodeProjectUrl)
            let _ = try FileManager.default.replaceItemAt(xcodeProjectUrl, withItemAt: tempXcodeProjectUrl, backupItemName: "backup_"+xcodeProjectUrl.lastPathComponent, options: [])
        } catch {
            print("Xcode project file could not be modified")
        }
    }
}
