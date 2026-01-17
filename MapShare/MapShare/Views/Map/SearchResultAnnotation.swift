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
        pinView.layer.shadowColor = UIColor.black.cgColor
        pinView.layer.shadowOffset = CGSize(width: 0, height: 1)
        pinView.layer.shadowRadius = 2
        pinView.layer.shadowOpacity = 0.2

        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = pinView.bounds.insetBy(dx: 6, dy: 6)

        pinView.addSubview(iconImageView)
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
        }
    }

    private func iconForCategory(_ category: String?) -> String {
        guard let category = category else { return "mappin" }

        switch category {
        case "MKPOICategoryRestaurant", "MKPOICategoryCafe":
            return "fork.knife"
        case "MKPOICategoryStore", "MKPOICategoryShoppingCenter":
            return "bag"
        case "MKPOICategoryGasStation":
            return "car"
        case "MKPOICategoryHotel":
            return "bed.double"
        case "MKPOICategoryHospital", "MKPOICategoryPharmacy":
            return "cross.case"
        case "MKPOICategorySchool", "MKPOICategoryUniversity":
            return "graduationcap"
        case "MKPOICategoryPark":
            return "leaf"
        case "MKPOICategoryMuseum":
            return "building.columns"
        case "MKPOICategoryTheater":
            return "theatermasks"
        case "MKPOICategoryNightlife", "MKPOICategoryBar":
            return "wineglass"
        case "MKPOICategoryGym", "MKPOICategoryFitnessCenter":
            return "dumbbell"
        case "MKPOICategoryAirport":
            return "airplane"
        case "MKPOICategoryBank", "MKPOICategoryATM":
            return "banknote"
        default:
            return "mappin"
        }
    }
}
