//
//  VibeView.swift
//  Canvas
//
//  Created by sijo using AI on 30/11/25.
//

import DataCollector
import Observation
import SwiftUI

struct VibeView: View {
    var sensorCollector: SensorDataCollector
    @State private var isQuotePulsing = false

    var body: some View {
        @Bindable var collector = sensorCollector
        let vibe = collector.sensorData.vibe

        ZStack {
            // 1. Full Screen Gradient Background
            vibe.gradient
                .ignoresSafeArea()
                .animation(.smooth, value: vibe)
            
            // 2. Content Overlay
            VStack(spacing: 30) {
                Spacer()

                // Vibe Title
                Text(vibe.title)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Spacer()

                // Footer
                Text("Vibe reflects your activity & time")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            sensorCollector.start()
        }
    }
}

extension Vibe {
    fileprivate var gradient: LinearGradient {
        switch self {
        case .sleep:
            // Night: Deep Indigo to Black
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.0, blue: 0.3), .black],
                startPoint: .top, endPoint: .bottom)
        case .morningRoutine:
            // Morning: Soft Sunrise (Mint to Peach)
            return LinearGradient(
                colors: [.mint, Color(red: 1.0, green: 0.8, blue: 0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .energetic:
            // High Noon/Energy: Bright Red to Orange
            return LinearGradient(
                colors: [.red, .orange],
                startPoint: .bottomLeading, endPoint: .topTrailing)
        case .commute:
            // Transition: Blue to Purple
            return LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading, endPoint: .trailing)
        case .focus:
            // Noon/Day: Clear Sky Blue to Cyan
            return LinearGradient(
                colors: [Color(red: 0.0, green: 0.5, blue: 1.0), .cyan],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .meal:
            // Nourishment: Warm Yellow to Orange
            return LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .top, endPoint: .bottom)
        case .chill:
            // Evening: Sunset (Purple to Pink)
            return LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.0, blue: 0.8), Color(red: 1.0, green: 0.4, blue: 0.7),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .unknown:
            return LinearGradient(
                colors: [.gray, .gray.opacity(0.5)],
                startPoint: .top, endPoint: .bottom)
        }
    }

    fileprivate var shadowColor: Color {
        switch self {
        case .sleep: return .indigo
        case .morningRoutine: return .orange
        case .energetic: return .red
        case .commute: return .purple
        case .focus: return .teal
        case .meal: return .pink
        case .chill: return .cyan
        case .unknown: return .gray
        }
    }
}
