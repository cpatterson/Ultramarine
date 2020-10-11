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
        
        // Instance variables
        
        let centralPublisher: AnyPublisher<CBCentralManager.ConnectionEventPublisher.Output, Error>
        let subject = PassthroughSubject<Output, Failure>()
        var subscriptions = Set<AnyCancellable>()
        
        // MARK: Initializer
        
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
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBPeripheral.ConnectionEventPublisher.Failure == S.Failure, CBPeripheral.ConnectionEventPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
    }
    
    public func connectionEventPublisher(central: CBCentralManager)  -> AnyPublisher<ConnectionEventType, Error> {
        return ConnectionEventPublisher(peripheral: self, central: central).eraseToAnyPublisher()
    }
}

// MARK: - DiscoveryPublisher

public enum DiscoveryEventType {
    case services
    case includedServices(service: CBService)
    case characteristics(service: CBService)
    case descriptors(characteristic: CBCharacteristic)
}

extension CBPeripheral {
    
    public class DiscoveryPublisher : CBPeripheralPublisher, Publisher {
        public typealias Output = DiscoveryEventType
        public typealias Failure = Error
        
        let subject = PassthroughSubject<Output, Failure>()

        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBPeripheral.DiscoveryPublisher.Failure == S.Failure, CBPeripheral.DiscoveryPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBPeripheralDelegate methods
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            self.subject.send(.services)
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
            self.subject.send(.includedServices(service: service))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            self.subject.send(.characteristics(service: service))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
            self.subject.send(.descriptors(characteristic: characteristic))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
    }
    
    public var discoveryPublisher: AnyPublisher<DiscoveryEventType, Error> {
        return DiscoveryPublisher(peripheral: self).eraseToAnyPublisher()
    }

}

// MARK: ChangePublisher

public enum PeripheralChangeType {
    case name(name: String?)
    case rssi(rssi: Double, error: Error?)
    case services(services: [CBService])
}

extension CBPeripheral {
    
    public class ChangePublisher : CBPeripheralPublisher, Publisher {
        public typealias Output = PeripheralChangeType
        public typealias Failure = Never
        
        let subject = PassthroughSubject<Output, Failure>()
        
        var rssiTimer: Timer?

        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBPeripheral.ChangePublisher.Failure == S.Failure, CBPeripheral.ChangePublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBPeripheralDelegate methods
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            self.subject.send(.name(name: peripheral.name))
        }
        
        func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
            self.subject.send(.services(services: invalidatedServices))
        }
        
        func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
            self.subject.send(.rssi(rssi: RSSI.doubleValue, error: error))
        }
    }
    
    public var changePublisher: AnyPublisher<PeripheralChangeType, Never> {
        return ChangePublisher(peripheral: self).eraseToAnyPublisher()
    }
    
    public func publishRSSIOnce() -> AnyPublisher<PeripheralChangeType, Never> {
        let publisher = self.changePublisher
        self.readRSSI()
        return publisher
            .filter { if case .rssi(_, _) = $0 { return true } else { return false } }
            .first()
            .eraseToAnyPublisher()
    }
    
    public func startPublishingRSSI(withTimeInterval timeInterval: TimeInterval = 1) -> AnyPublisher<PeripheralChangeType, Never> {
        let publisher = ChangePublisher(peripheral: self)
        publisher.rssiTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            self?.readRSSI()
        }
        return publisher
            .filter { if case .rssi(_, _) = $0 { return true } else { return false } }
            .eraseToAnyPublisher()
    }
    
    public func stopPublishingRSSI() {
        self.invokeDelegates { delegate in
            guard
                let publisher = delegate as? CBPeripheral.ChangePublisher,
                let timer = publisher.rssiTimer
            else { return }
            timer.invalidate()
            publisher.subject.send(completion:  .finished)
        }
    }
}
