//
//  DataStore.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation
import Observation

/// Manages storage and retrieval of sensor data with encryption
@Observable
class DataStore {
    static let shared = DataStore()
    
    var dataCount: Int = 0
    var isCollecting: Bool = false
    
    private let encryptionManager = EncryptionManager.shared
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var dataDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("CanvasData", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    private var dataFile: URL {
        dataDirectory.appendingPathComponent("sensor_data.encrypted")
    }
    
    private init() {
        loadDataCount()
    }
    
    /// Loads the count of stored data points
    private func loadDataCount() {
        if let data = try? Data(contentsOf: dataFile),
           let decrypted = try? encryptionManager.decrypt(data),
           let sensorDataArray = try? JSONDecoder().decode([SensorData].self, from: decrypted) {
            dataCount = sensorDataArray.count
        }
    }
    
    /// Saves sensor data with encryption
    func save(_ sensorData: SensorData) throws {
        var allData = loadAll()
        allData.append(sensorData)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(allData)
        let encrypted = try encryptionManager.encrypt(data)
        
        try encrypted.write(to: dataFile)
        dataCount = allData.count
    }
    
    /// Loads all sensor data
    func loadAll() -> [SensorData] {
        guard fileManager.fileExists(atPath: dataFile.path),
              let encrypted = try? Data(contentsOf: dataFile),
              let decrypted = try? encryptionManager.decrypt(encrypted),
              let sensorData = try? JSONDecoder().decode([SensorData].self, from: decrypted) else {
            return []
        }
        return sensorData
    }
    
    /// Loads recent sensor data (last N items)
    func loadRecent(count: Int = 100) -> [SensorData] {
        let allData = loadAll()
        return Array(allData.suffix(count))
    }
    
    /// Gets data for training (all data or recent subset)
    func getTrainingData(limit: Int? = nil) -> [SensorData] {
        let allData = loadAll()
        if let limit = limit {
            return Array(allData.suffix(limit))
        }
        return allData
    }
    
    /// Clears all stored data
    func clearAll() throws {
        if fileManager.fileExists(atPath: dataFile.path) {
            try fileManager.removeItem(at: dataFile)
        }
        dataCount = 0
    }
    
    /// Gets statistics about stored data
    func getStatistics() -> DataStatistics {
        let allData = loadAll()
        return DataStatistics(
            totalCount: allData.count,
            oldestTimestamp: allData.first?.timestamp,
            newestTimestamp: allData.last?.timestamp
        )
    }
}

struct DataStatistics {
    let totalCount: Int
    let oldestTimestamp: Date?
    let newestTimestamp: Date?
}

