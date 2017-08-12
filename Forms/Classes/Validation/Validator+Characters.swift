//
//  Validator+Characters.swift
//  Pods
//
//  Created by Brandon Evans on 2017-08-12.
//
//

import Foundation

extension Validator where Value == String {
    public static func invalidCharacters(_ invalidSet: CharacterSet, error: ValidationError = ValidationError(errorDescription: "Contains an invalid character.")) -> Validator {
        return Validator { value in
            guard value?.rangeOfCharacter(from: invalidSet) == nil else {
                return [error]
            }
            return []
        }
    }

    public static func onlyCharacters(_ validSet: CharacterSet, error: ValidationError = ValidationError(errorDescription: "Contains an invalid character.")) -> Validator {
        return Validator { value in
            if let value = value, value.utf8.notAll({ validSet.hasMember(inPlane: $0) }) {
                return [error]
            }
            return []
        }
    }
}
