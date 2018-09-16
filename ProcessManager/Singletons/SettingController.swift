//
//  SettingController.swift
//  ProcessManager
//
//  Created by Nguyen Ba Long on 31/07/2018.
//  Copyright © 2018 Nguyen Ba Long. All rights reserved.
//

import Foundation

protocol SettingControllerDelegate {
    func settingControllerDidChangeSetting()
}

enum DisplaySetting: String {
    case allProcesses
    case myOwnProcesses
    case rootProcesses
}

class SettingController: NSObject {
    static var share = SettingController()
    
    var delegate: SettingControllerDelegate?
    
    private var setting: DisplaySetting = .allProcesses
    
    override init() {
        super.init()
    
        let currentSetting = DisplaySetting(rawValue: UserDefaults.standard.string(forKey: "setting") ?? "")
        
        if currentSetting == nil {
            print("Nothing")
        } else {
            print("Set setting to the saved one")
            
            self.setting = currentSetting ?? .allProcesses
        }
    }
    
    public func setSetting(setting: DisplaySetting) {
        self.setting = setting
        UserDefaults.standard.set(self.setting.rawValue, forKey: "setting")
        delegate?.settingControllerDidChangeSetting()
    }
    
    public func removeSetting() {
        UserDefaults.standard.removeObject(forKey: "setting")
    }
    
    public func currentSetting() -> DisplaySetting {
        let setting = DisplaySetting(rawValue: UserDefaults.standard.string(forKey: "setting") ?? "")
        
        return setting ?? DisplaySetting.allProcesses
    }
}
