//
//  CBCentralManager+Publishers.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/7/19.
//

import CoreBluetooth
import Combine

public enum PublishedConnectionEvent : Int {
    case peerDisconnected
    case peerConnected
    case peerFailedToConnect
}

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

public class CBCentralManagerPublisher : NSObject, CBCentralManagerDelegate {
    weak var central: CBCentralManager?
    
    public init(central: CBCentralManager) {
        super.init()
        self.central = central
        if let delegate = central.delegate as? CBCentralManagerMulticastDelegate {
            delegate.multicast.addDelegate(self)
        } else {
            let multicastDelegate = CBCentralManagerMulticastDelegate()
            if let delegate = central.delegate {
                multicastDelegate.multicast.addDelegate(delegate)
            }
            multicastDelegate.multicast.addDelegate(self)
            central.delegate = multicastDelegate
        }
    }
    
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
    deinit {
        if let central = self.central, let delegate = central.delegate as? CBCentralManagerMulticastDelegate {
            delegate.multicast.removeDelegate(self)
            if delegate.multicast.isEmpty {
                central.delegate = nil
            }
        }
    }
}

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
