# Canvas | On-Device Adaptive AI Framework

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Canvas** is an iOS framework that enables on-device machine learning with complete privacy. Collect sensor data, train models locally, and perform inference—all without sending data to the cloud.

## Features

- 🔒 **Privacy-First**: All data encrypted and stored on-device
- 📱 **Sensor Collection**: Automatic collection of accelerometer, gyroscope, and location data
- 🤖 **Model Training**: On-device Core ML model training (macOS) or inference (iOS)
- 📊 **Real-Time Visualization**: Built-in dashboard and data visualization
- 🔐 **Secure Storage**: AES-GCM encryption with Keychain integration
- 📈 **Model Versioning**: Track and manage multiple model versions

## Quick Start

### Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/InfiniteEvolution/Canvas.git
cd Canvas
```

2. Open the project in Xcode:
```bash
open Canvas.xcodeproj
```

3. Build and run on your device or simulator.

### Basic Usage

#### Starting Data Collection

```swift
import Canvas

// Start collecting sensor data
SensorCollector.shared.startCollection()

// Check collection status
if SensorCollector.shared.isCollecting {
    print("Collecting sensor data...")
}
```

#### Accessing Collected Data

```swift
let dataStore = DataStore.shared

// Get total data count
print("Total data points: \(dataStore.dataCount)")

// Load recent data
let recentData = dataStore.loadRecent(count: 100)

// Get statistics
let stats = dataStore.getStatistics()
```

#### Training a Model

```swift
let trainer = ModelTrainer.shared

// Check if enough data is available
if trainer.canTrain() {
    // Train model asynchronously
    Task {
        do {
            try await trainer.trainModel()
            print("Model trained successfully!")
        } catch {
            print("Training error: \(error)")
        }
    }
}
```

#### Using the Dashboard UI

```swift
import SwiftUI

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
    }
}
```

## Architecture

### Project Structure

```
Canvas/
├── CanvasApp.swift          # App entry point
├── ContentView.swift        # Root view
├── DataPipeline/
│   ├── SensorCollector.swift    # Sensor data collection
│   └── DataStore.swift          # Encrypted data storage
├── ModelLifecycle/
│   ├── ModelTrainer.swift       # Model training pipeline
│   └── ModelManager.swift       # Model versioning & management
├── Security/
│   └── EncryptionManager.swift  # AES-GCM encryption
├── Models/
│   ├── SensorData.swift         # Sensor data models
│   └── ModelMetadata.swift      # Model metadata
└── Views/
    ├── DashboardView.swift      # Main dashboard
    └── DataCollectionView.swift # Data visualization
```

## Core Components

### Data Pipeline

#### SensorCollector

Collects data from device sensors using CoreMotion and CoreLocation.

**Key Features:**
- Automatic sensor availability detection
- Configurable update intervals (default: 1 second)
- Location permission handling
- Real-time data publishing via `@Published` properties

**Example:**
```swift
let collector = SensorCollector.shared

// Observe collection status
collector.$isCollecting
    .sink { isCollecting in
        print("Collection status: \(isCollecting)")
    }

// Access last reading
if let reading = collector.lastReading {
    print("Last accelerometer: \(reading.accelerometer)")
}
```

#### DataStore

Manages encrypted storage and retrieval of sensor data.

**Key Features:**
- AES-GCM encryption for all stored data
- Automatic data directory creation
- Efficient data loading (recent/all)
- Statistics and metadata tracking

**API:**
```swift
// Save sensor data
try dataStore.save(sensorData)

// Load all data
let allData = dataStore.loadAll()

// Load recent data
let recent = dataStore.loadRecent(count: 100)

// Get statistics
let stats = dataStore.getStatistics()
```

### Model Lifecycle

#### ModelTrainer

Handles on-device model training using CreateML (macOS) or provides inference (iOS).

**Key Features:**
- Automatic training when data threshold is met (100+ points)
- Progress tracking during training
- Model evaluation and accuracy calculation
- Platform-aware (CreateML on macOS, inference-only on iOS)

**Training Process:**
1. Validates minimum data requirements
2. Prepares training data table
3. Trains MLRegressor model
4. Evaluates model accuracy
5. Saves encrypted model with metadata

**Example:**
```swift
let trainer = ModelTrainer.shared

