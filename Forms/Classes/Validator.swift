import Foundation

public protocol Validator {
    associatedtype Value
    func validate(_ value: Value?) -> [ValidationError]
}

public enum ValidationTiming {
    case requested, blurred, changed
}

/// Provides a concrete implementation of Validator
public struct ValidatorWrapper<Value>: Validator {
    public typealias Wrapper = (Value?) -> [ValidationError]
    public let wrapper: Wrapper

    public init(_ wrapper: @escaping Wrapper) {
        self.wrapper = wrapper
    }

    public func validate(_ value: Value?) -> [ValidationError] {
        return wrapper(value)
    }
}

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

/// An example Validator of Strings
public struct CharacterSetValidator: Validator {
    public let characterSet: CharacterSet

    public init(notAllowed characterSet: CharacterSet) {
        self.characterSet = characterSet
    }

    public func validate(_ value: String?) -> [ValidationError] {
        if value?.rangeOfCharacter(from: characterSet) != nil {
            return [ValidationError(errorDescription: "Contains an invalid character.")]
        }

        return []
    }
}
