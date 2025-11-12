//
//  SensorData.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation
import CoreMotion

/// Represents a single sensor reading with timestamp and motion data
struct SensorData: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let accelerometer: AccelerometerData?
    let gyroscope: GyroscopeData?
    let location: LocationData?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        accelerometer: AccelerometerData? = nil,
        gyroscope: GyroscopeData? = nil,
        location: LocationData? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.accelerometer = accelerometer
        self.gyroscope = gyroscope
        self.location = location
    }
}

/// Accelerometer data (x, y, z in m/s²)
struct AccelerometerData: Codable {
    let x: Double
    let y: Double
    let z: Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(from motion: CMAccelerometerData) {
        self.x = motion.acceleration.x
        self.y = motion.acceleration.y
        self.z = motion.acceleration.z
    }
}

/// Gyroscope data (x, y, z in rad/s)
struct GyroscopeData: Codable {
    let x: Double
    let y: Double
    let z: Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(from motion: CMGyroData) {
        self.x = motion.rotationRate.x
        self.y = motion.rotationRate.y
        self.z = motion.rotationRate.z
    }
}

/// Location data (latitude, longitude, altitude)
struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let accuracy: Double
    
    init(latitude: Double, longitude: Double, altitude: Double, accuracy: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
    }
}

