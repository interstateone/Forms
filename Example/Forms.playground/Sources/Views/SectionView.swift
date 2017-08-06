import UIKit

open class SectionView: UIView, IdentifiableView {
    public let id: String

    public var title: String {
        didSet {
            updateTitle(title)
        }
    }

    private var collapseToggled: (() -> Void)?
    public func toggleCollapsed() {
        collapseToggled?()
    }

    public let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = .darkGray
        return label
    }()
    public let toggleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Toggle", for: .normal)
        return button
    }()

    required public init(id: String, title: String = "", collapseToggled: (() -> Void)? = nil) {
        self.id = id
        self.title = title
        self.collapseToggled = collapseToggled
        super.init(frame: .zero)

        backgroundColor = .lightGray

        toggleButton.addTarget(self, action: #selector(SectionView.toggleCollapsed), for: .touchUpInside)
        addSubview(toggleButton)
        toggleButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        toggleButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        toggleButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        addSubview(label)
        label.leadingAnchor.constraint(equalTo: toggleButton.trailingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        label.text = title
    }

    required public init?(coder aDecoder: NSCoder) {
        self.id = ""
        self.title = ""
        fatalError("init(coder:) has not been implemented")
    }

    open func updateTitle(_ title: String) {
        label.text = title
    }
}
