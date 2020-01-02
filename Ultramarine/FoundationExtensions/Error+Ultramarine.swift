//
//  Error+Ultramarine.swift
//  Ultramarine
//
//  Created by Chris Patterson on 1/2/20.
//

import Foundation

public enum ErrorCode: Int, Error, CustomStringConvertible {
    public typealias RawValue = Int
    
    case writeCharacteristicValueFailed
    case readCharacteristicValueFailed
    
    public var description: String {
        switch self {
        case .writeCharacteristicValueFailed: return "Write characteristic value failed."
        case .readCharacteristicValueFailed:  return "Read characteristic value failed."
        }
    }
}
