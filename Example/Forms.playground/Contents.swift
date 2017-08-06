import UIKit
import PlaygroundSupport

struct SignUpInfo {
    var email: String?
    var password: String?
    var passwordConfirmation: String?
}

var credentials = SignUpInfo(email: "", password: "", passwordConfirmation: nil)

enum Id: String {
    case email, password, passwordConfirmation, securityToken
}

let emailField = Field(Id.email, name: "Email", value: credentials.email)
let passwordField = Field(Id.password, name: "Password", value: credentials.password)
                        .validate(with: CharacterSetValidator(notAllowed: .whitespacesAndNewlines)) 
                        .validate(with: emailField) { password, email -> [ValidationError] in
                            if let password = password, let email = email, password.contains(email) {
                                return [ValidationError(errorDescription: "Password can't contain your email address")]
                            }
                            return []
                        }
let passwordConfirmationField = Field(Id.passwordConfirmation, name: "Confirm Password", value: credentials.passwordConfirmation)
                                    .validate(with: passwordField) { confirmation, password -> [ValidationError] in
                                        guard
                                            let confirmation = confirmation,
                                            let password = password,
                                            confirmation == password
                                        else {
                                            return [ValidationError(errorDescription: "Passwords don't match")]
                                        }
                                        return []
                                    }

let calculatedField = CalculatedField(Id.securityToken, name: "SecurityToken", field1: passwordField) { $0?.uppercased() }

let section = Section(id: "section1", title: "Section 1", fields: [emailField, passwordField, passwordConfirmationField, calculatedField])

let form = Form(sections: [section])

print(form.values)
passwordField.value = "new password"
print(form.values)

print(form.validate())

emailField.value = "test123@mailinator.com"
passwordField.value = "lol test123@mailinator.com"
print(form.validate())

passwordField.value = "lol_password"
passwordConfirmationField.value = "lol_password"
print(form.validate())

let view = FormView(frame: CGRect(x: 0, y: 0, width: 200, height: 500))
view.viewProvider = CustomFieldViewProvider()
view.reload(with: form)

PlaygroundPage.current.liveView = view
