//
//  CBPeripheral+Multicast.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/9/19.
//

import CoreBluetooth
import Combine

/// Provides the ability to attach multiple delegates to a single `CBPeripheral` instance.
class CBPeripheralMulticastDelegate: NSObject, CBPeripheralDelegate {

    // MARK: Instance variables
    
    /// A `MulticastDelegate` instance implementing the `CBPeripheralDelegate` protocol,
    /// used to forward peripheral delegate callbacks to all member delegate objects.
    let multicast = MulticastDelegate<CBPeripheralDelegate>()
    
    // MARK: CBPeripheral methods
    
    // MARK: Peripheral Updates
    
    /// Forwards this method call to all delegate members of `multicast`.
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.peripheralDidUpdateName?(peripheral) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didModifyServices: invalidatedServices) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didReadRSSI: RSSI, error: error) }
    }

    // MARK: Discovery
    
    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverServices: error) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverIncludedServicesFor: service, error: error) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didDiscoverDescriptorsFor: characteristic, error: error) }
    }

    // MARK: Read/Write/Notify Characteristic Values
    
    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error) }
    }

    // MARK: Read/Write Descriptor Values
    
    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error) }
    }

    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didWriteValueFor: descriptor, error: error) }
    }

    // MARK: Write Queue Management
    
    /// Forwards this method call to all delegate members of `multicast`.
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.peripheralIsReady?(toSendWriteWithoutResponse: peripheral) }
    }

    // MARK: L2CAP Channel Management
    
    /// Forwards this method call to all delegate members of `multicast`.
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        multicast.invokeDelegates { $0.peripheral?(peripheral, didOpen: channel, error: error) }
    }
}

// MARK: -

/// Implements the ability to add and remove multiple delegate objects to a `CBPeripheral`
/// using an instance of `CBPeripheralMulticastDelegate`.
extension CBPeripheral {
    
    /// Adds the given `CBPeripheralDelegate` object to this object's set of delegates.
    ///
    /// If the `delegate` property of this object is set to something other than a `CBPeripheralMulticastDelegate` object,
    /// then that object, along with the given delegate object, is added to a new multicast object, which becomes the new `delegate`.
    /// Otherwise, the given delegate object is simply added to the multicast object.
    ///
    /// parameter delegate: A `CBPeripheralDelegate` object that will start receiving delegate callbacks.
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
    
    /// Removes the given `CBPeripheralDelegate` object from this object's set of delegates.
    ///
    /// If this object's `delegate` property is an instance of `CBPeripheralMulticastDelegate`,
    /// then the multicast object's `removeDelegate(_:)` method is called with the given object.
    /// If the multicast object contains no more delegates, then the `delegate` property is set to nil.
    ///
    /// parameter delegate: A `CBPeripheralDelegate` object that will stop receiving delegate callbacks.
    public func removeDelegate(_ delegate: CBPeripheralDelegate) {
        if let delegate = self.delegate as? CBPeripheralMulticastDelegate {
            delegate.multicast.removeDelegate(delegate)
            if delegate.multicast.isEmpty {
                self.delegate = nil
            }
        }
    }
}
