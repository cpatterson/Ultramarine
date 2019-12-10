//
//  CBPeripheral+Multicast.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/9/19.
//

import CoreBluetooth
import Combine

class CBPeripheralMulticastDelegate: NSObject, CBPeripheralDelegate {
    let multicast = MulticastDelegate<CBPeripheralDelegate>()
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.peripheralDidUpdateName?(peripheral) }
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didModifyServices: invalidatedServices) }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didReadRSSI: RSSI, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverServices: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverIncludedServicesFor: service, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverDescriptorsFor: characteristic, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error) }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didWriteValueFor: descriptor, error: error) }
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.peripheralIsReady?(toSendWriteWithoutResponse: peripheral) }
    }

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didOpen: channel, error: error) }
    }
}

extension CBPeripheral {
    
    public func addDelegate(_ delegate: CBPeripheralDelegate) {
        if let delegate = self.delegate as? CBPeripheralMulticastDelegate {
            delegate.multicast.addDelegate(delegate)
        } else {
            let multicastDelegate = CBPeripheralMulticastDelegate()
            if let existingDelegate = self.delegate {
                multicastDelegate.multicast.addDelegate(existingDelegate)
            }
            multicastDelegate.multicast.addDelegate(delegate)
            self.delegate = multicastDelegate
        }
    }
    
    public func removeDelegate(_ delegate: CBPeripheralDelegate) {
        if let delegate = self.delegate as? CBPeripheralMulticastDelegate {
            delegate.multicast.removeDelegate(delegate)
            if delegate.multicast.isEmpty {
                self.delegate = nil
            }
        }
    }
}