// Check training availability
if trainer.canTrain() {
    Task {
        // Monitor training progress
        for await progress in trainer.$trainingProgress.values {
            print("Training: \(Int(progress * 100))%")
        }
        
        // Start training
        try await trainer.trainModel()
    }
}
```

#### ModelManager

Manages model versioning, storage, and retrieval.

**Key Features:**
- Automatic version numbering
- Encrypted model storage
- Model metadata tracking
- Latest model retrieval

**API:**
```swift
let manager = ModelManager.shared

// Get current model
if let model = manager.currentModel {
    print("Model version: \(model.version)")
    print("Accuracy: \(model.accuracy ?? 0)")
}

// Load specific model version
if let modelData = manager.loadModel(version: 1) {
    // Use model data
}

// Get next version number
let nextVersion = manager.getNextVersion()
```

### Security

#### EncryptionManager

Provides AES-GCM encryption with Keychain-based key management.

**Key Features:**
- Automatic key generation and storage in Keychain
- Device-only key access (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- Support for both Data and Codable types
- Secure nonce and tag handling

**Usage:**
```swift
let encryption = EncryptionManager.shared

// Encrypt data
let plaintext = "sensitive data".data(using: .utf8)!
let encrypted = try encryption.encrypt(plaintext)

// Decrypt data
let decrypted = try encryption.decrypt(encrypted)

// Encrypt Codable objects
struct MyData: Codable {
    let value: String
}
let myData = MyData(value: "test")
let encrypted = try encryption.encrypt(myData)
let decrypted: MyData = try encryption.decrypt(encrypted, as: MyData.self)
```

## Data Models

### SensorData

Represents a single sensor reading with timestamp and optional sensor values.

```swift
struct SensorData: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let accelerometer: AccelerometerData?
    let gyroscope: GyroscopeData?
    let location: LocationData?
}
```

### ModelMetadata

Tracks model information including version, training details, and performance metrics.

```swift
struct ModelMetadata: Codable, Identifiable {
    let id: UUID
    let version: Int
    let createdAt: Date
    let trainedOn: Date
    let dataPointCount: Int
    let modelPath: String
    let accuracy: Double?
    let trainingDuration: TimeInterval
}
```

## UI Components

### DashboardView

Main dashboard showing:
- Data collection status and statistics
- Model training status and progress
- Recent sensor readings
- Action buttons for collection and training

### DataCollectionView

Data visualization and exploration:
- Real-time accelerometer charts (X, Y, Z axes)
- Recent readings list
- Time range filtering (last 100, 500, or all)
- Interactive data exploration

## Permissions

Canvas requires the following permissions:

- **Location Services**: `NSLocationWhenInUseUsageDescription`
  - Used for collecting GPS location data
  - Required for complete sensor data collection

- **Motion & Fitness**: `NSMotionUsageDescription`
  - Used for accelerometer and gyroscope data
  - Required for motion-based model training

Add these to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Canvas needs location access to collect sensor data for on-device AI training.</string>

<key>NSMotionUsageDescription</key>
<string>Canvas needs motion sensor access to collect accelerometer and gyroscope data.</string>
```

## Platform Considerations

### iOS Devices
- ✅ Full sensor data collection
- ✅ Encrypted data storage
- ✅ Model inference
- ❌ Model training (CreateML not available)
- ⚠️ Training will show "unavailable" message

### macOS
- ✅ Full sensor data collection (if available)
- ✅ Encrypted data storage
- ✅ Model training with CreateML
- ✅ Model inference
- ✅ Complete framework functionality

### iOS Simulator
- ✅ Full sensor data collection (simulated)
- ✅ Encrypted data storage
- ✅ Model inference
- ❌ Model training (CreateML not available)

