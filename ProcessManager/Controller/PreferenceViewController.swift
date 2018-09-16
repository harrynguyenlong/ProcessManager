//
//  PreferenceViewController.swift
//  ProcessManager
//
//  Created by Nguyen Ba Long on 28/07/2018.
//  Copyright © 2018 Nguyen Ba Long. All rights reserved.
//

import Foundation
import Cocoa

class PreferenceViewController: NSViewController {
    
    @IBOutlet weak var settingPopUpBtn: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: Setup methods
    
    private func setupView() {
        let currentSetting = SettingController.share.currentSetting()
        
        if currentSetting == .allProcesses {
            settingPopUpBtn.selectItem(at: 0)
        } else if currentSetting == .myOwnProcesses {
            settingPopUpBtn.selectItem(at: 1)
        } else if currentSetting == .rootProcesses {
            settingPopUpBtn.selectItem(at: 2)
        }
    }
    
    // MARK: Action methods
    
    @IBAction func handleCancelBtnClicked(_ sender: NSButton) {
        
        self.view.window?.close()
    }
    
    @IBAction func handleSaveDisplaySetting(_ sender: NSButton) {
        
        print(settingPopUpBtn.indexOfSelectedItem)
        
        var currentSetting: DisplaySetting = .allProcesses
        
        switch settingPopUpBtn.indexOfSelectedItem {
        case 0:
            currentSetting = .allProcesses
        case 1:
            currentSetting = .myOwnProcesses
        case 2:
            currentSetting = .rootProcesses
        default:
            ()
        }
        
        SettingController.share.setSetting(setting: currentSetting)
        
        self.view.window?.close()
        
    }
    
}
