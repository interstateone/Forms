//
//  Validator+RegExp.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

import Foundation

extension Validator where Value == String {
    static func regularExpression(_ regularExpression: NSRegularExpression, error: ValidationError = ValidationError(errorDescription: "")) -> Validator {
        return Validator { value in
            guard
                let value = value,
                NSPredicate(format: "SELF MATCHES %@", regularExpression).evaluate(with: value)
            else {
                return [error]
            }
            return []
        }
    }
}
