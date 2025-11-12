//
//  SensorCollector.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation
import CoreMotion
import CoreLocation
import Combine

/// Collects sensor data from device sensors
class SensorCollector: NSObject, ObservableObject {
    static let shared = SensorCollector()
    
    @Published var isCollecting: Bool = false
    @Published var lastReading: SensorData?
    
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let dataStore = DataStore.shared
    
    private var updateTimer: Timer?
    private var updateInterval: TimeInterval = 1.0 // Collect data every second
    
    private var lastAccelerometerData: CMAccelerometerData?
    private var lastGyroData: CMGyroData?
    private var lastLocation: CLLocation?
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    /// Starts collecting sensor data
    func startCollection() {
        guard !isCollecting else { return }
        
        // Request location permissions
        locationManager.requestWhenInUseAuthorization()
        
        // Start motion updates
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = updateInterval
            motionManager.startAccelerometerUpdates()
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = updateInterval
            motionManager.startGyroUpdates()
        }
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Start timer to collect data periodically
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.collectCurrentReading()
        }
        
        isCollecting = true
        dataStore.isCollecting = true
    }
    
    /// Stops collecting sensor data
    func stopCollection() {
        guard isCollecting else { return }
        
        updateTimer?.invalidate()
        updateTimer = nil
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        locationManager.stopUpdatingLocation()
        
        isCollecting = false
        dataStore.isCollecting = false
    }
    
    /// Collects a single reading from all available sensors
    private func collectCurrentReading() {
        let accelerometer: AccelerometerData?
        if let accelData = motionManager.accelerometerData {
            accelerometer = AccelerometerData(from: accelData)
            lastAccelerometerData = accelData
        } else {
            accelerometer = nil
        }
        
        let gyroscope: GyroscopeData?
        if let gyroData = motionManager.gyroData {
            gyroscope = GyroscopeData(from: gyroData)
            lastGyroData = gyroData
        } else {
            gyroscope = nil
        }
        
        let location: LocationData?
        if let loc = lastLocation {
            location = LocationData(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                altitude: loc.altitude,
                accuracy: loc.horizontalAccuracy
            )
        } else {
            location = nil
        }
        
        let sensorData = SensorData(
            timestamp: Date(),
            accelerometer: accelerometer,
            gyroscope: gyroscope,
            location: location
        )
        
        lastReading = sensorData
        
        // Save to data store
        do {
            try dataStore.save(sensorData)
        } catch {
            print("Error saving sensor data: \(error)")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension SensorCollector: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if isCollecting {
                manager.startUpdatingLocation()
            }
        default:
            break
        }
    }
}

