//
//  Data+Ultramarine.swift
//  Ultramarine
//
//  Created by Christopher Patterson on 1/2/2020.
//  Copyright © 2020 Christopher Patterson. All rights reserved.
//

import Foundation

// MARK: - Debug extension

/// Extension of the Foundation `Data` class that provides handy methods for debugging.
public extension Data {
    
    /// Returns a `String` containing the hex string representation of the contents of the receiver.
    /// Prior to iOS 10, the `description` method returned a string like this, which is used in unit tests,
    /// so this method was added to replicate that functionality in iOS 10+.
    var testDescription: String {
        var result = "<"
        self.withUnsafeBytes { bytes in
            for index in self.startIndex ..< self.endIndex {
                result.append(String(format: "%02x", bytes[index]))
                
                if (index+1) % 4 == 0 && (index+1) < self.endIndex {
                    result.append(" ")
                }
            }
        }
        result.append(">")
        return result
    }
}

// MARK: - Integer reading extension

/// Extension of the Foundation `Data` class that provides handy methods for reading integer values.
public extension Data {
    
    /**
     Convenience method to read bytes from the given position into the receiver.
     Avoids the developer having to deal with `UnsafeMutableBufferPointer` and `Range<Data.Index>` in Swift 3.
     
     It infers the number of bytes to read from the integer type T of the returned value,
     as shown below.
     
     ```
     var position = 4
     let someValue:UInt32 = data.readBytes(&position) // reads 4 bytes for UInt32, starting at 4th byte
     ```
     
     If the receiver is smaller than the number of bytes required, this method returns nil.
     
     - parameter position: How many bytes into the receiver to start reading bytes from;
                           on return, updated to point to the next byte after the bytes read.
     
     - returns: Value of `Integer` type `T` of the read bytes
    */
    func readBytes<T: BinaryInteger>(_ position: inout Data.Index) -> T? {
        var value:T = 0
        let size = MemoryLayout<T>.size
        
        guard self.count >= position + size else {
            return nil
        }
        
        let buffer = UnsafeMutableBufferPointer(start: &value, count: size)
        let range  = position ..< position.advanced(by: size) as Range<Data.Index>
        guard self.copyBytes(to: buffer, from: range) == size else {
            return nil
        }
        
        position += size
        return value
    }
    
    /**
     Convenience method to read bytes from position 0 of the receiver.
     Avoids the developer having to deal with `UnsafeMutableBufferPointer` and `Range<Data.Index>` in Swift 3.
     
     It infers the number of bytes to read from the integer type T of the returned value,
     as shown below.
     
     ```
     let someValue:UInt16 = data.readBytes() // reads 2 bytes for UInt16, starting at first byte
     ```
     
     If the receiver is smaller than the number of bytes required, this method returns nil.
     
     - returns: Value of `Integer` type `T` of the read bytes
    */
    func readBytes<T:BinaryInteger>() -> T? {
        var position = 0
        return self.readBytes(&position)
    }
}

// MARK: - Date reading extension

/// Extension of the Foundation `Data` class that provides handy methods for reading `Date` values.
public extension Data {
    
    /**
     * Convenience method to read bytes from the given position into the receiver.
     * Avoids the developer having to deal with `UnsafeMutableBufferPointer` and `Range<Data.Index>` in Swift 3.
     *
     * ```
     * var position = 4
     * let someDate: Date? = data.readBytes(&position)
     * ```
     *
     * If the receiver is smaller than the number of bytes required, this method returns nil.
     * If the date formatter is not able to construct a valid date, nil is returned.
     *
     * - parameter position: How many bytes into the receiver to start reading bytes from;
     *                     on return, updated to point to the next byte after the bytes read.
     *
     * - returns: `Date` object interpreted from the read bytes
     */
    func readBytes(_ position: inout Data.Index) -> Date? {
        
        let size = 7 // 7 bytes to represent 56 bits.
        guard self.count >= position + size else {
            return nil
        }
        
        guard
            let year: UInt16 = readBytes(&position),
            let month: UInt8 = readBytes(&position),
            let day: UInt8 = readBytes(&position),
            let hour: UInt8 = readBytes(&position),
            let min: UInt8 = readBytes(&position),
            let sec: UInt8 = readBytes(&position) else {
                return nil
        }
        
        let dateFormatter = DateFormatter()
        
        // Why set the `locale` and `timeZone`?
        // https://developer.apple.com/library/archive/qa/qa1480/_index.html
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let dateString = String(format: "%d %d %d %d %d %d", year, month, day, hour, min, sec)
        dateFormatter.dateFormat = "yyyy MM dd HH mm ss"
        let date = dateFormatter.date(from: dateString)
        return date
    }
    
