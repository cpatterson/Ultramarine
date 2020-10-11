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
    
    public var statePublisher: AnyPublisher<CBManagerState, Never> {
        return StatePublisher(central: self).eraseToAnyPublisher()
    }
}

// MARK: - AuthorizationPublisher extension

extension CBCentralManager {
    
    /// `Publisher` of `CBCentralManager.authorization` changes
    public class AuthorizationPublisher : CBCentralManagerPublisher, Publisher {
        public typealias Output = CBManagerAuthorization
        public typealias Failure = Never
        
        // MARK: Instance variables
        
        let subject = CurrentValueSubject<Output, Failure>(.notDetermined)
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.AuthorizationPublisher.Failure == S.Failure, CBCentralManager.AuthorizationPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate state change methods
        
        public override func centralManagerDidUpdateState(_ central: CBCentralManager) {
            self.subject.send(CBManager.authorization)
        }
    }
    
    public var authorizationPublisher: AnyPublisher<CBManagerAuthorization, Never> {
        return AuthorizationPublisher(central: self).eraseToAnyPublisher()
    }
}

// MARK: - DiscoveryPublisher extension

public struct Discovery {
    let peripheral: CBPeripheral
    let advertisementData: [String: Any]
    let rssi: Double
}

extension CBCentralManager {
    
    public class DiscoveryPublisher: CBCentralManagerPublisher, Publisher {
        public typealias Output = Discovery
        public typealias Failure = Error
        
        // MARK: Instance variables
        
        let subject = PassthroughSubject<Output, Failure>()
        
        let serviceUUIDs: [CBUUID]?
        
        // MARK: Initializer
        
        /// Initializer that filters `Discovery` events by the given service UUIDs.
        /// Only discoveries of peripherals whose services are included in `serviceUUIDs` will be published.
        ///
        /// - parameter central: `CBCentralManager` generating discovery events
        /// - parameter serviceUUIDs: Optional array of `CBUUID` objects used to filter discovery events. Pass `nil` (the default) to discover all peripherals.
        public init(central: CBCentralManager, serviceUUIDs: [CBUUID]? = nil) {
            self.serviceUUIDs = serviceUUIDs
            super.init(central: central)
        }
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.DiscoveryPublisher.Failure == S.Failure, CBCentralManager.DiscoveryPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate discovery methods
        
        public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            // If serviceUUIDs is non-nil, only send discoveries that match. Otherwise, send all discoveries.
            let peripheralServiceUUIDs: [CBUUID] = peripheral.services?.map { $0.uuid } ?? []
            if serviceUUIDs == nil || serviceUUIDs!.contains(where: peripheralServiceUUIDs.contains) {
                self.subject.send(Discovery(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI.doubleValue))
            }
        }
    }
    
    public var discoveryPublisher: AnyPublisher<Discovery, Error> {
        return DiscoveryPublisher(central: self).eraseToAnyPublisher()
    }
    
    public func discoverPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String : Any]? = nil,
        where predicate: @escaping ((Discovery) -> Bool) = { _ in true }
    ) -> AnyPublisher<Discovery, Error> {
        let publisher = DiscoveryPublisher(central: self, serviceUUIDs: serviceUUIDs)
        self.scanForPeripherals(withServices: serviceUUIDs, options: options)
        return publisher
            .filter(predicate)
            .eraseToAnyPublisher()
    }
    
    public func stopDiscoveringPeripherals() {
        self.stopScan()
        self.invokeDelegates { (delegate) in
            guard let discoveryPublisher = delegate as? CBCentralManager.DiscoveryPublisher else { return }
            discoveryPublisher.subject.send(completion: .finished)
        }
    }
}

// MARK: - ConnectionEventPublisher extension

public enum ConnectionEventType : Int {
    case peerDisconnected
    case peerConnected
    case peerFailedToConnect
}

public struct ConnectionEvent {
    let peripheral: CBPeripheral
    let event: ConnectionEventType
}

extension CBCentralManager {

    public class ConnectionEventPublisher: CBCentralManagerPublisher, Publisher {
        public typealias Output = ConnectionEvent
        public typealias Failure = Error
        
        // MARK: Instance variables
        
        let subject = PassthroughSubject<Output, Failure>()
        
        // MARK: Publisher methods
        
        public func receive<S>(subscriber: S) where S : Subscriber, CBCentralManager.ConnectionEventPublisher.Failure == S.Failure, CBCentralManager.ConnectionEventPublisher.Output == S.Input {
            self.subject.receive(subscriber: subscriber)
        }
        
        // MARK: CBCentralManagerDelegate connection methods
        
        public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
            guard let publishedEvent = ConnectionEventType(rawValue: event.rawValue) else { return }
            self.subject.send(ConnectionEvent(peripheral: peripheral, event: publishedEvent))
        }
        
        public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            self.subject.send(ConnectionEvent(peripheral: peripheral, event: .peerConnected))
        }
        
        public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            self.subject.send(ConnectionEvent(peripheral: peripheral, event: .peerFailedToConnect))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
        
        public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            self.subject.send(ConnectionEvent(peripheral: peripheral, event: .peerDisconnected))
            if let error = error {
                self.subject.send(completion: .failure(error))
            }
        }
    }
    
    public var connectionEventPublisher: AnyPublisher<ConnectionEvent, Error> {
        return ConnectionEventPublisher(central: self).eraseToAnyPublisher()
    }
    
    public func connect(to peripheral: CBPeripheral, options: [String : Any]? = nil) -> AnyPublisher<ConnectionEventType, Error> {
        let publisher = peripheral.connectionEventPublisher(central: self)
        self.connect(peripheral, options: options)
        return publisher
    }
    
    public func connectToFirstDiscovery(
        withServices serviceUUIDs: [CBUUID]?,
        scanOptions: [String : Any]? = nil,
        connectOptions: [String : Any]? = nil,
        where predicate: @escaping ((Discovery) -> Bool) = { _ in true }
    ) -> AnyPublisher<ConnectionEventType, Error> {
        return self
            .discoverPeripherals(withServices: serviceUUIDs, options: scanOptions, where: predicate)
            .first()
            .flatMap { [weak self] (discovery) -> AnyPublisher<ConnectionEventType, Error> in
                guard let _self = self else {
                    return Empty().eraseToAnyPublisher()
                }
                return _self.connect(to: discovery.peripheral, options: connectOptions)
            }
            .eraseToAnyPublisher()
    }
}
