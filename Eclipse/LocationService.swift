//
//  LocationService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/18/25.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    
    private let manager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func updateLocation() {
        requestPermission() 
        manager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
                self.locationError = "Location access denied. Please enable it in Settings to use Eclipse Direct."
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            // Stop updating to save battery once we have a fix, unless continuous tracking is needed.
            // For "Where is the nearest...", a single fix is usually enough, but we'll let it run briefly or stop manually.
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
            print("❌ Location Error: \(error.localizedDescription)")
        }
    }
    func getCurrentLocation() async -> CLLocation? {
        if let location = currentLocation {
            return location
        }
        
        updateLocation()
        
        // Wait for up to 5 seconds for a location fix
        for _ in 0..<50 {
            if let location = currentLocation {
                return location
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        return currentLocation
    }
}
