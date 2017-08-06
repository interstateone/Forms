import Foundation

public class UntypedField {
    public let id: String
    public let name: String
    public var untypedValue: Any? {
        didSet {
            untypedValueChanged?(untypedValue)
        }
    }
    var valueDependents: [UntypedField] = []
    var validationDependents: [UntypedField] = []
    var untypedValueChanged: ((Any?) -> Void)?

    public var isHidden = false
//    public var isHidden: ((Form) -> Bool)?

    public init<Id: RawRepresentable>(_ id: Id, name: String, value: Any?) where Id.RawValue == String {
        self.id = id.rawValue
        self.name = name
        self.untypedValue = value
    }

    public func validate() -> [ValidationError] {
        return []
    }
}

extension UntypedField: Hashable {
    public var hashValue: Int { return id.hashValue }
    public static func ==(lhs: UntypedField, rhs: UntypedField) -> Bool { return lhs.id == rhs.id }
}

///    ┌─────────┐
/// ┌─▶│Untouched│──┬───────┐
/// │  └─────────┘  │       │
/// │               │       │
/// │blur           │focus  │
/// │               │       │
/// │  ┌─────────┐  │       │
/// └──│ Focused │◀─┘       │
///    └─────────┘          │
///         │               │
///         │change         │change
///         ▼               │
///    ┌─────────┐◀─┐       │
/// ┌─▶│ Changed │  │change │
/// │  └─────────┘──┘       │
/// │       │               │
/// │focus  │blur           │
/// │       ▼               │
/// │  ┌─────────┐          │
/// └──│ Blurred │◀─────────┘
///    └─────────┘
public enum FieldState {
    case untouched, focused, changed, blurred

    public enum Event {
        case focus, change, blur
    }

    mutating func handleEvent(_ event: Event) {
        switch (self, event) {
        case (.untouched, .focus):
            self = .focused
        case (.untouched, .change):
            self = .blurred
        case (.focused, .blur):
            self = .untouched
        case (.focused, .change):
            self = .changed
        case (.changed, .blur):
            self = .blurred
        case (.changed, .change):
            self = .changed
        case (.blurred, .focus):
            self = .changed
        default:
            break
        }
    }
}

public class Field<Value: Equatable>: UntypedField {
    public override var untypedValue: Any? {
        get { return value }
        set {
            value = newValue as? Value
            untypedValueChanged?(newValue)
        }
    }
    public var value: Value? {
        didSet {
            valueChanged?(value)
            state.handleEvent(.change)
        }
    }
    var valueChanged: ((Value?) -> Void)?

    public var state: FieldState = .untouched {
        didSet {
            switch (state, validatesWhen) {
            case (.changed, .changed):
                validate()
            case (.blurred, .blurred):
                validate()
            default:
                break
            }
        }
    }

    public var validators: [ValidatorWrapper<Value>] = []
    public typealias ValidationHandler = ([ValidationError]) -> Void
    public var onValidate: ValidationHandler?
    public var validatesWhen: ValidationTiming = .requested
    public var lastValidationErrors: [ValidationError] = []

    public init<Id: RawRepresentable>(_ id: Id, name: String, value: Value?) where Id.RawValue == String {
        self.value = value
        super.init(id, name: name, value: value)
    }

    @discardableResult
    public override func validate() -> [ValidationError] {
        lastValidationErrors = validators.flatMap { $0.validate(value) }
        onValidate?(lastValidationErrors)
        return lastValidationErrors
    }

    // A little sugar to allow building a chained field definition
    public func validate<V: Validator>(with validator: V) -> Self where V.Value == Value {
        validators.append(ValidatorWrapper({ validator.validate($0) }))
        return self
    }

    public func validate<A>(with field1: Field<A>, validator: @escaping (Value?, A?) -> [ValidationError]) -> Self {
        validators.append(ValidatorWrapper({ validator($0, field1.value) }))
        field1.validationDependents.append(self)
        return self
    }

    public func validate<A, B>(with field1: Field<A>, field2: Field<B>, validator: @escaping (Value?, A?, B?) -> [ValidationError]) -> Self {
        validators.append(ValidatorWrapper({ validator($0, field1.value, field2.value) }))
        field1.validationDependents.append(self)
        field2.validationDependents.append(self)
        return self
    }
}

public class CalculatedField<Value: Equatable>: Field<Value> {
    private let closure: () -> Value?

    public override var value: Value? {
        get {
            return closure()
        }
        set {
            assertionFailure("Can't set the value of a calculated field.")
        }
    }

    public init<Id: RawRepresentable, A>(_ id: Id, name: String, field1: Field<A>, closure: @escaping (A?) -> Value?) where Id.RawValue == String {
        self.closure = { closure(field1.value) }
        super.init(id, name: name, value: self.closure())

        field1.valueDependents.append(self)
    }

    public init<Id: RawRepresentable, A, B>(_ id: Id, name: String, field1: Field<A>, field2: Field<B>, closure: @escaping (A?, B?) -> Value) where Id.RawValue == String {
        self.closure = { closure(field1.value, field2.value) }
        super.init(id, name: name, value: self.closure())

        field1.valueDependents.append(self)
        field2.valueDependents.append(self)
    }
}
