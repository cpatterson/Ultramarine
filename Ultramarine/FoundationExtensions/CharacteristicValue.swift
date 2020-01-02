//
//  CharacteristicValue.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 1/2/2020.
//  Copyright © 2020 Christopher Patterson. All rights reserved.
//

import Foundation

/**
 *  Common protocol for classes that provide a `Data` object intended for use as 
 *  a `CBCharacteristic.value`.
 *
 *  In addition, this protocol also inherits the `CustomStringConvertible` Foundation protocol,
 *  thus requiring adopting classes to provide a custom `description` method for debugging purposes as well.
 *
 *  In the Ultramarine framework, this protocol is adopted by extensions to
 *  Foundation `Data` class and integer types, as well as the following classes:
 *
 *  - `InsulinDose`
 *  - `InsulinDoseContext`
 *  - `InjectorStatus`
 *  - `InjectorTimeInterval`
 *  - `InjectorEvent`
 *  - `InjectorFeatures`
 *  - `RecordAccessControl`
 */
public protocol CharacteristicValue: CustomStringConvertible {
    
    /**
     Returns a `Data` object containing the packed data of this object intended for use
     as the value of a `CBCharacteristic` object.
     
     - returns: `Data` containing the packed data of the receiver.
     
     - throws: `Ultramarine.ErrorCode.writeCharacteristicValueFailed` if there are any problems constructing the characteristic values.
     */
    func characteristicValue() throws -> Data
    
    /**
     Optional variant method returning a `Data` object containing the packed data of this object
     intended for use as the value of a `CBCharacteristic` object.
     
     This variant takes an optional `profileVersionNumber` property for cases where the
     characteristic value of an object may vary based on the version of the BLE profile associated with the type.
     
     The default implementation assumes a `nil` value for the `profileVersionNumber` parameter and
     calls through to the unparameterized, required `characteristicValue()` method.
     
     Adopters of this protocol may implement the parameterized version if needed.
     */
    func characteristicValue(for profileVersion: Float?) throws -> Data
}

/**
 Extension for the `CharacteristicValue` protocol providing a default implementation for the
 optional parameterized version of the `characteristicValue()` method.
 
 The default implementation assumes a `nil` value for the `profileVersionNumber` parameter and
 calls through to the unparameterized, required `characteristicValue()` method.
 */
extension CharacteristicValue {
    
    /**
     Optional variant method returning a `Data` object containing the packed data of this object
     intended for use as the value of a `CBCharacteristic` object.
     
     This variant takes an optional `profileVersionNumber` property for cases where the
     characteristic value of an object may vary based on the version of the BLE profile associated with the type.
     
     This default implementation assumes a `nil` value for the `profileVersionNumber` parameter and
     calls through to the unparameterized, required `characteristicValue()` method.
     
     Adopters of this protocol may implement the parameterized version if needed.
     */
    public func characteristicValue(for profileVersion: Float? = nil) throws -> Data {
        return try characteristicValue()
    }
}

/**
 *  Extension to `Data` class to allow it to adopt the `CharacteristicValue` protocol.
 */
extension Data: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
     
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        return self
    }
}

/**
 *  Extension to `UInt8` type to allow it to adopt the `CharacteristicValue` protocol.
 */
extension UInt8: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
     
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        var bytes = self
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: bytes))
    }
}

/**
 *  Extension to `Int16` type to allow it to adopt the `CharacteristicValue` protocol.
 */
extension Int16: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
     
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        var bytes = self.littleEndian
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: bytes))
    }
}

/**
 *  Extension to `UInt16` type to allow it to adopt the `CharacteristicValue` protocol.
 */
extension UInt16: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
     
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        var bytes = self.littleEndian
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: bytes))
    }
}

/**
 *  Extension to `UInt32` type to allow it to adopt the `CharacteristicValue` protocol.
 */
extension UInt32: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
     
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        var bytes = self.littleEndian
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: bytes))
    }
}

/**
 *  Extension to `UInt64` type to allow it to adopt the `CharacteristicValue` protocol.
 */
extension UInt64: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
     
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        var bytes = self.littleEndian
        return Data(bytes: &bytes, count: MemoryLayout.size(ofValue: bytes))
    }
}

/**
 * Extension to `String` type to allow it to adopt the `CharacteristicValue` protocol.
 */
extension String: CharacteristicValue {
    
    /**
     Returns this object (`self`) as the value for a `CBCharacteristic` object.
 
     - returns: `self` as the characteristic value.
     */
    public func characteristicValue() -> Data {
        return Data(self.utf8)
    }
}

/**
 * Extension to `Date` type to allow it to adopt the `CharacteristicValue` protocol.
 * This object is encoded as a IEEE 11073 Date
 */
extension Date: CharacteristicValue {
    
    /**
     Returns this object (`self`) which has been converted to a IEEE 11073 date format as the value for a `CBCharacteristic` object.
     
     - returns: `Data` containing the encoded IEEE 11073 date format of (`self`).
     
     - throws: `Ultramarine.ErrorCode.writeCharacteristicValueFailed` if there are any problems constructing the characteristic values.
     */
    public func characteristicValue() throws -> Data {
        
        let componentFlags: Set<Calendar.Component> = [.second, .minute, .hour, .day, .month, .year]
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dateComponents = calendar.dateComponents(componentFlags, from: self)

        /**
         IEEE 11073 date is encoded as `UInt16` year, `UInt8` month, `UInt8` day, `UInt8` hour, `UInt8` minute, and `UInt8` second
         */
        guard
            let year = dateComponents.year,
            let month = dateComponents.month,
            let day = dateComponents.day,
            let hour = dateComponents.hour,
            let minute = dateComponents.minute,
            let second = dateComponents.second else {
                throw Ultramarine.ErrorCode.writeCharacteristicValueFailed
        }
        
        let rawYear = UInt16(year).littleEndian
        let rawMonth = UInt8(month)
        let rawDay = UInt8(day)
        let rawHour = UInt8(hour)
        let rawMinute = UInt8(minute)
        let rawSecond = UInt8(second)
        var data = rawYear.characteristicValue()
        data.append(rawMonth.characteristicValue())
        data.append(rawDay.characteristicValue())
        data.append(rawHour.characteristicValue())
        data.append(rawMinute.characteristicValue())
        data.append(rawSecond.characteristicValue())
        return data
    }
}

//extension IEEE11073Float: CharacteristicValue {
//    /**
//    Returns the `bitPattern` as the value for a `CBCharacteristic` object.
//
//    - returns: `Data` containing the `bitPattern` of (`self`).
//    */
//    public func characteristicValue() -> Data {
//        return self.bitPattern.characteristicValue()
//    }
//}
//
//
//extension IEEE11073ShortFloat: CharacteristicValue {
//    /**
//     Returns the `bitPattern` as the value for a `CBCharacteristic` object.
//
//     - returns: `Data` containing the `bitPattern` of (`self`).
//     */
//    public func characteristicValue() -> Data {
//        return self.bitPattern.characteristicValue()
//    }
//}
