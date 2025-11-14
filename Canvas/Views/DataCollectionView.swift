//
//  DataCollectionView.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import SwiftUI
import Charts

struct DataCollectionView: View {
    @State private var dataStore = DataStore.shared
    @State private var sensorCollector = SensorCollector.shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var recentData: [SensorData] = []
    @State private var selectedTimeRange: TimeRange = .last100
    
    enum TimeRange: String, CaseIterable {
        case last100 = "Last 100"
        case last500 = "Last 500"
        case all = "All"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Data visualization
                    if !recentData.isEmpty {
                        dataVisualizationSection
                    } else {
                        emptyStateView
                    }
                    
                    // Recent readings list
                    recentReadingsSection
                }
                .padding()
            }
            .navigationTitle("Data Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecentData()
            }
            .onChange(of: selectedTimeRange) {
                loadRecentData()
            }
        }
    }
    
    private var dataVisualizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accelerometer Data")
                    .font(.headline)
                Spacer()
                Picker("Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Chart {
                ForEach(recentData.prefix(50).enumerated().map { (index, data) in
                    (index: index, data: data)
                }, id: \.data.id) { item in
                    if let accel = item.data.accelerometer {
                        LineMark(
                            x: .value("Index", item.index),
                            y: .value("X", accel.x),
                            series: .value("Axis", "X")
                        )
                        .foregroundStyle(.red)
                        
                        LineMark(
                            x: .value("Index", item.index),
                            y: .value("Y", accel.y),
                            series: .value("Axis", "Y")
                        )
                        .foregroundStyle(.green)
                        
                        LineMark(
                            x: .value("Index", item.index),
                            y: .value("Z", accel.z),
                            series: .value("Axis", "Z")
                        )
                        .foregroundStyle(.blue)
                    }
                }
            }
            .frame(height: 200)
            .chartLegend {
                HStack {
                    Label("X", systemImage: "circle.fill")
                        .foregroundColor(.red)
                    Label("Y", systemImage: "circle.fill")
                        .foregroundColor(.green)
                    Label("Z", systemImage: "circle.fill")
                        .foregroundColor(.blue)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No data collected yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Start data collection to see visualizations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recentReadingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Readings")
                .font(.headline)
            
            if recentData.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(recentData.prefix(10)) { data in
                    DataRowView(data: data)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func loadRecentData() {
        switch selectedTimeRange {
        case .last100:
            recentData = dataStore.loadRecent(count: 100)
        case .last500:
            recentData = dataStore.loadRecent(count: 500)
        case .all:
            recentData = dataStore.loadAll()
        }
    }
}

struct DataRowView: View {
    let data: SensorData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatDate(data.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let accel = data.accelerometer {
                HStack {
                    Text("Accel:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("x:\(accel.x, specifier: "%.2f") y:\(accel.y, specifier: "%.2f") z:\(accel.z, specifier: "%.2f")")
                        .font(.system(.caption, design: .monospaced))
                }
            }
            
            if let gyro = data.gyroscope {
                HStack {
                    Text("Gyro:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("x:\(gyro.x, specifier: "%.2f") y:\(gyro.y, specifier: "%.2f") z:\(gyro.z, specifier: "%.2f")")
                        .font(.system(.caption, design: .monospaced))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    DataCollectionView()
}

