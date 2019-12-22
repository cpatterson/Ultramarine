//
//  CBCentralManager+Multicast.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/10/19.
//

import CoreBluetooth

/// Provides the ability to attach multiple delegates to a single `CBCentralManager` instance.
class CBCentralManagerMulticastDelegate: NSObject, CBCentralManagerDelegate {
    
    // MARK: Instance variables
    
    /// A `MulticastDelegate` instance implementing the `CBCentralManagerDelegate` protocol,
    /// used to forward central manager delegate callbacks to all member delegate objects.
    let multicast = MulticastDelegate<CBCentralManagerDelegate>()
    
    // MARK: CBCentralManagerDelegate methods
    
    /// Forwards this method call to all delegate members of `multicast`.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        multicast.invokeDelegates { $0.centralManagerDidUpdateState(central) }
    }
    
    /// Forwards this method call to all delegate members of `multicast`.
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.centralManager?(central, connectionEventDidOccur: event, for: peripheral) }
    }
    
    /// Forwards this method call to all delegate members of `multicast`.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        multicast.invokeDelegates { $0.centralManager?(central, didConnect: peripheral) }
    }
    
    /// Forwards this method call to all delegate members of `multicast`.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        multicast.invokeDelegates { $0.centralManager?(central, didFailToConnect: peripheral, error: error) }
    }
    
    /// Forwards this method call to all delegate members of `multicast`.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        multicast.invokeDelegates { $0.centralManager?(central, didDisconnectPeripheral: peripheral, error: error) }
    }
}

// MARK: -

/// Implements the ability to add and remove multiple delegate objects to a `CBCentralManager`
/// using an instance of `CBCentralManagerMulticastDelegate`.
extension CBCentralManager {
    
    /// Adds the given `CBCentralManagerDelegate` object to this object's set of delegates.
    ///
    /// If the `delegate` property of this object is set to something other than a `CBCentralManagerMulticastDelegate` object,
    /// then that object, along with the given delegate object, is added to a new multicast object, which becomes the new `delegate`.
    /// Otherwise, the given delegate object is simply added to the multicast object.
    ///
    /// parameter delegate: A `CBCentralManagerDelegate` object that will start receiving delegate callbacks.
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
    
    /// Removes the given `CBCentralManagerDelegate` object from this object's set of delegates.
    ///
    /// If this object's `delegate` property is an instance of `CBCentralManagerMulticastDelegate`,
    /// then the multicast object's `removeDelegate(_:)` method is called with the given object.
    /// If the multicast object contains no more delegates, then the `delegate` property is set to nil.
    ///
    /// parameter delegate: A `CBCentralManagerDelegate` object that will stop receiving delegate callbacks.
    public func removeDelegate(_ delegate: CBCentralManagerDelegate) {
        if let delegate = self.delegate as? CBCentralManagerMulticastDelegate {
            delegate.multicast.removeDelegate(delegate)
            if delegate.multicast.isEmpty {
                self.delegate = nil
            }
        }
    }
}

