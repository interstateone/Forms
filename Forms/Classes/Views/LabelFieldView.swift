import UIKit

public class LabelFieldView: UIView, IdentifiableView {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
        super.init(frame: .zero)
        
        backgroundColor = .white

        let label = UILabel()
        label.text = name
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    public required init?(coder aDecoder: NSCoder) {
        self.id = ""
        self.name = ""
        super.init(coder: aDecoder)
    }
}
