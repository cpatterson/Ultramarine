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
        public typealias Output = ConnectionEventType
        public typealias Failure = Error
        
        let centralPublisher: AnyPublisher<CBCentralManager.ConnectionEventPublisher.Output, Error>
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
    
    public func connectionEventPublisher(central: CBCentralManager)  -> AnyPublisher<ConnectionEventType, Error> {
        return ConnectionEventPublisher(peripheral: self, central: central).eraseToAnyPublisher()
    }
}

// MARK: - DiscoveryPublisher

enum DiscoveryEventType {
    case services
    case includedServices(service: CBService)
    case characteristics(service: CBService)
    case descriptors(descriptors: [CBDescriptor], characteristic: CBCharacteristic)
}

// MARK: updatePublisher

enum PeripheralChangeType {
    case name(name: String)
    case rssi(rssi: Double)
    case services(services: [CBService])
    
}
