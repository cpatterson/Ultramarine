//
//  CBCentralManager+Publishers.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/7/19.
//

import CoreBluetooth
import Combine

public class CBCentralManagerPublisher : NSObject, CBCentralManagerDelegate {
    
    // MARK: Instance variables
        
    weak var central: CBCentralManager?
    
    // MARK: Initializers
    
    public init(central: CBCentralManager) {
        super.init()
        self.central = central
        central.addDelegate(self)
    }
    
    deinit {
        if let central = self.central {
            central.removeDelegate(self)
        }
    }

    // MARK: CBCentralManagerDelegate state change methods
    
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
}

// MARK: - StatePublisher extension

extension CBCentralManager {
    
    /// `Publisher` of `CBCentralManager.state` changes
    public class StatePublisher : CBCentralManagerPublisher, Publisher {
        public typealias Output = CBManagerState
        public typealias Failure = Never
        
        // MARK: Instance variables
        
        let subject = PassthroughSubject<Output, Failure>()
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.StatePublisher.Failure == S.Failure, CBCentralManager.StatePublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate state change methods
        
        public override func centralManagerDidUpdateState(_ central: CBCentralManager) {
            self.subject.send(central.state)
        }
    }
    
    public var statePublisher: StatePublisher {
        return StatePublisher(central: self)
    }
}

// MARK: - AuthorizationPublisher extension

extension CBCentralManager {
    
    /// `Publisher` of `CBCentralManager.authorization` changes
    public class AuthorizationPublisher : CBCentralManagerPublisher, Publisher {
        public typealias Output = CBManagerAuthorization
        public typealias Failure = Never
        
        // MARK: Instance variables
        
        let subject = PassthroughSubject<Output, Failure>()
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.AuthorizationPublisher.Failure == S.Failure, CBCentralManager.AuthorizationPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate state change methods
        
        public override func centralManagerDidUpdateState(_ central: CBCentralManager) {
            self.subject.send(CBManager.authorization)
        }
    }
    
    public var authorizationPublisher: AuthorizationPublisher {
        return AuthorizationPublisher(central: self)
    }
}

// MARK: - DiscoveryPublisher extension

extension CBCentralManager {
    
    public class DiscoveryPublisher: CBCentralManagerPublisher, Publisher {
        public typealias Output = (peripheral: CBPeripheral, advertisementData: [String: Any], rssi: Double)
        public typealias Failure = Error
        
        // MARK: Instance variables
        
        let subject = PassthroughSubject<Output, Failure>()
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.DiscoveryPublisher.Failure == S.Failure, CBCentralManager.DiscoveryPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate discovery methods
        
        public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            self.subject.send((peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI.doubleValue))
        }
    }
    
    public var discoveryPublisher: DiscoveryPublisher {
        return DiscoveryPublisher(central: self)
    }
}

// MARK: - ConnectionEventPublisher extension

public enum PublishedConnectionEvent : Int {
    case peerDisconnected
    case peerConnected
    case peerFailedToConnect
}

extension CBCentralManager {

    public class ConnectionEventPublisher: CBCentralManagerPublisher, Publisher {
        public typealias Output = (peripheral: CBPeripheral, event: PublishedConnectionEvent)
        public typealias Failure = Error
        
        // MARK: Instance variables
        
        let subject = PassthroughSubject<Output, Failure>()
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.ConnectionEventPublisher.Failure == S.Failure, CBCentralManager.ConnectionEventPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate connection methods
        
        public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
            guard let publishedEvent = PublishedConnectionEvent(rawValue: event.rawValue) else { return }
            self.subject.send((peripheral, publishedEvent))
        }
        
        public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            self.subject.send((peripheral: peripheral, event: .peerConnected))
        }
        
        public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            self.subject.send((peripheral: peripheral, event: .peerFailedToConnect))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
        
        public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            self.subject.send((peripheral: peripheral, event: .peerDisconnected))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
    }
    
    public var connectionEventPublisher: ConnectionEventPublisher {
        return ConnectionEventPublisher(central: self)
    }
}