    /**
     Convenience method to read date bytes from position 0 of the receiver.
     
     ```
     let someDate:Date = data.readBytes() // reads 7 bytes, starting with 2 bytes for UInt16 year, starting at first byte.
     ```
     
     If the receiver is smaller than the number of bytes required, this method returns nil.
     
     - returns: `Date` object interpreted from the read bytes
    */
    func readBytes() -> Date? {
        var position = 0
        return self.readBytes(&position)
    }
}

// MARK: - String reading extension

/// Extension of the Foundation `Data` class that provides handy methods for reading `String` values.
public extension Data {
    
    /**
     Convenience method to read `length` bytes from the given position in this `Data` object.
     Avoids the developer having to deal with `Range<Data.Index>`.
     
     ```
     var position = 4
     let length = 2
     let someString: String? = data.readBytes(&position, length: length)
     ```
     If the receiver is smaller than the given `position` plus `length`, this method returns nil.
     If the `String` initializer fails, this method returns nil.
     
     - parameter position: How many bytes into the receiver to start reading bytes from;
                           on return, updated to `self.count + 1` so that further `readBytes`
                           calls won't reread these bytes.
     
     - parameter count:   How many bytes to read from the receiver into the resulting `String`.
     
     - parameter encoding: The string encoding for this Data. Defaults to `.utf8`.
     
     - returns: `String` containing the read bytes, if they can be decoded using the given `encoding`; nil otherwise.
     */
    func readBytes(_ position: inout Data.Index, count: Int = Int.max, encoding: String.Encoding = .utf8) -> String? {
        var length = count
        if length == Int.max {
            length = self.count
        }
        guard self.count >= position + length else {
            return nil
        }
        
        let range = position ..< position.advanced(by: length) as Range<Data.Index>
        let strBytes = self.subdata(in: range)
        
        guard let result = String(bytes: strBytes, encoding: encoding) else {
            return nil
        }
        
        position += length
        return result
    }
    
    /**
     Convenience method to read `length` bytes from position 0 of the receiver.
     
     ```
     let someString:String = data.readBytes(length: 2) // Attempts to read 2 bytes of `data` as a UTF-8 `String`.
     ```
     
     - returns: `String` object interpreted from the read bytes
    */
    func readBytes(count: Int = Int.max, encoding: String.Encoding = .utf8) -> String? {
        var position = 0
        return self.readBytes(&position, count: count, encoding: encoding)
    }
}

// MARK: - Floating point reading extension

