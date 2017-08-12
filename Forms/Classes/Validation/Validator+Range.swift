//
//  Validator+Range.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

import Foundation

extension Validator where Value: Comparable {
    static func greaterThan(_ minimum: Value, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            guard
                let value = value,
                value > minimum
            else {
                return [error ?? ValidationError(errorDescription: "Must be greater than \(minimum)")]
            }
            return []
        }
    }

    static func greaterThanOrEqualTo(_ minimum: Value, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            guard
                let value = value,
                value >= minimum
                else {
                    return [error ?? ValidationError(errorDescription: "Must be greater than or equal to \(minimum)")]
            }
            return []
        }
    }

    static func lessThanOrEqualTo(_ maximum: Value, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            guard
                let value = value,
                value <= maximum
                else {
                    return [error ?? ValidationError(errorDescription: "Must be less than or equal to \(maximum)")]
            }
            return []
        }
    }

    static func lessThan(_ maximum: Value, error: ValidationError? = nil) -> Validator {
        return Validator { value in
            guard
                let value = value,
                value < maximum
                else {
                    return [error ?? ValidationError(errorDescription: "Must be less than \(maximum)")]
            }
            return []
        }
    }
}
