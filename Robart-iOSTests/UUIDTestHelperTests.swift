//
//  UUIDTestHelperTests.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

// UUIDTestHelperTests.swift
import XCTest
 // TODO: @testable import Robart_IOS // ⬅️ WICHTIG: hier musst du deinen Projektnamen eintragen

final class UUIDTestHelperTests: XCTestCase {
    
    func testRandomUUIDIsUnique() {
        let uuid1 = UUIDTestHelper.random
        let uuid2 = UUIDTestHelper.random
        XCTAssertNotEqual(uuid1, uuid2, "Random UUIDs sollten unterschiedlich sein")
    }
    
    func testZeroUUIDIsAllZeros() {
        let zero = UUIDTestHelper.zero
        XCTAssertEqual(zero.uuidString, "00000000-0000-0000-0000-000000000000", "Zero-UUID sollte aus Nullen bestehen")
    }
    
    func testDummyUUIDIsCorrect() {
        let dummy = UUIDTestHelper.dummy
        XCTAssertEqual(dummy.uuidString, "11111111-1111-1111-1111-111111111111", "Dummy-UUID sollte korrekt sein")
    }
    
    func testFixedUUIDFromValidString() {
        let input = "7e3eb341-cee9-4da6-8acb-677d5cb19e13"
        let fixed = UUIDTestHelper.fixed(input)
        XCTAssertEqual(fixed.uuidString, input, "Fixe UUID sollte identisch sein mit Eingabestring")
    }
    
    func testFixedUUIDFromInvalidStringFallsBackToRandom() {
        let invalidInput = "INVALID-UUID-STRING"
        let fixed = UUIDTestHelper.fixed(invalidInput)
        XCTAssertNotNil(fixed, "UUID sollte trotzdem generiert werden, auch wenn der String ungültig war")
    }
}
