//
//  Location.swift
//  ParkenDD
//
//  Created by Kilian Költzsch on 12/01/2017.
//  Copyright © 2017 Kilian Koeltzsch. All rights reserved.
//

import Foundation
import CoreLocation

class Location: NSObject {
    
    enum AuthorizationStatus {
        case authorized
        case pending
        case denied
        
        fileprivate init(status: CLAuthorizationStatus) {
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                self = .authorized
            case .denied, .restricted:
                self = .denied
            case .notDetermined:
                self = .pending
            }
        }
    }
    
    private override init() {
        super.init()
        Location.manager.delegate = self
    }

    static let shared = Location()
    static let manager = CLLocationManager()
    static var authState: AuthorizationStatus {
        return AuthorizationStatus(status: CLLocationManager.authorizationStatus())
    }

    var lastLocation: CLLocation?

    // This is really weird o.O
    var didMove = [(CLLocation) -> Void]()
    func onMove(_ block: @escaping (CLLocation) -> Void) {
        didMove.append(block)
    }
}

extension Location: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        guard let lastLocation = lastLocation else { self.lastLocation = currentLocation; return }

        let distance = currentLocation.distance(from: lastLocation)
        if distance > 100 {
            self.lastLocation = currentLocation
            didMove.forEach { $0(currentLocation) }
        }
    }
}
