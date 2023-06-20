//
//  File.swift
//
//

import Foundation

public struct JSONBody<E: Encodable & Sendable>: HTTPBody {
    
    public let value: E
    
    public var stream: AsyncStream<UInt8> {
        get throws {
            let data = try JSONEncoder().encode(value)
            return AsyncStream(sequence: data)
        }
    }
    
    public let headers: HTTPHeaders
    
    public init(value: E) {
        self.value = value
        self.headers = [
            "Content-Type": "application/json; charset=utf-8"
        ]
    }
}
