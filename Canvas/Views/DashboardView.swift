//
//  DashboardView.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var sensorCollector = SensorCollector.shared
    @State private var dataStore = DataStore.shared
    @State private var modelTrainer = ModelTrainer.shared
    @State private var modelManager = ModelManager.shared
    
    @State private var showingDataCollection = false
    @State private var showingTrainingAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Data Collection Status
                    dataCollectionCard
                    
                    // Model Status
                    modelStatusCard
                    
                    // Statistics
                    statisticsCard
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Canvas")
            .sheet(isPresented: $showingDataCollection) {
                DataCollectionView()
            }
            .alert("Training Error", isPresented: $showingTrainingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = modelTrainer.lastTrainingError {
                    Text(error)
                } else {
                    Text("Not enough data points. Need at least 100 data points to train a model.")
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On-Device Adaptive AI")
                .font(.title2)
                .fontWeight(.bold)
            Text("Private intelligence that learns and evolves on your device")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dataCollectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: sensorCollector.isCollecting ? "waveform.path" : "waveform.path.badge.minus")
                    .foregroundColor(sensorCollector.isCollecting ? .green : .gray)
                Text("Data Collection")
                    .font(.headline)
                Spacer()
                if sensorCollector.isCollecting {
                    Text("Active")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            
            Text("\(dataStore.dataCount) data points collected")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let lastReading = sensorCollector.lastReading {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last reading:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let accel = lastReading.accelerometer {
                        Text("Accel: x:\(accel.x, specifier: "%.2f") y:\(accel.y, specifier: "%.2f") z:\(accel.z, specifier: "%.2f")")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var modelStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                Text("Model Status")
                    .font(.headline)
                Spacer()
            }
            
            if let currentModel = modelManager.currentModel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version \(currentModel.version)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let accuracy = currentModel.accuracy {
                        HStack {
                            Text("Accuracy:")
                            Spacer()
                            Text("\(accuracy * 100, specifier: "%.1f")%")
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                    }
                    
                    Text("Trained on \(currentModel.dataPointCount) data points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Training time: \(formatDuration(currentModel.trainingDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No model trained yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if modelTrainer.isTraining {
                ProgressView(value: modelTrainer.trainingProgress)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.purple)
                Text("Statistics")
                    .font(.headline)
                Spacer()
            }
            
            let stats = dataStore.getStatistics()
            
            VStack(alignment: .leading, spacing: 6) {
                StatRow(label: "Total Data Points", value: "\(stats.totalCount)")
                
                if let oldest = stats.oldestTimestamp {
                    StatRow(label: "Oldest Data", value: formatDate(oldest))
                }
                
                if let newest = stats.newestTimestamp {
                    StatRow(label: "Newest Data", value: formatDate(newest))
                }
                
                StatRow(label: "Models Trained", value: "\(modelManager.allModels.count)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                if sensorCollector.isCollecting {
                    sensorCollector.stopCollection()
                } else {
                    sensorCollector.startCollection()
                }
            }) {
                HStack {
                    Image(systemName: sensorCollector.isCollecting ? "stop.circle.fill" : "play.circle.fill")
                    Text(sensorCollector.isCollecting ? "Stop Collection" : "Start Collection")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(sensorCollector.isCollecting ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                if modelTrainer.canTrain() {
                    Task {
                        do {
                            try await modelTrainer.trainModel()
                        } catch {
                            showingTrainingAlert = true
                        }
                    }
                } else {
                    showingTrainingAlert = true
                }
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Train Model")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(modelTrainer.canTrain() ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!modelTrainer.canTrain() || modelTrainer.isTraining)
            
            Button(action: {
                showingDataCollection = true
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("View Data Collection")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

#Preview {
    DashboardView()
}

