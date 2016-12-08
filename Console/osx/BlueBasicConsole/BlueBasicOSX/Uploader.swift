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
  var chunkArr: [String] = []
  
  init(_ console: Console) {
    self.console = console
  }
  
  func upload(_ url: URL, onComplete: CompletionHandler? = nil) {
    
    self.complete = onComplete

    console.delegate = self;
    
    console.status = "Sending...0%"
    
    var data : String
    do
    {
       data = try String(contentsOf: url, encoding: String.Encoding.ascii)
       data = "NEW\n" + data + "END\n"
    }
    catch
    {
      data = ""
    }
    
    var comment = ""
    for item in data.components(separatedBy: "\n") {
      let line = item + "\n"
      // if the entire line is a comment we skip it
      if !line.hasPrefix("//") {
        if !self.write(line) {
          console.status = "File upload failed"
          return
        }
        // in order to echo the upload to the console
        // we slice each line into 20 byte chunks (as write does)
        var chunk = ""
        for ch in line.characters {
          chunk.append(ch)
          if ch == "\n" || chunk.utf16.count > 19 {
            chunkArr.append(comment + chunk)
            chunk = ""
            comment = ""
          }
        }
      } else {
        comment += line
      }
    }
  }


  func write(_ str: String) -> Bool {
    wrote += (str.utf16.count + 19) / 20
    return console.write(str)
  }
  
  func onNotification(_ uuid: CBUUID, data: Data) -> Bool {
    let str = NSString(data: data, encoding: String.Encoding.ascii.rawValue)!
    if uuid == UUIDS.inputCharacteristicUUID && str == "OK\n" {
      okcount += 1
      return false   // supress OK echo
    }
    return true
  }
  
  func onWriteComplete(_ uuid: CBUUID) {
    written += 1
    console.status = String(format: "Sending...%d%%", 100 * written / wrote)
    // echo the uploaded chunks to the console
    console.append(chunkArr[0])
    chunkArr.remove(at: 0)
    if written == wrote {
      console.status = "Connected"
      console.append("OK\n")
      console.delegate = nil
      complete?(true)
    }
  }
}
