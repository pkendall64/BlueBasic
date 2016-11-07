//
//  Utilities.swift
//  BlueBasicConsole
//
//  Created by tim on 10/4/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation
import CoreBluetooth

class Utilities {
  class func getValue(_ characteristic: CBCharacteristic) -> Data {
    return characteristic.value!
  }
}
