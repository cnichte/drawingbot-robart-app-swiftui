//
//  UUIDHelperTests.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

// UUIDHelperTests.swift
import XCTest

final class UUIDHelperTests: XCTestCase {
    
    func testValidUUIDStrings() {
        let validUUID = "7e3eb341-cee9-4da6-8acb-677d5cb19e13"
        XCTAssertTrue(validUUID.isValidUUID)
    }
    
    func testInvalidUUIDStrings() {
        let invalidUUID = "not-a-valid-uuid"
        XCTAssertFalse(invalidUUID.isValidUUID)
    }
    
    func testUUIDFromString_Success() {
        let uuidString = "7e3eb341-cee9-4da6-8acb-677d5cb19e13"
        let uuid = UUID.from(uuidString)
        XCTAssertNotNil(uuid)
        XCTAssertEqual(uuid?.uuidString.lowercased(), uuidString.lowercased())
    }
    
    func testUUIDFromString_Failure() {
        let uuidString = "invalid-uuid"
        let uuid = UUID.from(uuidString)
        XCTAssertNil(uuid)
    }
    
    func testUUIDSafeFromString_Success() {
        let uuidString = "7e3eb341-cee9-4da6-8acb-677d5cb19e13"
        let uuid = UUID.safeFrom(uuidString)
        XCTAssertEqual(uuid.uuidString.lowercased(), uuidString.lowercased())
    }
    
    func testUUIDSafeFromString_FailureFallback() {
        let uuidString = "not-valid"
        let uuid = UUID.safeFrom(uuidString)
        XCTAssertNotNil(uuid)
    }
    
    // MARK: - Async Variante (Demo)
    
    func testUUIDAsyncLoading() async throws {
        let uuidString = "7e3eb341-cee9-4da6-8acb-677d5cb19e13"
        let uuid = try await loadUUIDAsync(from: uuidString)
        XCTAssertEqual(uuid.uuidString.lowercased(), uuidString.lowercased())
    }
    
    private func loadUUIDAsync(from string: String) async throws -> UUID {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s simuliertes Delay
        guard let uuid = UUID.from(string) else {
            throw URLError(.badURL)
        }
        return uuid
    }
}
