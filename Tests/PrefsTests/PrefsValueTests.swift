//
//  PrefsValue.swift
//  
//
//  Created by Gal Yedidovich on 01/10/2022.
//

import Foundation
import XCTest
import Prefs

final class PrefsValueTests: XCTestCase {
	lazy var prefs: Prefs = Prefs(suite: name)
	
	override func tearDown() {
		prefs.edit().clear().commit()
	}
	
	func testShouldBeNil_whenKeyIsMissing() {
		//Given
		
		//When
		@PrefsValue(.firstName, prefs: prefs) var name: String?
		
		//Then
		XCTAssertNil(name)
	}

	func testShouldBeDefaultValue_whenKeyIsMissing() {
		//Given
		let EXPECTED_DEFAULT_VALUE = "default value"
		
		//When
		@PrefsValue(.firstName, prefs: prefs) var name = EXPECTED_DEFAULT_VALUE
		
		//Then
		XCTAssertEqual(name, EXPECTED_DEFAULT_VALUE)
	}
	
	func testShouldUsePrefsValue() {
		//Given
		let EXPECTED_VALUE = "bubu"
		prefs.edit().put(key: .lastName, EXPECTED_VALUE).commit()
		
		//When
		@PrefsValue(.lastName, prefs: prefs) var name = "default value"
		
		//Then
		XCTAssertEqual(name, EXPECTED_VALUE)
	}
	
	func testShouldUpdatePrefs_whenAssigningNewValue() {
		//Given
		@PrefsValue(.age, prefs: prefs) var age = 10
		
		//When
		age = 15
		
		//Then
		XCTAssertEqual(prefs.int(key: .age), age)
	}
	
	func testShouldRemoveFromPrefs_whenAssigningNil() {
		//Given
		@PrefsValue(.age, prefs: prefs) var age: Int?
		age = 9
		
		//When
		age = nil
		
		//Then
		XCTAssertFalse(prefs.contains(.age))
	}
	
	func testShouldUpdatePrefsValue_whenEditingPrefs() {
		//Given
		@PrefsValue(.isAlive, prefs: prefs) var isAlive = false
		
		//When
		prefs.edit().put(key: .isAlive, true).commit()
		
		//Then
		XCTAssertTrue(isAlive)
	}
}

fileprivate extension Prefs.Key {
	static let firstName = Prefs.Key(value: "firstName")
	static let lastName =  Prefs.Key(value: "lastName")
	static let isAlive = Prefs.Key(value: "isAlive")
	static let age = Prefs.Key(value: "age")
}
