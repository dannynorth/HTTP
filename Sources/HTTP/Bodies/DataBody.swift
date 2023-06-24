//
//  File.swift
//  
//

import Foundation

public struct DataBody: HTTPBody {
    
    public let data: Data
    
    public let headers: HTTPHeaders
    
    public init(_ data: Data, headers: HTTPHeaders? = nil) {
        self.data = data
        self.headers = headers ?? .init()
    }
    
    public var stream: AsyncStream<UInt8> {
        return AsyncStream(sequence: data)
    }
    
}

extension Data: HTTPBody {
    
    public var stream: AsyncStream<UInt8> {
        return AsyncStream(sequence: self)
    }
    
}
