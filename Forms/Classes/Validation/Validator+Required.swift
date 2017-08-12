//
//  Validator+Required.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

import Foundation

extension Validator {
    static func required(error: ValidationError = ValidationError(errorDescription: "")) -> Validator {
        return Validator { value in
            if let string = value as? String {
                guard string.isNotEmpty else { return [error] }
            }
            guard value != nil else { return [error] }
            return []
        }
    }
}
