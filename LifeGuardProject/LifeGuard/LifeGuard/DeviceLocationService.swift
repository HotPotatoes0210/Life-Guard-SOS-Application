import Combine
import CoreLocation

class DeviceLocationService:NSObject, CLLocationManagerDelegate, ObservableObject{
    var coordinatesPublisher = PassthroughSubject<CLLocationCoordinate2D, Error>()
    
    var deniedLocationAccessPublisher = PassthroughSubject<Void, Never>()
    
    private override init(){
        super.init()
    }
    
    static let shared = DeviceLocationService()
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        return manager
    }()
    
    func requestLocationUpdate(){
        switch locationManager.authorizationStatus{
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            deniedLocationAccessPublisher.send()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus{
            
        case .authorizedWhenInUse,.authorizedAlways:
            locationManager.startUpdatingLocation()
            
        default:
            manager.stopUpdatingLocation()
            deniedLocationAccessPublisher.send()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        guard let location = locations.last else {return}
        coordinatesPublisher.send(location.coordinate)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error : Error){
        coordinatesPublisher.send(completion: .failure(error))
    }
}

func getAddressFromCoordinates(latitude: CLLocationDegrees, longtitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
    let geocoder = CLGeocoder()
    let location = CLLocation(latitude: latitude, longitude: longtitude)
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
        if let error = error {
            print("Error in reverse geocoding: \(error.localizedDescription)")
            completion(nil)
            return
        }
        guard let placemark = placemarks?.first else {
            print("No placemark found")
            completion(nil)
            return
        }
        
        let address = """
        \(placemark.name ?? ""), \(placemark.locality ?? ""), \(placemark.administrativeArea ?? "")
        """
        completion(address)
    }
}

func performGeocoding(lat:Double, lon: Double) {
    let latitude:CLLocationDegrees = lat
    let longtitude:CLLocationDegrees = lon
    getAddressFromCoordinates(latitude: latitude, longtitude: longtitude) { address in
        if let address = address {
            print("Address: \(address)")
        } else {
            print("Unable to retrieve address.")
        }
    }
}

