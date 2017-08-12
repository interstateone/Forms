//
//  ValidationError.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

import Foundation

/// Basic concrete implementation of LocalizedError
/// Will be displayed as-is in a UI
public struct ValidationError: LocalizedError {
    public var errorDescription: String?
    public var failureReason: String?
    public var helpAnchor: String?
    public var recoverySuggestion: String?

    public init(errorDescription: String) {
        self.errorDescription = errorDescription
    }
}
