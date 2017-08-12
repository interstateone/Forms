import Foundation

extension Array {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

extension Sequence {
    func all(_ predicate: @escaping (Iterator.Element) -> Bool) -> Bool {
        return reduce(true) { $0 && predicate($1) }
    }

    func notAll(_ predicate: @escaping (Iterator.Element) -> Bool) -> Bool {
        return !all(predicate)
    }
}
