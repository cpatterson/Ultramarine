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
        
        let centralPublisher: CBCentralManager.ConnectionEventPublisher
        let subject = PassthroughSubject<Output, Failure>()
        var subscriptions = Set<AnyCancellable>()
        
        public init(peripheral: CBPeripheral, central: CBCentralManager) {
            self.centralPublisher = central.connectionEventPublisher
            super.init(peripheral: peripheral)
            
            self.centralPublisher
                .filter { $0.peripheral == self.peripheral }
                .sink(
                    receiveCompletion: { self.subject.send(completion: $0) },
                    receiveValue:      { self.subject.send($0.event) }
                )
                .store(in: &subscriptions)
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBPeripheral.ConnectionEventPublisher.Failure == S.Failure, CBPeripheral.ConnectionEventPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
    }
    
    public func connectionEventPublisher(central: CBCentralManager)  -> ConnectionEventPublisher {
        return ConnectionEventPublisher(peripheral: self, central: central)
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


