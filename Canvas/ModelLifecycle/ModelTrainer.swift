//
//  ModelTrainer.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation
import CoreML
#if canImport(CreateML) && !os(iOS)
import CreateML
#endif
import Observation

/// Trains models on collected sensor data
@Observable
class ModelTrainer {
    static let shared = ModelTrainer()
    
    var isTraining: Bool = false
    var trainingProgress: Double = 0.0
    var lastTrainingError: String?
    
    private let dataStore = DataStore.shared
    private let modelManager = ModelManager.shared
    
    // Minimum data points required for training
    let minimumDataPoints = 100
    
    private init() {}
    
    /// Checks if there's enough data to train a model
    func canTrain() -> Bool {
        return dataStore.dataCount >= minimumDataPoints
    }
    
    /// Trains a new model on collected data
    func trainModel() async throws {
        guard !isTraining else { return }
        guard canTrain() else {
            throw TrainingError.insufficientData
        }
        
        await MainActor.run {
            isTraining = true
            trainingProgress = 0.0
            lastTrainingError = nil
        }
        
        let startTime = Date()
        
        do {
            // Get training data
            let trainingData = dataStore.getTrainingData()
            
            await MainActor.run {
                trainingProgress = 0.2
            }
            
#if canImport(CreateML) && !os(iOS)
            // Prepare data for training
            // For this MVP, we'll create a simple regression model
            // that predicts a value based on accelerometer data
            let trainingTable = try prepareTrainingTable(from: trainingData)
            
            await MainActor.run {
                trainingProgress = 0.4
            }
            // Create and train a simple regression model
            // Note: In a production system, you'd use more sophisticated models
            let regressor = try MLRegressor(trainingData: trainingTable, targetColumn: "magnitude")
            
            await MainActor.run {
                trainingProgress = 0.7
            }
            
            // Evaluate the model (simple placeholder accuracy for MVP)
            let accuracy: Double
            if let eval = try? regressor.evaluation(on: trainingTable) {
                let rmse = eval.rootMeanSquaredError
                // maxError might be Duration in newer CreateML versions, convert to Double
                let maxErrorValue: Double
                if let duration = eval.maxError as? Duration {
                    // Convert Duration to seconds as Double
                    let components = duration.components
                    maxErrorValue = Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000.0
                } else if let doubleValue = eval.maxError as? Double {
                    maxErrorValue = doubleValue
                } else {
                    // Try to convert via NSNumber
                    maxErrorValue = Double(truncating: (eval.maxError as? NSNumber) ?? NSNumber(value: 0))
                }
                let maxError = max(maxErrorValue, 1e-9)
                accuracy = max(0, min(1, 1.0 - rmse / maxError))
            } else {
                accuracy = 0.0
            }
            
            await MainActor.run {
                trainingProgress = 0.9
            }
            
            // Save the model
            let modelVersion = modelManager.getNextVersion()
            let tempModelURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("model_v\(modelVersion).mlmodel")
            
            try regressor.write(to: tempModelURL)
            
            // Compile the model
            let compiledURL = try MLModel.compileModel(at: tempModelURL)
            let compiledData = try Data(contentsOf: compiledURL)
            
            let trainingDuration = Date().timeIntervalSince(startTime)
            
            let metadata = ModelMetadata(
                version: modelVersion,
                trainedOn: Date(),
                dataPointCount: trainingData.count,
                modelPath: "", // Will be set by ModelManager
                accuracy: max(0, min(1, accuracy)), // Clamp between 0 and 1
                trainingDuration: trainingDuration
            )
            
            try modelManager.saveModel(compiledData, metadata: metadata)
            
            await MainActor.run {
                trainingProgress = 1.0
                isTraining = false
            }
            return
#else
            throw TrainingError.trainingUnavailable
#endif
            
        } catch {
            await MainActor.run {
                isTraining = false
                lastTrainingError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Prepares training data table from sensor data
    #if canImport(CreateML) && !os(iOS)
    private func prepareTrainingTable(from sensorData: [SensorData]) throws -> MLDataTable {
        var x: [Double] = []
        var y: [Double] = []
        var z: [Double] = []
        var magnitude: [Double] = []

        for data in sensorData {
            guard let accel = data.accelerometer else { continue }
            x.append(accel.x)
            y.append(accel.y)
            z.append(accel.z)
            let mag = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
            magnitude.append(mag)
        }

        guard !magnitude.isEmpty else {
            throw TrainingError.noValidData
        }

        return try MLDataTable(dictionary: [
            "x": x,
            "y": y,
            "z": z,
            "magnitude": magnitude
        ])
    }
    #endif
    
    /// Performs inference using the latest model
    func predict(accelerometerData: AccelerometerData) throws -> Double? {
        guard modelManager.getLatestModel() != nil else {
            return nil
        }
        
        // For MVP, we'll return a simple calculation
        // In a full implementation, we'd load and use the Core ML model
        let magnitude = sqrt(
            accelerometerData.x * accelerometerData.x +
            accelerometerData.y * accelerometerData.y +
            accelerometerData.z * accelerometerData.z
        )
        
        return magnitude
    }
}

enum TrainingError: LocalizedError {
    case insufficientData
    case noValidData
    case trainingFailed
    case trainingUnavailable
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Not enough data points. Need at least \(ModelTrainer.shared.minimumDataPoints) points."
        case .noValidData:
            return "No valid sensor data found for training."
        case .trainingFailed:
            return "Model training failed."
        case .trainingUnavailable:
            return "On-device training isn't available on this platform/build (CreateML not present)."
        }
    }
}

