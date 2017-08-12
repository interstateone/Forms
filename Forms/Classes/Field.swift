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

    @discardableResult
    public func validate() -> [ValidationError] {
        return []
    }
}

extension UntypedField: Hashable {
    public var hashValue: Int { return id.hashValue }
    public static func ==(lhs: UntypedField, rhs: UntypedField) -> Bool { return lhs.id == rhs.id }
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
            handleEvent(.change)
            
            for dependent in validationDependents {
                dependent.validate()
            }
        }
    }
    var valueChanged: ((Value?) -> Void)?

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
    ///      │     ▲
    ///      └─────┘
    ///       change
    public enum State {
        case untouched, focused, changed, blurred

        public enum Event {
            case focus, change, blur
        }

        internal mutating func handleEvent(_ event: Event) {
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
            case (.blurred, .change):
                self = .blurred
            default:
                break
            }
        }
    }

    private(set) public var state: State = .untouched

    public func handleEvent(_ event: State.Event) {
        switch (event, validatesWhen) {
        case (.change, .changed):
            validate()
        case (.blur, .blurred):
            validate()
        default:
            break
        }

        state.handleEvent(event)
    }

    public var validators: [Validator<Value>] = []
    public typealias ValidationHandler = ([ValidationError]) -> Void
    public var onValidate: ValidationHandler?
    public var validatesWhen: ValidationTiming = .requested
    /// The results of the last validation. Access doesn't result in validation being performed.
    public var lastValidationErrors: [ValidationError] = []

    public init<Id: RawRepresentable>(_ id: Id, name: String, value: Value?) where Id.RawValue == String {
        self.value = value
        super.init(id, name: name, value: value)
    }

    /// Manually request validation. Results will be returned and stored in `lastValidationErrors` for future access without causing re-validation.
    @discardableResult
    public override func validate() -> [ValidationError] {
        lastValidationErrors = validators.joined().validate(value)
        onValidate?(lastValidationErrors)
        return lastValidationErrors
    }

    /// Adds a validator to be used in future validations
    ///
    /// - Parameter validator: A validator that can validate this field's Value type
    /// - Returns: The field, for the purpose of chained method calls
    @discardableResult
    public func validate(with validator: Validator<Value>) -> Self {
        validators.append(validator)
        return self
    }

    /// Adds a validator to be used in future validations, along with a field dependency
    ///
    /// - Parameter fieldDependency: A field that will be registered as a dependency for this validation. Changes to this field dependency's value will cause validation to occur immediately regardless of this field's validatesWhen property.
    /// - Parameter validator: A validation closure that can validate this field's Value type and the type of the field dependency
    /// - Returns: The field, for the purpose of chained method calls
    @discardableResult
    public func validate<A>(with fieldDependency: Field<A>, validator: @escaping (Value?, A?) -> [ValidationError]) -> Self {
        validators.append(Validator({ validator($0, fieldDependency.value) }))
        fieldDependency.validationDependents.append(self)
        return self
    }

    /// Adds a validator to be used in future validations, along with a two field dependencies
    ///
    /// - Parameter fieldDependency1: A field that will be registered as a dependency for this validation. Changes to this field dependency's value will cause validation to occur immediately regardless of this field's validatesWhen property.
    /// - Parameter fieldDependency2: A second field that will be registered as a dependency for this validation. Changes to this field dependency's value will cause validation to occur immediately regardless of this field's validatesWhen property.
    /// - Parameter validator: A validation closure that can validate this field's Value type and the type of the field dependency
    /// - Returns: The field, for the purpose of chained method calls
    @discardableResult
    public func validate<A, B>(with fieldDependency1: Field<A>, and fieldDependency2: Field<B>, validator: @escaping (Value?, A?, B?) -> [ValidationError]) -> Self {
        validators.append(Validator({ validator($0, fieldDependency1.value, fieldDependency2.value) }))
        fieldDependency1.validationDependents.append(self)
        fieldDependency2.validationDependents.append(self)
        return self
    }
}

public enum ValidationTiming {
    case requested, blurred, changed
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
