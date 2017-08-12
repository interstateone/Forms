import Foundation

public struct Validator<Value> {
    public typealias Validate = (Value?) -> [ValidationError]
    public let validate: Validate

    public init(_ validate: @escaping Validate) {
        self.validate = validate
    }
}

// MARK: - Operations

extension Validator {
    public static func && (v1: Validator, v2: Validator) -> Validator {
        return Validator { value in
            let e1 = v1.validate(value)
            let e2 = v2.validate(value)
            if e1.isEmpty && e2.isEmpty { return [] }
            return e1 + e2
        }
    }

    public static func || (v1: Validator, v2: Validator) -> Validator {
        return Validator { value in
            let e1 = v1.validate(value)
            let e2 = v2.validate(value)
            if e1.isEmpty || e2.isEmpty { return [] }
            return e1 + e2
        }
    }
}

// MARK: - Algebra

/// Validator could also be additive, but a definition of `zero` wouldn't have any meaningful error information
extension Validator: Multiplicative {
    public static func op(_ lhs: Validator<Value>, _ rhs: Validator<Value>) -> Validator<Value> {
        return lhs && rhs
    }

    public static var one: Validator { return Validator { _ in [] } }
}
