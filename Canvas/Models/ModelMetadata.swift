//
//  ModelMetadata.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation

/// Metadata about a trained model
struct ModelMetadata: Codable, Identifiable {
    let id: UUID
    let version: Int
    let createdAt: Date
    let trainedOn: Date
    let dataPointCount: Int
    let modelPath: String
    let accuracy: Double?
    let trainingDuration: TimeInterval
    
    init(
        id: UUID = UUID(),
        version: Int,
        createdAt: Date = Date(),
        trainedOn: Date,
        dataPointCount: Int,
        modelPath: String,
        accuracy: Double? = nil,
        trainingDuration: TimeInterval
    ) {
        self.id = id
        self.version = version
        self.createdAt = createdAt
        self.trainedOn = trainedOn
        self.dataPointCount = dataPointCount
        self.modelPath = modelPath
        self.accuracy = accuracy
        self.trainingDuration = trainingDuration
    }
}

