//
//  UltramarineTests.swift
//  UltramarineTests
//
//  Created by Christopher Patterson on 11/7/19.
//

import XCTest
import RZBluetooth
import Ultramarine

class TestDevice: RZBSimulatedDevice {
    
    // Instance variables
    
    public var integerCharacteristicValue: UInt32 {
        get {
            let suuid = TestService.serviceUUID()!
            let cuuid = TestService.characteristicUUIDsByKey()["integer"] as! CBUUID
            guard let characteristic = self.characteristic(for: cuuid, serviceUUID: suuid) else { return 0 }
            return TestService.value(forKey: "integer", from: characteristic.value) as! UInt32
        }
        set {
            let suuid = TestService.serviceUUID()!
            let cuuid = TestService.characteristicUUIDsByKey()["integer"] as! CBUUID
            let characteristic = self.characteristic(for: cuuid, serviceUUID: suuid)
            characteristic?.value = TestService.data(forKey: "integer", fromValue: "\(newValue)")
        }
    }
    
    public var stringCharacteristicValue:  String {
        get {
            let suuid = TestService.serviceUUID()!
            let cuuid = TestService.characteristicUUIDsByKey()["string"] as! CBUUID
            guard let characteristic = self.characteristic(for: cuuid, serviceUUID: suuid) else { return "" }
            return TestService.value(forKey: "string", from: characteristic.value) as! String
        }
        set {
            let suuid = TestService.serviceUUID()!
            let cuuid = TestService.characteristicUUIDsByKey()["string"] as! CBUUID
            let characteristic = self.characteristic(for: cuuid, serviceUUID: suuid)
            characteristic?.value = TestService.data(forKey: "string", fromValue: newValue)
        }
    }
    
    let mockService = TestService()
    
    override init() {
        super.init()
        self.add(mockService, isPrimary: true)
    }
}

class TestService: NSObject, RZBBluetoothRepresentable {
    
    static func serviceUUID() -> CBUUID! {
        CBUUID(string: "A349E74F-9FCA-47AB-9B15-99B88491648C")
    }
    
    static func characteristicUUIDsByKey() -> [AnyHashable : Any]! {
        [
            "integer": CBUUID(string: "4DE8F78C-3A7A-4419-8BAF-017C3CDAD64F"),
            "string" : CBUUID(string: "269AADCD-9F21-40FE-ADBB-1A03A937E286")
        ]
    }
    
    static func characteristicProperties(forKey key: String!) -> CBCharacteristicProperties {
        CBCharacteristicProperties([.read, .write, .notify])
    }
    
    static func value(forKey key: String!, from data: Data!) -> Any! {
        switch key {
        case "integer":
            let integerValue: UInt32 = data.readBytes() ?? 0
            return integerValue
        case "string":
            let stringValue: String = data.readBytes() ?? ""
            return stringValue
        default:
            return 0
        }
    }
    
    static func data(forKey key: String!, fromValue value: String!) -> Data! {
        switch key {
        case "integer":
            let integerValue = UInt32(value) ?? 0
            return integerValue.characteristicValue()
        case "string":
            return value.characteristicValue()
        default:
            return Data()
        }
    }
}

class UltramarineTestCase: RZBSimulatedTestCase {
    
    override class func simulatedDeviceClass() -> AnyClass! {
        TestDevice.self
    }
}
