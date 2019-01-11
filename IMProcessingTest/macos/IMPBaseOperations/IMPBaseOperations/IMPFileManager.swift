//
//  IMPFileManager.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 07/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa


public class IMPFileManager {
    private let openRecentCount = 10
    private let openRecentKey = "imageMetalling-open-recent"

    public enum FileType{
        case Image
    }
    
    public typealias Observer = ((_ file:String, _ type:FileType) -> Void)
    
    static public let sharedInstance = IMPFileManager()

    public func add(updates observer:@escaping Observer){
        fileUpdateHandlers.append(observer)
    }
    
    public weak var openRecentMenu: NSMenu! {
        didSet{
            if let list = openRecentList {
                if list.count>0{
                    for file in list.reversed() {
                        addOpenRecentMenuItemMenu(file: file)
                    }
                }
            }
        }
    }

    public func openFilePanel(types:[String]){
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseFiles  = true;
        openPanel.resolvesAliases = true;
        openPanel.isExtensionHidden = false;
        openPanel.allowedFileTypes = types
        
        let result = openPanel.runModal()
        
        if result == NSApplication.ModalResponse.OK {
            IMPFileManager.sharedInstance.currentFile = openPanel.urls[0].path
        }
    }

    
    var currentFile:String?{
        didSet{
            
            guard let path = currentFile else {
                return
            }
            
            let code = access(path, R_OK)
            if  code < 0 {
                let error = NSError(
                    domain: "com.dehancer.DehancerEAPOSX",
                    code: Int(code),
                    userInfo: [
                        NSLocalizedDescriptionKey: String(format: NSLocalizedString("File %@ could not be opened", comment:""), path),
                        NSLocalizedFailureReasonErrorKey: String(format: NSLocalizedString("File open error", comment:""))
                    ])
                let alert = NSAlert(error: error)
                alert.runModal()
                
                _ = removeOpenRecentFileMenuItem(file: path)
                return
            }
            
            addOpenRecentFileMenuItem(file: currentFile!)
            
            for o in self.fileUpdateHandlers{
                o(currentFile!, .Image)
            }
        }
    }

    private func addOpenRecentFileMenuItem(file:String){
        
        var list = removeOpenRecentFileMenuItem(file: file)
        
        list.insert(file, at: 0)
        
        if list.count > openRecentCount {
            for i in list[openRecentCount..<list.count]{
                if let menuItem = openRecentMenuItems[i] {
                    openRecentMenu.removeItem(menuItem)
                }
            }
            list.removeSubrange(openRecentCount..<list.count)
        }
        
        UserDefaults.standard.set(list, forKey: openRecentKey)
        UserDefaults.standard.synchronize()
        
        addOpenRecentMenuItemMenu(file: file)
    }
    
    private func addOpenRecentMenuItemMenu(file:String){
        if let menu = openRecentMenu {
            let menuItem = menu.insertItem(withTitle: file, action: Selector(("openRecentHandler:")), keyEquivalent: "", at: 0)
            openRecentMenuItems[file]=menuItem
        }
    }
    
    private func removeOpenRecentFileMenuItem(file:String) -> [String] {
        
        var list = openRecentList ?? [String]()
        
        if let index = list.index(of: file){
            list.remove(at: index)
            if let menuItem = openRecentMenuItems[file] {
                //openRecentMenu.removeItem(menuItem)
            }
        }
        
        UserDefaults.standard.set(list, forKey: openRecentKey)
        UserDefaults.standard.synchronize()
        
        return list
    }

    private var openRecentList:[String]?{
        get {
            return UserDefaults.standard.object(forKey: openRecentKey) as? [String]
        }
    }
    
    private var openRecentMenuItems = Dictionary<String,NSMenuItem>()

    private init() {}
    
    private var fileUpdateHandlers = [Observer]()
}
