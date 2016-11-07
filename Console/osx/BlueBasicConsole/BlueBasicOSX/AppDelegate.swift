//
//  AppDelegate.swift
//  BlueBasicConsole
//
//  Created by tim on 9/23/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Cocoa
import CoreBluetooth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, DeviceListDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var devicesView: NSTableView!
  @IBOutlet weak var statusField: NSTextField!
  @IBOutlet weak var consoleView: NSScrollView!
  @IBOutlet weak var toDeviceMenu: NSMenuItem!
  @IBOutlet weak var upgradeMenu: NSMenuItem!
  
  let manager = DeviceManager()
  var console: Console!
  var devices: DeviceList!
  var autoUpgrade: AutoUpdateFirmware?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    console = Console(console: consoleView.contentView.documentView as! NSTextView, status: statusField)
    devices = DeviceList(devices: devicesView, manager: manager)
    devices.delegate = self
    devices.scan()
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    console.disconnect()
  }
  
  func onDeviceConnect(_ device: Device) {
    upgradeMenu.isEnabled = false
    toDeviceMenu.isEnabled = false
    console.connectTo(device) {
      success in
      if success {
        self.toDeviceMenu.isEnabled = true
        self.autoUpgrade = AutoUpdateFirmware(console: self.console)
        self.autoUpgrade!.detectUpgrade() {
          needupgrade in
          if needupgrade {
            self.console.status = "Upgrade available"
            self.upgradeMenu.isEnabled = true
          } else {
            self.autoUpgrade = nil
          }
        }
      }
    }
  }
  
  func onDeviceDisconnect(_ device: Device) {
    upgradeMenu.isEnabled = false
    toDeviceMenu.isEnabled = false
    console.disconnect()
  }
  
  
  @IBAction func fromDevice(_ sender: AnyObject) {
  }
  
  @IBAction func toDevice(_ sender: AnyObject) {
    if console.isConnected {
      let panel = NSOpenPanel()
      panel.allowsMultipleSelection = false
      panel.canChooseDirectories = false
      panel.canCreateDirectories = false
      panel.canChooseFiles = true
      panel.title = "Select BASIC file to load onto device"
      let i = panel.runModal()
      if (i == NSModalResponseOK){
        Uploader(self.console!).upload(panel.url!)
      }
    }
  }
  
  @IBAction func upgrade(_ sender: AnyObject) {
    if autoUpgrade != nil {
      autoUpgrade!.upgrade()
    }
  }
}

