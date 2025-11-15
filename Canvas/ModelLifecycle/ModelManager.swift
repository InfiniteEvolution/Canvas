//
//  ModelManager.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation
import CoreML
import Observation
import Crypto

/// Manages model lifecycle: storage, versioning, and retrieval
@Observable
class ModelManager {
    static let shared = ModelManager()
    
    var currentModel: ModelMetadata?
    var allModels: [ModelMetadata] = []
    
    private let fileManager = FileManager.default
    private let encryptionManager = CryptoManager.shared
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var modelsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("CanvasModels", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    private var metadataFile: URL {
        modelsDirectory.appendingPathComponent("metadata.json")
    }
    
    private init() {
        loadModels()
    }
    
    /// Loads all model metadata
    private func loadModels() {
        guard fileManager.fileExists(atPath: metadataFile.path),
              let data = try? Data(contentsOf: metadataFile),
              let metadata = try? JSONDecoder().decode([ModelMetadata].self, from: data) else {
            allModels = []
            currentModel = nil
            return
        }
        
        allModels = metadata.sorted { $0.version > $1.version }
        currentModel = allModels.first
    }
    
    /// Saves model metadata
    private func saveMetadata() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(allModels)
        try data.write(to: metadataFile)
    }
    
    /// Saves a trained model with metadata
    func saveModel(_ modelData: Data, metadata: ModelMetadata) throws {
        // Save model file (encrypted)
        let modelFileName = "model_v\(metadata.version).mlmodelc"
        let modelFile = modelsDirectory.appendingPathComponent(modelFileName)
        
        // For Core ML, we save the compiled model directory
        // In a real implementation, we'd handle .mlmodelc directories
        // For now, we'll save the metadata and note the path
        let encryptedModel = try encryptionManager.encrypt(modelData)
        try encryptedModel.write(to: modelFile)
        
        // Update metadata with actual file path
        let metadataWithPath = ModelMetadata(
            id: metadata.id,
            version: metadata.version,
            createdAt: metadata.createdAt,
            trainedOn: metadata.trainedOn,
            dataPointCount: metadata.dataPointCount,
            modelPath: modelFile.path,
            accuracy: metadata.accuracy,
            trainingDuration: metadata.trainingDuration
        )
        
        allModels.append(metadataWithPath)
        allModels.sort { $0.version > $1.version }
        currentModel = allModels.first
        
        try saveMetadata()
    }
    
    /// Gets the next version number
    func getNextVersion() -> Int {
        return (allModels.map { $0.version }.max() ?? 0) + 1
    }
    
    /// Loads a model by version
    func loadModel(version: Int) -> Data? {
        guard let metadata = allModels.first(where: { $0.version == version }),
              fileManager.fileExists(atPath: metadata.modelPath),
              let encrypted = try? Data(contentsOf: URL(fileURLWithPath: metadata.modelPath)),
              let decrypted = try? encryptionManager.decrypt(encrypted) else {
            return nil
        }
        return decrypted
    }
    
    /// Gets the latest model
    func getLatestModel() -> Data? {
        guard let latest = currentModel else { return nil }
        return loadModel(version: latest.version)
    }
    
    /// Deletes a model
    func deleteModel(version: Int) throws {
        guard let metadata = allModels.first(where: { $0.version == version }) else {
            return
        }
        
        if fileManager.fileExists(atPath: metadata.modelPath) {
            try fileManager.removeItem(atPath: metadata.modelPath)
        }
        
        allModels.removeAll { $0.version == version }
        if currentModel?.version == version {
            currentModel = allModels.first
        }
        
        try saveMetadata()
    }
}

