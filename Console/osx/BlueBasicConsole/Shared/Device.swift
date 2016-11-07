//
//  Device.swift
//  BlueBasicConsole
//
//  Created by tim on 9/23/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import CoreBluetooth

class Device: NSObject, CBPeripheralDelegate {
  
  let peripheral: CBPeripheral
  let manager: DeviceManager
  var serviceList = [CBUUID: DeviceService]()
  var isPopulated = false
  var serviceCallbacks = OneTimeCallbacks<[CBUUID: DeviceService]>()
  var characteristics = 0
  var delegate: DeviceDelegate?
  var readCallbacks = [CBUUID: OneTimeCallbacks<Data?>]()
  
  var rssi: Int
  
  init (peripheral: CBPeripheral, rssi: Int, manager: DeviceManager) {
    self.peripheral = peripheral
    self.manager = manager
    self.rssi = rssi
    super.init()
    self.peripheral.delegate = self
  }
  
  func services(_ callback: @escaping ServicesFoundHandler) {
    if !isPopulated {
      _ = serviceCallbacks.append(callback)
      if !isConnected {
        manager.connect(self) {
          success in
          if success {
            self.peripheral.discoverServices([])
          } else {
            self.serviceCallbacks.call(self.serviceList)
          }
        }
      } else {
        peripheral.discoverServices([])
      }
    } else {
      callback(serviceList)
    }
  }
  
  func connect(_ onConnected: CompletionHandler? = nil) {
    manager.connect(self) {
      success in
      if success {
        _ = self.manager.disconnectCallbacks.append({
          ignore in
          let d = self.delegate
          d?.onDisconnect()
        })
      }
      onConnected?(success)
    }
  }
  
  func disconnect(_ onDisconnect: CompletionHandler? = nil) {
    manager.disconnect(self, onDisconnect: onDisconnect)
  }
  
  var isConnected: Bool = false {
    didSet {
      if !isConnected && oldValue {
        serviceCallbacks.removeAll()
      } else if isConnected && !oldValue {
        isPopulated = false
        serviceList.removeAll(keepingCapacity: false)
      }
    }
  }
  
  var name: String {
    get {
      return manager.deviceName(peripheral)
    }
  }
  
  var identifier: UUID {
    get {
      return peripheral.identifier;
    }
  }
  
  func write(_ data: Data, characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
    if isConnected {
      peripheral.writeValue(data, for: characteristic, type: type)
    }
  }
  
  func notify(_ uuid: CBUUID, serviceUUID: CBUUID) {
    if isConnected {
      services() {
        list in
        if let characteristic = list[serviceUUID]?.characteristics[uuid] {
          self.peripheral.setNotifyValue(true, for: characteristic)
        }
      }
    }
  }
  
  func read(_ characteristic: CBCharacteristic, onRead: @escaping (Data?) -> Void) {
    if isConnected {
      if readCallbacks[characteristic.uuid] == nil {
        readCallbacks[characteristic.uuid] = OneTimeCallbacks<Data?>()
      }
      _ = readCallbacks[characteristic.uuid]!.append(onRead)
      peripheral.readValue(for: characteristic)
    } else {
      onRead(nil)
    }
  }
  
//  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//    if let services = peripheral.services as? [CBService] {
//      characteristics = 0
//      for service in services {
//        serviceList[service.UUID] = DeviceService(device: self, service: service)
//        peripheral.discoverCharacteristics([], forService: service)
//        characteristics++
//      }
//    }
//  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    characteristics = 0
    for service in peripheral.services! {
      let thisService = service as CBService
      serviceList[service.uuid] = DeviceService(device: self, service: thisService)
      peripheral.discoverCharacteristics([], for: thisService)
      characteristics += 1
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    characteristics -= 1
    if serviceList[service.uuid] != nil && characteristics == 0 {
      isPopulated = true
      serviceCallbacks.call(self.serviceList)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if error == nil {
      let value = Utilities.getValue(characteristic)
      if let callback = readCallbacks[characteristic.uuid] {
        readCallbacks.removeValue(forKey: characteristic.uuid)
        callback.call(error == nil ? value : nil)
      } else {
        delegate?.onNotification(error == nil, uuid: characteristic.uuid, data: value)
      }
    } else {
      if let callback = readCallbacks[characteristic.uuid] {
        readCallbacks.removeValue(forKey: characteristic.uuid)
        callback.call(nil)
      } else {
        delegate?.onNotification(true, uuid: characteristic.uuid, data: Data())
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    delegate?.onWriteComplete(error == nil, uuid: characteristic.uuid)
  }
}
