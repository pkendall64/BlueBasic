//
//  DeviceList.swift
//  BlueBasicConsole
//
//  Created by tim on 9/23/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import Cocoa
import CoreBluetooth

class DeviceList: NSObject, NSTableViewDataSource, NSTableViewDelegate {
  
  let manager: DeviceManager
  let devices: NSTableView
  var names = [Device]()
  var delegate: DeviceListDelegate?
  
  init(devices: NSTableView, manager: DeviceManager) {
    self.devices = devices
    self.manager = manager
    super.init()
    devices.dataSource = self
    devices.selectionHighlightStyle = .regular
    devices.target = self
    devices.doubleAction = #selector(DeviceList.selectDevice(_:))
  }
  
  func scan() {
    manager.findDevices() {
      device in
//      if !contains(self.names, device) {
      if !self.names.contains(device) {
        self.names.append(device)
      }
      self.devices.reloadData()
    }
  }
  
  func numberOfRows(in tableView: NSTableView!) -> Int {
    return names.count
  }
  
  func tableView(_ tableView: NSTableView!, objectValueFor tableColumn: NSTableColumn!, row: Int) -> Any! {
    return names[row].name
  }
  
  func selectDevice(_ id: AnyObject) {
    delegate?.onDeviceConnect(names[devices.clickedRow])
  }
}
