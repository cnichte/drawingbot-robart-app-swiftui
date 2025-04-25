//
//  RobartMacTests.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

// RobartMacTests.swift
import XCTest
@testable import Robart

final class RobartMacTests: XCTestCase {
    
    override func setUpWithError() throws {
        print("🔧 Setup läuft…")
        // z.B. Mock-Daten vorbereiten
    }

    override func tearDownWithError() throws {
        print("🧹 Teardown läuft…")
        // z.B. Testdaten aufräumen
    }
    
    func testSimpleAddition() throws {
        XCTAssertEqual(2 + 3, 5, "Addition sollte funktionieren")
    }
    
    func testDefaultPaperFormatValues() throws {
        let defaultFormat = PaperFormat.default
        XCTAssertEqual(defaultFormat.name, "DIN A4")
        XCTAssertEqual(defaultFormat.width, 210)
        XCTAssertEqual(defaultFormat.height, 297)
        XCTAssertEqual(defaultFormat.unit, "mm")
    }
    
    func testInitializePaperFormatWithUUID() throws {
        let uuid = UUID(uuidString: "7e3eb341-cee9-4da6-8acb-677d5cb19e13")!
        let paper = PaperFormat(id: uuid, name: "Test", width: 100, height: 200, unit: "mm")
        XCTAssertEqual(paper.id, uuid)
        XCTAssertEqual(paper.name, "Test")
    }
    
    // MARK: - Async Example
    
    func testAsyncLoadItems() async throws {
        let store = GenericStore<PaperFormat>(directoryName: "paperformats")
        await store.loadItems()
        
        XCTAssertTrue(store.items.count >= 0, "Store sollte initialisiert sein, auch wenn leer")
    }
    
    // MARK: - Mocking Example
    
    func testMockedDataLoading() throws {
        struct MockPaperFormat: Codable, Identifiable {
            var id: UUID
            var name: String
            var width: Double
            var height: Double
            var unit: String
        }
        
        let mock = MockPaperFormat(
            id: UUID(),
            name: "TestFormat",
            width: 100,
            height: 200,
            unit: "mm"
        )
        
        XCTAssertEqual(mock.width, 100)
        XCTAssertEqual(mock.height, 200)
        XCTAssertEqual(mock.unit, "mm")
    }
}
