//
//  DeviceDelegate.swift
//  BlueBasicConsole
//
//  Created by tim on 9/25/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol DeviceDelegate {
  
  func onDisconnect()
  func onNotification(_ success: Bool, uuid: CBUUID, data: Data)
  func onWriteComplete(_ success: Bool, uuid: CBUUID)
  
}
