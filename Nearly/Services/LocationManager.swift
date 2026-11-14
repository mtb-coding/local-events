import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationManager: NSObject {
    static let defaultCoordinate = MockEventService.nycCenter
    /// Discover reloads on the first fix, or after a move of at least this distance.
    static let significantMoveMeters: CLLocationDistance = 300

    private let manager = CLLocationManager()
    private var fixTimeoutTask: Task<Void, Never>?

    var authorizationStatus: CLAuthorizationStatus
    var currentLocation: CLLocation?
    var lastError: Error?
    /// Authorized, still no fix, after a 10s wait or a terminal Core Location error.
    var locationFixFailed = false

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
        startFixTimeoutIfNeeded()
        manager.startUpdatingLocation()
    }

    /// Clears a failed locate attempt and asks Core Location for a new fix.
    func requestFreshFix() {
        guard isAuthorized else { return }
        lastError = nil
        locationFixFailed = false
        startFixTimeoutIfNeeded()
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        cancelFixTimeout()
    }

    func refreshAuthorization() {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            startUpdatingIfAuthorized()
        } else {
            stopUpdating()
        }
    }

    private func startFixTimeoutIfNeeded() {
        guard currentLocation == nil else { return }
        cancelFixTimeout()
        fixTimeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            guard let self, self.currentLocation == nil, self.isAuthorized else { return }
            self.locationFixFailed = true
            self.manager.stopUpdatingLocation()
        }
    }

    private func cancelFixTimeout() {
        fixTimeoutTask?.cancel()
        fixTimeoutTask = nil
    }

    private func acceptFix(_ location: CLLocation) {
        currentLocation = location
        lastError = nil
        locationFixFailed = false
        cancelFixTimeout()
        manager.stopUpdatingLocation()
    }

    private func handleFailure(_ error: Error) {
        // locationUnknown is often transient while a fix is still coming in.
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        lastError = error
        guard currentLocation == nil, isAuthorized else { return }
        locationFixFailed = true
        cancelFixTimeout()
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if isAuthorized {
                startUpdatingIfAuthorized()
            } else {
                stopUpdating()
                locationFixFailed = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        Task { @MainActor in
            acceptFix(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            handleFailure(error)
        }
    }
}
