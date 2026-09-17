import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationManager: NSObject {
    static let defaultCoordinate = MockEventService.nycCenter

    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus
    var currentLocation: CLLocation?
    var lastError: Error?

    var hasDeterminedAuthorization: Bool {
        switch authorizationStatus {
        case .notDetermined:
            return false
        default:
            return true
        }
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    var coordinateForSearch: CLLocationCoordinate2D {
        if isAuthorized, let currentLocation {
            return currentLocation.coordinate
        }
        return Self.defaultCoordinate
    }

    var usingDefaultLocation: Bool {
        !isAuthorized || currentLocation == nil
    }

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingIfAuthorized() {
        guard isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    func refreshAuthorization() {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            startUpdatingIfAuthorized()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if isAuthorized {
                startUpdatingIfAuthorized()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error
        }
    }
}