/// Extension of the Foundation `Data` class that provides handy methods for reading `String` values.
//public extension Data {
//
//    /**
//     Enumeration of supported float types.
//
//     - `ieee11073_float`:               IEEE-11073 FLOAT data type. 32-bit value defined with a 24-bit mantissa and 8-bit exponent.
//     - `ieee11073_sfloat`:              IEEE-11073 SHORT FLOAT data type. 16-bit value defined with a 12-bit mantissa and 4-bit exponent.
//     */
//    enum FloatingType: UInt8 {
//
//        /// IEEE-11073 FLOAT data type. 32-bit value defined with a 24-bit mantissa and 8-bit exponent.
//        case ieee11073_float
//
//        /// IEEE-11073 SHORT FLOAT data type. 16-bit value defined with a 12-bit mantissa and 4-bit exponent.
//        case ieee11073_sfloat
//
//        // MARK: Instance variables
//
//        /// Holds the number of bytes required for holding all of the information related to a IEEE 11073 Float or Short Float
//        var byteSize: Int {
//            switch self {
//            case .ieee11073_float:          return 4
//            case .ieee11073_sfloat:         return 2
//            }
//        }
//    }
//
//
//    /**
//     * Convenience method to read bytes from the given position into the receiver.
//     * Avoids the developer having to deal with `UnsafeMutableBufferPointer`, `UnsafeMutablePointer` and `Range<Data.Index>` in Swift 3.
//     *
//     * ```
//     * var position = 4
//     * let someValue: IEEE11073Float = data.readBytes(&position) // reads 4 bytes for IEEE11073Float bit pattern, starting at 4th byte
//     * ```
//     *
//     * If the receiver is smaller than the number of bytes required, this method returns nil.
//     *
//     * - parameter position: How many bytes into the receiver to start reading bytes from;
//     *                     on return, updated to point to the next byte after the bytes read.
//     *
//     * - returns: `IEEE11073Float` value of the read bytes
//     */
//    func readBytes(_ position: inout Data.Index) -> IEEE11073Float? {
//
//        var bitPattern: UInt32 = 0
//        let size = FloatingType.ieee11073_float.byteSize
//
//        guard self.count >= position + size else {
//            return nil
//        }
//
//        let buffer = UnsafeMutableBufferPointer<UInt32>(start: &bitPattern, count: size)
//        let range = position..<position.advanced(by: size) as Range<Data.Index>
//
//        guard self.copyBytes(to: buffer, from: range) == size else {
//            return nil
//        }
//
//        guard let pointer = UnsafeMutablePointer<UInt32>(OpaquePointer(buffer.baseAddress)) else {
//            return nil
//        }
//        let float = IEEE11073Float(bitPattern: pointer.pointee)
//
//        position += size
//        return float
//    }
//
//    /**
//     * Convenience method to read bytes from the given position into the receiver.
//     * Avoids the developer having to deal with `UnsafeMutableBufferPointer`, `UnsafeMutablePointer` and `Range<Data.Index>` in Swift 3.
//     *
//     * ```
//     * var position = 4
//     * let someValue: IEEE11073ShortFloat = data.readBytes(&position) // reads 2 bytes for IEEE11073ShortFloat bit pattern, starting at 4th byte
//     * ```
//     *
//     * If the receiver is smaller than the number of bytes required, this method returns nil.
//     *
//     * - parameter position: How many bytes into the receiver to start reading bytes from;
//     *                     on return, updated to point to the next byte after the bytes read.
//     *
//     * - returns: `IEEE11073ShortFloat` value of the read bytes
//     */
//    func readBytes(_ position: inout Data.Index) -> IEEE11073ShortFloat? {
//
//        var bitPattern: UInt16 = 0
//        let size = FloatingType.ieee11073_sfloat.byteSize
//
//        guard self.count >= position + size else {
//            return nil
//        }
//
//        let buffer = UnsafeMutableBufferPointer<UInt16>(start: &bitPattern, count: size)
//        let range = position..<position.advanced(by: size) as Range<Data.Index>
//
//        guard self.copyBytes(to: buffer, from: range) == size else {
//            return nil
//        }
//
//        guard let pointer = UnsafeMutablePointer<UInt16>(OpaquePointer(buffer.baseAddress)) else {
//            return nil
//        }
//        let sFloat = IEEE11073ShortFloat(bitPattern: pointer.pointee)
//
//        position += size
//        return sFloat
//    }
//
//    /**
//     * Convenience method to read bytes from the given position into the receiver.
//     * Avoids the developer having to deal with `UnsafeMutableBufferPointer`, `UnsafeMutablePointer` and `Range<Data.Index>` in Swift 3.
//     *
//     * ```
//     * var position = 4
//     * let someValue: Double = data.readBytes(.ieee11073_float, &position) // reads 4 bytes for Double, starting at 4th byte
//     * ```
//     *
//     * If the receiver is smaller than the number of bytes required, this method returns nil.
//     *
//     * - parameter floatType: Which kind of `FloatingType` is represented by the bytes. Performs the appropriate IEEE 11073 conversion based on what `FloatingType` is sent in.
//     * - parameter position: How many bytes into the receiver to start reading bytes from;
//     *                     on return, updated to point to the next byte after the bytes read.
//     *
//     * - returns: Value of `FloatingPoint` type `T` of the read bytes
//     */
//    func readBytes<T: FloatingPoint>(_ floatType: FloatingType, _ position: inout Data.Index) -> T? {
//
//        var value: T = 0
//        var calculatedValue: T?
//        let size = floatType.byteSize
//
//        guard self.count >= position + size else {
//            return nil
//        }
//
//        let buffer = UnsafeMutableBufferPointer<T>(start: &value, count: size)
//        let range = position..<position.advanced(by: size) as Range<Data.Index>
//
//        guard self.copyBytes(to: buffer, from: range) == size else {
//            return nil
//        }
//
//        switch floatType {
//        case .ieee11073_float:
//            guard let pointer = UnsafeMutablePointer<UInt32>(OpaquePointer(buffer.baseAddress)) else {
//                return nil
//            }
//            let float = IEEE11073Float(bitPattern: pointer.pointee)
//            calculatedValue = T(float.value)
//
//        case .ieee11073_sfloat:
//            guard let pointer = UnsafeMutablePointer<UInt16>(OpaquePointer(buffer.baseAddress)) else {
//                return nil
//            }
//            let sFloat = IEEE11073ShortFloat(bitPattern: pointer.pointee)
//            calculatedValue = T(sFloat.value)
//        }
//
//        position += size
//        return calculatedValue
//    }
//}
