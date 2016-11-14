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
  @IBOutlet weak var loadFirmwareMenu: NSMenuItem!
  
  let manager = DeviceManager()
  var console: Console!
  var devices: DeviceList!
  var autoUpgrade: AutoUpdateFirmware?
  var firmwareBlob: Data?

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
    loadFirmwareMenu.isEnabled = false
    console.connectTo(device) {
      success in
      if success {
        self.toDeviceMenu.isEnabled = true
        self.loadFirmwareMenu.isEnabled = true
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
    loadFirmwareMenu.isEnabled = false
    
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
      panel.message = "Select BASIC file to load onto device"
      // calling .runModal() works not in sandboxed mode
      // this would need to be executed in the main thread
      // needs to be fixed
      if (panel.runModal() == NSModalResponseOK){
        Uploader(self.console!).upload(panel.url!)
      }
    }
  }
  
  @IBAction func upgrade(_ sender: AnyObject) {
    if autoUpgrade != nil {
      autoUpgrade!.upgrade()
    }
  }

  @IBAction func update(_ sender: AnyObject){
    if console.isConnected {
      let panel = NSOpenPanel()
      panel.allowsMultipleSelection = false
      panel.canChooseDirectories = false
      panel.canCreateDirectories = false
      panel.canChooseFiles = true
      panel.allowedFileTypes = ["bin"]
      panel.message = "Select binary Firmware image to load onto device"
      if (panel.runModal() == NSModalResponseOK) {
        do {
          firmwareBlob = try Data(contentsOf: panel.url!)
          Firmware(console).upgrade(firmwareBlob!)
        } catch let error as NSError {
          print("Could not read file, Error \(error)")
        }
      }
    }
  }
  
}

