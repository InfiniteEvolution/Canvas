//
//  EncryptionManager.swift
//  Canvas
//
//  Created by sijo on 12/11/25.
//

import Foundation
import CryptoKit
import Security

/// Manages encryption and decryption of data using AES-GCM
class EncryptionManager {
    static let shared = EncryptionManager()
    
    private let keychainService = "com.canvas.encryption"
    private let keychainKey = "encryptionKey"
    
    private init() {}
    
    /// Gets or creates the encryption key from Keychain
    private func getEncryptionKey() throws -> SymmetricKey {
        // Try to retrieve existing key from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data {
            let key = SymmetricKey(data: data)
            return key
        }
        
        // Create new key if not found
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess || addStatus == errSecDuplicateItem else {
            throw EncryptionError.keychainError
        }
        
        return newKey
    }
    
    /// Encrypts data using AES-GCM
    func encrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // Combine nonce, ciphertext, and tag
        var encryptedData = sealedBox.nonce.withUnsafeBytes { Data($0) }
        encryptedData.append(sealedBox.ciphertext)
        encryptedData.append(sealedBox.tag)
        
        return encryptedData
    }
    
    /// Decrypts data using AES-GCM
    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getEncryptionKey()
        
        // Extract nonce (first 12 bytes), tag (last 16 bytes), and ciphertext (middle)
        guard encryptedData.count >= 28 else {
            throw EncryptionError.invalidData
        }
        
        let nonceData = encryptedData.prefix(12)
        let tagData = encryptedData.suffix(16)
        let ciphertextData = encryptedData.dropFirst(12).dropLast(16)
        
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: ciphertextData,
            tag: tagData
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// Encrypts a Codable object
    func encrypt<T: Codable>(_ object: T) throws -> Data {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        return try encrypt(data)
    }
    
    /// Decrypts data to a Codable object
    func decrypt<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        let data = try decrypt(encryptedData)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

enum EncryptionError: Error {
    case keychainError
    case invalidData
    case decryptionFailed
}

