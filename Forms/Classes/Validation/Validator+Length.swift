//
//  Validator+Length.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

import Foundation

extension Validator where Value == String {
    public static func minimumLength(_ minimumLength: Int, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            guard
                let value = value,
                value.characters.count >= minimumLength
                else {
                    return [error ?? ValidationError(errorDescription: "Must be at least \(minimumLength) characters.")]
            }
            return []
        }
    }

    public static func maximumLength(_ maximumLength: Int, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            if let value = value,
               value.characters.count > maximumLength{
                return [error ?? ValidationError(errorDescription: "Must be no more than \(maximumLength) characters.")]
            }
            return []
        }
    }

    public static func exactLength(_ exactLength: Int, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            guard
                let value = value,
                value.characters.count == exactLength
                else {
                    return [error ?? ValidationError(errorDescription: "Must be exactly \(maximumLength) characters.")]
            }
            return []
        }
    }
}
