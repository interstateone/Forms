import UIKit

public class FormView: UIView {
    public var scrollView: UIScrollView!
    /// The stack view that is managed internally to display the form views. This is a public property in order to allow customization of its layout properties without re-implementing its interface, but don't do anything silly with that access.
    public var stackView: UIStackView!
    /// A callback invoked when a field's value has changed anywhere in the form
    public var valueChanged: ((_ sectionId: String, _ fieldId: String, _ value: Any?) -> Void)? = nil
    private var form = Form(sections: [])
    public var viewProvider: FieldViewProvider!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        let scrollView = UIScrollView(frame: frame)
        self.scrollView = scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(frame: frame)
        self.stackView = stackView
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally

        addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: 0).isActive = true

        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(greaterThanOrEqualTo: scrollView.bottomAnchor, constant: 0).isActive = true
        stackView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }


    /// Removes the existing form views and adds new views from the new form
    ///
    /// - Parameter form: The new form to display
    public func reload(with form: Form) {
        removeAllViews()
        self.form = form

        for (sectionIndex, section) in form.sections.enumerated() {
            prepareSectionAndAddToStackView(section, at: sectionIndex)

            for (fieldIndex, field) in section.fields.enumerated() {
                prepareFieldAndAddToStackView(field, at: fieldIndex, in: section)
            }
        }
    }

    // MARK: - Section Visibility
    /// Toggles a section between expanded and collapsed
    ///
    /// - Parameter sectionId: The id of the section to toggle
    /// - Throws: FormView.Error.invalidSectionId if a section with that id can't be found in the current form
    ///           FormView.Error.sectionNotCollapsible if the section with that id isn't collapsible
    public func toggleSection(withId sectionId: String) throws {
        guard let section = form.sections.filter({ $0.id == sectionId }).first else { throw FormView.Error.invalidSectionId }
        guard section.collapsible == true else { throw FormView.Error.sectionNotCollapsible }

        section.collapsed = !section.collapsed
        updateCollapsedStateOfSection(section)
    }


    /// Shows a collapsed section
    ///
    /// - Parameter sectionId: The id of the section to show
    /// - Throws: FormView.Error.invalidSectionId if a section with that id can't be found in the current form
    ///           FormView.Error.sectionNotCollapsible if the section with that id isn't collapsible
    ///           FormView.Error.sectionAlreadyShown if the section with that id is already shown
    public func showSection(withId sectionId: String) throws {
        guard let section = form.sections.filter({ $0.id == sectionId }).first else { throw FormView.Error.invalidSectionId }
        guard section.collapsible == true else { throw FormView.Error.sectionNotCollapsible }
        guard section.collapsed == true else { throw FormView.Error.sectionAlreadyVisible }

        try toggleSection(withId: sectionId)
    }

    /// Hides an expanded section
    ///
    /// - Parameter sectionId: The id of the section to hide
    /// - Throws: FormView.Error.invalidSectionId if a section with that id can't be found in the current form
    ///           FormView.Error.sectionNotCollapsible if the section with that id isn't collapsible
    ///           FormView.Error.sectionAlreadyHidden if the section with that id is already hidden
    public func hideSection(withId sectionId: String) throws {
        guard let section = form.sections.filter({ $0.id == sectionId }).first else { throw FormView.Error.invalidSectionId }
        guard section.collapsible == true else { throw FormView.Error.sectionNotCollapsible }
        guard section.collapsed == false else { throw FormView.Error.sectionAlreadyHidden }

        try toggleSection(withId: sectionId)
    }

    // MARK: - Form Mutation
    // The section/field add/remove methods could have accompanying versions that take an id instead of an index where appropriate

    /// Adds a section at the given index
    ///
    /// - Parameters:
    ///   - section: The section to add
    ///   - sectionIndex: The index to add the section at.
    /// - Throws: FormView.Error.invalidSectionIndex if the sectionIndex is less than 0 or greater than the number of sections currently in the form
    public func addSection(_ section: Section, at sectionIndex: Int) throws {
        guard sectionIndex >= 0, sectionIndex <= form.sections.count else { throw FormView.Error.invalidSectionIndex }

        form.sections.insert(section, at: sectionIndex)
        prepareSectionAndAddToStackView(section, at: sectionIndex)
    }


    /// Removes a section at the given index
    ///
    /// - Parameter sectionIndex: The index of the section to remove
    /// - Throws: FormView.Error.invalidSectionIndex if the sectionIndex is less than 0 or greater than the number of sections currently in the form
    public func removeSection(at sectionIndex: Int) throws {
        guard sectionIndex >= 0, sectionIndex < form.sections.count else { throw FormView.Error.invalidSectionIndex }

        let section = form.sections[sectionIndex]

        guard let sectionView = stackView.arrangedSubviews.flatMap({ $0 as? IdentifiableView }).first(where: { $0.id == section.id }) else { return }
        stackView.removeArrangedSubview((sectionView as! UIView))
        form.sections.remove(at: sectionIndex)
    }


    /// Adds a field at the given index in the section with the given id
    ///
    /// - Parameters:
    ///   - field: The field to add
    ///   - sectionId: The id of the section in which to add the field
    ///   - fieldIndex: The index to add the field at within its new section
    /// - Throws: FormView.Error.invalidSectionId if a section with that id can't be found in the current form
    ///           FormView.Error.invalidFieldIndex if the fieldIndex is less than 0 or greater than the number of fields currently in the section
    public func addField(_ field: UntypedField, inSectionWithId sectionId: String, at fieldIndex: Int) throws {
        guard let section = form.sections.filter({ $0.id == sectionId }).first else { throw FormView.Error.invalidSectionId }
        guard fieldIndex >= 0, fieldIndex <= section.fields.count else { throw FormView.Error.invalidFieldIndex }

        section.fields.insert(field, at: fieldIndex)
        prepareFieldAndAddToStackView(field, at: fieldIndex, in: section)
    }

    /// Removes a field at the given index in the section with the given id
    ///
    /// - Parameters:
    ///   - sectionId: The id of the section from which to remove the field
    ///   - fieldIndex: The index of the field to remove
    /// - Throws: FormView.Error.invalidSectionId if a section with that id can't be found in the current form
    ///           FormView.Error.invalidFieldIndex if the fieldIndex is less than 0 or greater than the number of fields currently in the section
    public func removeField(inSectionWithId sectionId: String, at fieldIndex: Int) throws {
        guard let section = form.sections.filter({ $0.id == sectionId }).first else { throw FormView.Error.invalidSectionId }
        guard fieldIndex >= 0, fieldIndex < section.fields.count else { throw FormView.Error.invalidFieldIndex }

        let field = section.fields[fieldIndex]

        guard let fieldView = stackView.arrangedSubviews.flatMap({ $0.subviews }).flatMap({ $0 as? IdentifiableView }).first(where: { $0.id == field.id }) else { return }
        stackView?.removeArrangedSubview((fieldView as! UIView))
        section.fields.remove(at: fieldIndex)
    }

    // MARK: - Private methods
    private func removeAllViews() {
        for arrangedSubview in stackView?.arrangedSubviews ?? [] {
            stackView?.removeArrangedSubview(arrangedSubview)
        }
    }

    private func updateCollapsedStateOfSection(_ section: Section) {
        let fieldViews = stackView.arrangedSubviews.flatMap({ $0 as? IdentifiableView })

        guard
            let firstFieldView = fieldViews.first(where: { $0.id == section.fields.first?.id }) as? UIView,
            let firstFieldIndexToShow = stackView.arrangedSubviews.index(where: { $0 === firstFieldView }),
            let lastFieldView = fieldViews.first(where: { $0.id == section.fields.last?.id }) as? UIView,
            let lastFieldIndexToShow = stackView.arrangedSubviews.index(where: { $0 === lastFieldView })
        else { return }

        if let arrangedSubviewsToShow = stackView?.arrangedSubviews[firstFieldIndexToShow...lastFieldIndexToShow] {
            UIView.animate(withDuration: 0.25) {
                arrangedSubviewsToShow.forEach { view in
                    view.alpha = section.collapsed ? 0 : 1
                    view.isHidden = section.collapsed
                }
            }
        }
    }

    private func prepareSectionAndAddToStackView(_ section: Section, at sectionIndex: Int) {
        let adjustedSectionIndex = constrain(sectionIndex, min: 0, max: form.sections.count)

        section.collapsedDidChange = { [weak self] section in
            self?.updateCollapsedStateOfSection(section)
        }

        // In order to put the section view in the stack view, we need to know the number of views that will be before this one once each preceding section's views and its fields' views are taken into account
        let actualIndex = numberOfViewsPrecedingSection(at: adjustedSectionIndex)
        let sectionView = viewProvider.viewForSection(section, formView: self)
        stackView?.insertArrangedSubview(sectionView.view, at: actualIndex)
    }

    internal func numberOfViewsPrecedingSection(at sectionIndex: Int) -> Int {
        let adjustedSectionIndex = constrain(sectionIndex, min: 0, max: form.sections.count)
        return form.sections[0..<adjustedSectionIndex].map { 1 + $0.fields.count }.reduce(0, +)
    }

    internal func numberOfViewsPrecedingSection(at sectionIndex: Int, fieldAt fieldIndex: Int) -> Int {
        let adjustedSectionIndex = constrain(sectionIndex, min: 0, max: form.sections.count)
        let section = form.sections[adjustedSectionIndex]
        let adjustedFieldIndex = constrain(fieldIndex, min: 0, max: section.fields.count)

        let precedingSectionsViewCount = numberOfViewsPrecedingSection(at: adjustedSectionIndex)
        let thisSectionPrecedingViewCount = 1 + adjustedFieldIndex // 1 for the section view, fieldIndex is also the number of preceding fields
        return precedingSectionsViewCount + thisSectionPrecedingViewCount
    }

    private func prepareFieldAndAddToStackView(_ field: UntypedField, at fieldIndex: Int, in section: Section) {
        let sectionIndex = form.sections.index(of: section)
        let adjustedSectionIndex = constrain(sectionIndex ?? form.sections.count, min: 0, max: form.sections.count)

        field.untypedValueChanged = { [weak self] value in
            self?.valueChanged?(section.id, field.id, value)
        }

        // In order to put the field view in the stack view, we need to know the number of views that will be before this one once each preceding field and section's views and its fields' views are taken into account
        let actualIndex = numberOfViewsPrecedingSection(at: adjustedSectionIndex, fieldAt: fieldIndex)
        let fieldView = viewProvider.viewForField(field, formView: self)
        stackView?.insertArrangedSubview(fieldView.view, at: actualIndex)
    }
}

func constrain<T: Comparable>(_ x: T, min minimum: T, max maximum: T) -> T {
    return max(minimum, min(maximum, x))
}

public extension FormView {
    enum Error: Swift.Error, CustomStringConvertible {
        case invalidSectionId
        case invalidSectionIndex
        case sectionNotCollapsible
        case sectionAlreadyVisible
        case sectionAlreadyHidden
        case invalidFieldIndex

        public var description: String {
            switch self {
            case .invalidSectionId: return "Invalid section id"
            case .invalidSectionIndex: return "Invalid section index"
            case .sectionNotCollapsible: return "Section isn't collapsible"
            case .sectionAlreadyVisible: return "Section is already visible"
            case .sectionAlreadyHidden: return "Section is already hidden"
            case .invalidFieldIndex: return "Invalid field index"
            }
        }

        public var localizedDescription: String {
            return NSLocalizedString(description, comment: "A localized version of the description")
        }
    }
}
