//
//  ConsoleProtocol.swift
//  BlueBasicConsole
//
//  Created by tim on 10/8/14.
//  Copyright (c) 2014 tim. All rights reserved.
//

import Foundation

protocol ConsoleProtocol {
  
  var status: String { get set }
  
  func setStatus(_ status: String) // Workaround
  
  var delegate: ConsoleDelegate? { get set }
  
  func setDelegate(_ delegate: ConsoleDelegate)
  
  var current: Device? { get }
  
  var isConnected: Bool { get }
  
  var isRecoveryMode: Bool { get }
  
  func connectTo(_ device: Device, onConnected: CompletionHandler?)
  
  func disconnect(_ onDisconnect: CompletionHandler?)
  
  func write(_ str: String) -> Bool
  
  //func append(_ str: String)
}
