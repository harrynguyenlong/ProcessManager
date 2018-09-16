//
//  ViewController.swift
//  ProcessManager
//
//  Created by Nguyen Ba Long on 27/07/2018.
//  Copyright © 2018 Nguyen Ba Long. All rights reserved.
//

import Cocoa
import Darwin

extension MainViewController: SettingControllerDelegate {
    func settingControllerDidChangeSetting() {
        updateTheTableView()
    }
}


extension MainViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return listOfRunningProcesses.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            image = listOfRunningProcesses[row].icon
            text = listOfRunningProcesses[row].name
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = String(listOfRunningProcesses[row].pID)
            cellIdentifier = CellIdentifiers.PIDCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = listOfRunningProcesses[row].owner
            cellIdentifier = CellIdentifiers.UserCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image
            return cell
        }

        return nil
    }


    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
}

class MainViewController: NSViewController {
    
    var currentSetting: DisplaySetting = SettingController.share.currentSetting()
    
    var selectedRow: Int? {
        didSet {
            guard let selectedRow = selectedRow else { return }
            
            if selectedRow != -1 {
                terminateButton.isEnabled = true
            } else {
                terminateButton.isEnabled = false
            }
        }
    }
    
    @IBOutlet weak var tableView: NSTableView!
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
        static let PIDCell = "PIDCellID"
        static let UserCell = "UserCellID"
    }
    
    var listOfRunningProcesses: [Application] = getListOfAllRunningProcesses(setting: SettingController.share.currentSetting())
    
    lazy var terminateButton: NSButton = {
        let btn = NSButton()
        btn.title = "Terminate"
        btn.bezelStyle = .rounded
        btn.isEnabled = false
        btn.target = self
        btn.action = #selector(handleTerminateBtnClicked)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        setupTableView()

        setupTimer()
    }
    
    // MARK: Setup methods
    
    private func setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.updateTheTableView()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.action = #selector(handleItemClicked)
    }
    
    private func setupViews() {
        
        SettingController.share.delegate = self
        
        self.view.addSubview(terminateButton)
        
        terminateButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 20, paddingRight: 20, width: 100, height: 20)
        
    }
    
    private func updateTheTableView() {
        
        var isDisPlaySettingChange: Bool = (self.currentSetting == SettingController.share.currentSetting()) ? false : true
        
        if isDisPlaySettingChange {
            self.currentSetting = SettingController.share.currentSetting()
            self.selectedRow = nil
        }
        
        if selectedRow == nil {
            
            self.listOfRunningProcesses = MainViewController.getListOfAllRunningProcesses(setting: SettingController.share.currentSetting())
            
            self.tableView.reloadData()
            
        } else {
            
            guard let selectedRow = selectedRow, selectedRow != -1 else { return }
            
            let processToBeCheck = listOfRunningProcesses[selectedRow]
            
            self.listOfRunningProcesses = MainViewController.getListOfAllRunningProcesses(setting: SettingController.share.currentSetting())
            
            self.tableView.reloadData()
            
            guard let newIndex = checkForNewIndex(app: processToBeCheck) else { return }
            
            let index = IndexSet(integer: newIndex)
            
            self.tableView.selectRowIndexes(index, byExtendingSelection: false)
            
            self.selectedRow = newIndex
        }
        
    }
    
    private func checkForNewIndex(app: Application) -> Int? {
        for (index, process) in listOfRunningProcesses.enumerated() {
            if process.pID == app.pID {
                return index
            }
        }
        
        return nil
    }
    
    // MARK: Handle click event
    
    @objc private func handleTerminateBtnClicked() {
        guard let selectedRow = selectedRow else { return }
        
        terminateProcessWithPid(app: listOfRunningProcesses[selectedRow])
    }
    
    @objc private func handleItemClicked() {
        self.selectedRow = tableView.selectedRow
    }
    
    // MARK: Supporting methods
    
    static func getListOfAllRunningProcesses(setting: DisplaySetting) -> [Application] {
        
        var processList = [Application]()
        
        guard let listOfRunningProcess = GetBSDProcessList() else { return [Application]() }

        for app in listOfRunningProcess {
            guard let currentUserId = getpwuid(app.kp_eproc.e_ucred.cr_uid) else { return [Application]() }
            
            let pid = app.kp_proc.p_pid
            
            var name = app.kp_proc
            
            let processName = withUnsafePointer(to: &name.p_comm) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: name.p_comm)) {
                    String(cString: $0)
                }
            }
            
            let username = String(cString: currentUserId.pointee.pw_name)
            
            let application = NSRunningApplication(processIdentifier: pid)
            
            let process = Application(name: processName, owner: username, pID: pid.hashValue, icon: application?.icon)
            
            switch setting {
                case .allProcesses:
                    processList.append(process)
                case .myOwnProcesses:
                    if process.owner == NSUserName() {
                        processList.append(process)
                    }
                case .rootProcesses:
                    if process.owner == "root" {
                        processList.append(process)
                    }
            }
        }
        
        return processList
    }
    
    private func terminateProcessWithPid(app: Application) {
        
        guard let pidCode = pid_t(exactly: app.pID) else { return }
        
        guard let selectedRow = selectedRow else { return }
        
        let resultCode = kill(pidCode, SIGKILL)
        
        if resultCode == 0 {
            print("Success")
            
            listOfRunningProcesses.remove(at: selectedRow)
            
            tableView.reloadData()
            
        } else if resultCode == -1 {
            
            print("Failed")
            print(errno)
            print(EPERM)
            
            let answer = dialogOKCancel(question: "Error", text: "Operation could not be finished")
        }
        
        self.selectedRow = nil
        
        self.terminateButton.isEnabled = false
    
    }
    
    private func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        return alert.runModal() == .alertFirstButtonReturn
    }

}

