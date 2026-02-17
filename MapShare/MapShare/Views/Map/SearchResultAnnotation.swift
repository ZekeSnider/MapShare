import SwiftUI
import MapKit

class SearchResultAnnotation: NSObject, MKAnnotation {
    let searchResult: SearchResult

    var coordinate: CLLocationCoordinate2D {
        searchResult.coordinate
    }

    var title: String? {
        searchResult.name
    }

    var subtitle: String? {
        searchResult.address
    }

    init(searchResult: SearchResult) {
        self.searchResult = searchResult
        super.init()
    }
}

class SearchResultAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "searchResult"

    var searchResult: SearchResult? {
        didSet { updateView() }
    }

    private let pinView = UIView()
    private let iconImageView = UIImageView()
    private let glossView = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        pinView.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        pinView.layer.cornerRadius = 14
        pinView.backgroundColor = .white
        pinView.layer.borderWidth = 2.5
        pinView.layer.borderColor = UIColor.systemBlue.cgColor

        // Enhanced shadow for embossed look
        pinView.layer.shadowColor = UIColor.black.cgColor
        pinView.layer.shadowOffset = CGSize(width: 0, height: 2)
        pinView.layer.shadowRadius = 3
        pinView.layer.shadowOpacity = 0.3

        // Gloss highlight on upper half
        glossView.frame = CGRect(x: 0, y: 0, width: 28, height: 14)
        glossView.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        glossView.isUserInteractionEnabled = false
        glossView.layer.cornerRadius = 14
        glossView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        glossView.layer.masksToBounds = true

        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = pinView.bounds.insetBy(dx: 6, dy: 6)

        pinView.addSubview(iconImageView)
        pinView.addSubview(glossView)
        addSubview(pinView)

        frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        centerOffset = CGPoint(x: 0, y: -14)
    }

    private func updateView() {
        guard let result = searchResult else { return }
        iconImageView.image = UIImage(systemName: iconForCategory(result.category))
    }

    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.transform = selected ? CGAffineTransform(scaleX: 1.3, y: 1.3) : .identity
            self.pinView.backgroundColor = selected ? .systemBlue : .white
            self.iconImageView.tintColor = selected ? .white : .systemBlue
            self.glossView.backgroundColor = UIColor.white.withAlphaComponent(selected ? 0.25 : 0.4)
        }
    }

}
