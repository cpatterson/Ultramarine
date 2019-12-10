//
//  CBPeripheral+Publishers.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 11/10/19.
//

import CoreBluetooth
import Combine

public class CBPeripheralPublisher : NSObject, CBPeripheralDelegate {
    weak var peripheral: CBPeripheral?
    
    public init(peripheral: CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        peripheral.addDelegate(self)
    }
    
    deinit {
        if let peripheral = self.peripheral {
            peripheral.removeDelegate(self)
        }
    }
}

// MARK: - ConnectionEventPublisher

// Passes through connection events from central for this peripheral.
extension CBPeripheral {
    
    public class ConnectionEventPublisher : CBPeripheralPublisher, Publisher {
        public typealias Output = PublishedConnectionEvent
        public typealias Failure = Error
        
        let subject = PassthroughSubject<Output, Failure>()
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBPeripheral.ConnectionEventPublisher.Failure == S.Failure, CBPeripheral.ConnectionEventPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
    }
    
    public var connectionEventPublisher : ConnectionEventPublisher {
        return ConnectionEventPublisher(peripheral: self)
    }
}

// MARK: - DiscoveryPublisher

enum DiscoveryEventType {
    case nameUpdated(name: String)
    case services
    case changedServices
    case includedServices
    case characteristics
    case descriptors
}

// MARK: - RSSIPublisher


