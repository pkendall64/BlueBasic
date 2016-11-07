//
//  Uploader.swift
//  BlueBasicConsole
//
//  Created by tim on 9/24/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import CoreBluetooth

class Uploader: ConsoleDelegate {
  
  var okcount = 0
  let console: Console
  var complete: CompletionHandler? = nil
  var written = 0
  var wrote = 0
  
  init(_ console: Console) {
    self.console = console
  }
  
  func upload(_ url: URL, onComplete: CompletionHandler? = nil) {
    
    self.complete = onComplete

    console.delegate = self;
    
    console.status = "Sending...0%"
    
//    var data = NSString(contentsOfURL: url, encoding: String.Encoding.ascii, error: error)
//    var data = String(contentsOf: url, encoding: String.Encoding.ascii, error: error)
    let data : String
    do
    {
       data = try String(contentsOf: url, encoding: String.Encoding.ascii)
    }
    catch
    {
      data = ""
    }
    
      write("NEW\n")
    for line in data.components(separatedBy: "\n") {
        write(line + "\n")
      write("END\n")
    }
  }
  
  func write(_ str: String) {
    wrote += (str.utf16.count + 63) / 64
    console.write(str)
  }
  
  func onNotification(_ uuid: CBUUID, data: Data) -> Bool {
    let str = NSString(data: data, encoding: String.Encoding.ascii.rawValue)!
    okcount += 1
    if uuid == UUIDS.inputCharacteristicUUID && str == "OK\n" &&  okcount == 2 {
      console.status = "Connected"
      console.delegate = nil
      complete?(true)
      return true
    } else {
      return false
    }
  }
  
  func onWriteComplete(_ uuid: CBUUID) {
    written += 1
    console.status = String(format: "Sending...%d%%", 100 * written / wrote)
  }
}
