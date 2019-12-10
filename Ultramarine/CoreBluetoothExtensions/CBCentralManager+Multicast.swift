//
//  CBCentralManager+Multicast.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/10/19.
//

import CoreBluetooth

class CBCentralManagerMulticastDelegate: NSObject, CBCentralManagerDelegate {
    let multicast = MulticastDelegate<CBCentralManagerDelegate>()
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        multicast.invokeDelegates { $0.centralManagerDidUpdateState(central) }
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.centralManager?(central, connectionEventDidOccur: event, for: peripheral) }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.centralManager?(central, didConnect: peripheral) }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        multicast.invokeDelegates { $0.centralManager?(central, didFailToConnect: peripheral, error: error) }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        multicast.invokeDelegates { $0.centralManager?(central, didDisconnectPeripheral: peripheral, error: error) }
    }
}

extension CBCentralManager {
    
    public func addDelegate(_ delegate: CBCentralManagerDelegate) {
        if let delegate = self.delegate as? CBCentralManagerMulticastDelegate {
            delegate.multicast.addDelegate(delegate)
        } else {
            let multicastDelegate = CBCentralManagerMulticastDelegate()
            if let existingDelegate = self.delegate {
                multicastDelegate.multicast.addDelegate(existingDelegate)
            }
            multicastDelegate.multicast.addDelegate(delegate)
            self.delegate = multicastDelegate
        }
    }
    
    public func removeDelegate(_ delegate: CBCentralManagerDelegate) {
        if let delegate = self.delegate as? CBCentralManagerMulticastDelegate {
            delegate.multicast.removeDelegate(delegate)
            if delegate.multicast.isEmpty {
                self.delegate = nil
            }
        }
    }
}

