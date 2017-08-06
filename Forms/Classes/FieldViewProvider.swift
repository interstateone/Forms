import UIKit

public protocol IdentifiableView {
    var id: String { get }
    var view: UIView { get }
}

extension IdentifiableView where Self: UIView {
    public var view: UIView {
        return self
    }
}

public protocol FieldViewProvider {
    func viewForSection(_ section: Section, formView: FormView) -> IdentifiableView
    func viewForField(_ field: UntypedField, formView: FormView) -> IdentifiableView
}

public class CustomFieldViewProvider: FieldViewProvider {
    public func viewForSection(_ section: Section, formView: FormView) -> IdentifiableView {
        return SectionView(id: section.id, title: section.title, collapseToggled: {
            try? formView.toggleSection(withId: section.id)
        })
    }

    public func viewForField(_ field: UntypedField, formView: FormView) -> IdentifiableView {
        return LabelFieldView(id: field.id, name: field.name)
    }

    public init() {}
}
