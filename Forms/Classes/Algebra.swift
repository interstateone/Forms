//
//  Algebra.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

public protocol Semigroup {
    /// Associative binary operation
    static func op(_ lhs: Self, _ rhs: Self) -> Self
}

public protocol Multiplicative: Semigroup {
    /// Identity
    static var one: Self { get }
}

extension Array where Element: Multiplicative {
    func joined() -> Element {
        return reduce(Element.one, Element.op)
    }
}
