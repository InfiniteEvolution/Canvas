//
//  CanvasApp.swift
//  Canvas
//
//  Created by sijo using AI on 30/11/25.
//

import DataCollector
import SwiftUI

@main
struct CanvasApp: App {
    @State private var sensorCollector = SensorDataCollector()

    var body: some Scene {
        WindowGroup {
            VibeView(sensorCollector: sensorCollector)
        }
    }
}
