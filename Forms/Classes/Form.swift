import Foundation

public class Form {
    public var sections: [Section] = []
    public var fields: [UntypedField] {
        return sections.flatMap { $0.fields }
    }

    public init(sections: [Section]) {
        self.sections = sections
    }

    public var values: [String: Any?] {
        return fields.reduce([:]) { values, field in
            var values = values
            values[field.id] = field.untypedValue
            return values
        }
    }

    public func validate() -> [String: [String]] {
        return fields.reduce([:]) { errors, field in
            var errors = errors
            let fieldErrors = field.validate().map { $0.localizedDescription }
            if fieldErrors.isNotEmpty {
                errors[field.id] = fieldErrors
            }
            return errors
        }
    }
}
