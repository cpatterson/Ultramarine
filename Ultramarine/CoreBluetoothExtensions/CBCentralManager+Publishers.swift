//
//  CBCentralManager+Publishers.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/7/19.
//

import CoreBluetooth
import Combine

public class CBCentralManagerPublisher : NSObject, CBCentralManagerDelegate {
    weak var central: CBCentralManager?
    
    public init(central: CBCentralManager) {
        super.init()
        self.central = central
        central.addDelegate(self)
    }
    
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
    deinit {
        if let central = self.central {
            central.removeDelegate(self)
        }
    }
}

// MARK: - StatePublisher extension

extension CBCentralManager {
    
    public class StatePublisher : CBCentralManagerPublisher, Publisher {
        public typealias Output = CBManagerState
        public typealias Failure = Never
        
        let subject = PassthroughSubject<Output, Failure>()
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.StatePublisher.Failure == S.Failure, CBCentralManager.StatePublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
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
    
    public class AuthorizationPublisher : CBCentralManagerPublisher, Publisher {
        public typealias Output = CBManagerAuthorization
        public typealias Failure = Never
        
        let subject = PassthroughSubject<Output, Failure>()
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.AuthorizationPublisher.Failure == S.Failure, CBCentralManager.AuthorizationPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        public override func centralManagerDidUpdateState(_ central: CBCentralManager) {
            self.subject.send(central.authorization)
        }
    }
    
    public var authorizationPublisher: AuthorizationPublisher {
        return AuthorizationPublisher(central: self)
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
        public typealias Output = (CBPeripheral, PublishedConnectionEvent)
        public typealias Failure = Error
        
        let subject = PassthroughSubject<Output, Failure>()
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.ConnectionEventPublisher.Failure == S.Failure, CBCentralManager.ConnectionEventPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
            guard let publishedEvent = PublishedConnectionEvent(rawValue: event.rawValue) else { return }
            self.subject.send((peripheral, publishedEvent))
        }
        
        public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            self.subject.send((peripheral, .peerConnected))
            
            // TODO: subscribe peripheral to connection event publisher and pass through connection events
            //let peripheralPublisher = peripheral.connectionEventPublisher
            //self.subject.receive(subscriber: peripheralPublisher)
        }
        
        public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            self.subject.send((peripheral, .peerFailedToConnect))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
        
        public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            self.subject.send((peripheral, .peerDisconnected))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
    }
    
    public var connectionEventPublisher: ConnectionEventPublisher {
        return ConnectionEventPublisher(central: self)
    }
}

