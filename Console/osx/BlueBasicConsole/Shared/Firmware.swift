//
//  Firmware.swift
//  BlueBasicConsole
//
//  Created by tim on 9/24/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import CoreBluetooth

class Firmware: ConsoleDelegate {

  let console: ConsoleProtocol
  var complete: CompletionHandler? = nil
  let device: Device
  var firmware : Data?
  var wrote = 0
  var written = 0
  var blockCharacteristic: CBCharacteristic?
  
  init(_ console: ConsoleProtocol) {
    self.console = console
    self.device = console.current!
  }
  
  func upgrade(_ firmware: Data, onComplete: CompletionHandler? = nil) {
    
    self.firmware = firmware
    self.complete = onComplete
    
    if console.isRecoveryMode {
      flash()
    } else {
      console.setStatus("Rebooting")
      console.write("REBOOT UP\n")
      // Wait a moment to give device chance to reboot
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(1_000_000_000) / Double(NSEC_PER_SEC)) {
        self.console.disconnect() {
          success in
          self.console.connectTo(self.device) {
            success in
            self.flash()
          }
        }
      }
    }
  }
  
  func onWriteComplete(_ uuid: CBUUID) {
    
    let blocksize = 16
    let countsize = 16

    switch uuid {
    case UUIDS.imgIdentityUUID:
      let nrblocks = (firmware!.count + blocksize - 1) / blocksize
      for i in 0...nrblocks-1 {
        let block = NSMutableData(capacity: blocksize + 2)!
        let blockheader = [ UInt8(i & 255), UInt8(i >> 8) ]
        block.append(blockheader, length: 2)
//        block.append(self.firmware!.subdata(in: NSMakeRange(i * blocksize, blocksize)))
        block.append(self.firmware!.subdata(in: (i * blocksize)..<(i*blocksize + blocksize)))
        if i < nrblocks - 1 && i % countsize != 0 {
          device.write(block as Data, characteristic: blockCharacteristic!, type: .withoutResponse)
        } else {
          device.write(block as Data, characteristic: blockCharacteristic!, type: .withResponse)
          wrote += 1
        }
      }
    case UUIDS.imgBlockUUID:
      written += 1
      if written == wrote - 1 { // Last ack is always lost as device reboots
        console.setStatus("Waiting...")
        // Wait for 5 seconds to give last writes change to finish
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(5_000_000_000) / Double(NSEC_PER_SEC)) {
          self.console.disconnect() {
            success in
            self.console.connectTo(self.device, onConnected: self.complete)
          }
        }
      } else {
        console.setStatus(String(format: "Upgrading...%d%%", 100 * written / wrote))
      }
      break
    default:
      break
    }
  }

  func onNotification(_ uuid: CBUUID, data: Data) -> Bool {
    return false
  }
  
  func flash() {

    device.services() {
      list in
      
      self.console.setDelegate(self)

      self.blockCharacteristic = list[UUIDS.oadServiceUUID]!.characteristics[UUIDS.imgBlockUUID]!
      
      let identCharacteristic = list[UUIDS.oadServiceUUID]!.characteristics[UUIDS.imgIdentityUUID]!
//      let header = self.firmware!.subdata(in: NSMakeRange(4, 8)) // version:2, length:2, uid:4
      let header = self.firmware!.subdata(in: 4..<12) // version:2, length:2, uid:4
      self.device.write(header, characteristic: identCharacteristic, type: .withResponse)
    }
  }
  
}
