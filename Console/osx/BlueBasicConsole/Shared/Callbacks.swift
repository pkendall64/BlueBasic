//
//  Callbacks.swift
//  BlueBasicConsole
//
//  Created by tim on 9/23/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import CoreBluetooth

typealias CompletionHandler = (Bool) -> Void
typealias NewDeviceFoundHandler = (Device) -> Void
typealias ServicesFoundHandler = ([CBUUID: DeviceService]) -> Void
typealias CharacteristicUpdateHandler = (Data) -> Void

class Callback<T> {
  
  let callbacks: Callbacks<T>
  let id: Int
  
  init(callbacks: Callbacks<T>, id: Int) {
    self.callbacks = callbacks
    self.id = id
  }

  func remove() {
    callbacks.remove(id)
  }
  
}


class Callbacks<T> {
  
  var callbacks = Array<((T) -> Void)?>()
  
  func append(_ callback: ((T) -> Void)?) -> Callback<T> {
    callbacks.append(callback)
    return Callback<T>(callbacks: self, id: callbacks.count - 1)
  }
  
  func remove(_ id: Int) {
    callbacks.remove(at: id)
  }
  
  func removeAll() {
    callbacks.removeAll(keepingCapacity: false)
  }
  
  func call(_ arg: T) {
    for callback in callbacks {
      callback?(arg)
    }
  }

}

class OneTimeCallbacks<T> : Callbacks<T> {
  
  override func call(_ arg: T) {
    let ocallbacks = callbacks
    callbacks.removeAll(keepingCapacity: false)
    for callback in ocallbacks {
      callback?(arg)
    }
  }
  
}