## Best Practices

1. **Data Collection**
   - Start collection only when needed to preserve battery
   - Monitor data count to ensure sufficient data for training
   - Review collected data periodically for quality

2. **Model Training**
   - Ensure at least 100 data points before training
   - Train during device idle time to avoid performance impact
   - Review model accuracy before deploying

3. **Security**
   - Never export encryption keys
   - Keep models encrypted at rest
   - Use Keychain for all sensitive data

4. **Performance**
   - Use appropriate data collection intervals
   - Limit historical data loading to recent subsets
   - Monitor memory usage with large datasets

## Troubleshooting

### Model Training Not Available

**Issue**: Training shows "unavailable" message on iOS devices.

**Solution**: Model training requires macOS. On iOS, use the framework for data collection and inference only. For training, transfer data to macOS or use a cloud-based training service.

### Location Permission Denied

**Issue**: Location data not being collected.

**Solution**: 
1. Check `Info.plist` has location usage description
2. Request permission: `locationManager.requestWhenInUseAuthorization()`
3. Check Settings > Privacy > Location Services

### Encryption Errors

**Issue**: Keychain access errors or encryption failures.

**Solution**:
1. Ensure app has Keychain access entitlement
2. Check device is not locked when accessing keys
3. Verify Keychain service identifier is unique

### Insufficient Data for Training

**Issue**: Training fails with "insufficient data" error.

**Solution**:
- Collect at least 100 data points before training
- Check `dataStore.dataCount` to verify data availability
- Ensure sensor collection is active and working

## API Reference

### DataStore

```swift
class DataStore {
    static let shared: DataStore
    
    var dataCount: Int { get }
    var isCollecting: Bool { get set }
    
    func save(_ sensorData: SensorData) throws
    func loadAll() -> [SensorData]
    func loadRecent(count: Int) -> [SensorData]
    func getTrainingData(limit: Int?) -> [SensorData]
    func clearAll() throws
    func getStatistics() -> DataStatistics
}
```

### SensorCollector

```swift
class SensorCollector: NSObject, ObservableObject {
    static let shared: SensorCollector
    
    @Published var isCollecting: Bool
    @Published var lastReading: SensorData?
    
    func startCollection()
    func stopCollection()
}
```

### ModelTrainer

```swift
@Observable
class ModelTrainer {
    static let shared: ModelTrainer
    
    var isTraining: Bool { get }
    var trainingProgress: Double { get }
    var lastTrainingError: String? { get }
    let minimumDataPoints: Int
    
    func canTrain() -> Bool
    func trainModel() async throws
    func predict(accelerometerData: AccelerometerData) throws -> Double?
}
```

### ModelManager

```swift
@Observable
class ModelManager {
    static let shared: ModelManager
    
    var currentModel: ModelMetadata? { get }
    var allModels: [ModelMetadata] { get }
    
    func saveModel(_ modelData: Data, metadata: ModelMetadata) throws
    func getNextVersion() -> Int
    func loadModel(version: Int) -> Data?
    func getLatestModel() -> Data?
    func deleteModel(version: Int) throws
}
```

### EncryptionManager

```swift
class EncryptionManager {
    static let shared: EncryptionManager
    
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ encryptedData: Data) throws -> Data
    func encrypt<T: Codable>(_ object: T) throws -> Data
    func decrypt<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T
}
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and code of conduct before submitting pull requests.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Uses [Core ML](https://developer.apple.com/machine-learning/core-ml/) for on-device machine learning
- Encryption powered by [CryptoKit](https://developer.apple.com/documentation/cryptokit)

## Support

For issues, questions, or contributions:
- Open an issue on [GitHub](https://github.com/InfiniteEvolution/Canvas/issues)
- Check the [documentation](https://github.com/InfiniteEvolution/Canvas/wiki)
- Read the [White Paper](WHITEPAPER.md) for architectural details

---

**Canvas** - Evolving Intelligence. Everywhere. Privately.

