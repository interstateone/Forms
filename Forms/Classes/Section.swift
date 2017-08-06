import Foundation

public class Section {
    public let id: String
    public var title: String
    public var fields: [UntypedField]

    public let collapsible: Bool
    internal var collapsed: Bool = false
    public var collapsedDidChange: ((Section) -> ())?

    public init(id: String, title: String = "", fields: [UntypedField] = [], collapsible: Bool = true) {
        self.id = id
        self.title = title
        self.fields = fields
        self.collapsible = collapsible
    }

    public func update(_ values: [String: Any?]) {
        for field in fields {
            if let value = values[field.id] {
                field.untypedValue = value
            }
        }
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
            if !fieldErrors.isEmpty {
                errors[field.id] = fieldErrors
            }
            return errors
        }
    }

    public func toggleCollapsed() {
        collapsed = !collapsed
        collapsedDidChange?(self)
    }
}

extension Section: Equatable {
    static public func ==(lhs: Section, rhs: Section) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.collapsed == rhs.collapsed
    }
}

extension Section: Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
}
