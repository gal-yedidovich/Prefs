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
	func testShouldBeDefaultValue_whenKeyIsMissing() {
		//Given
		let prefs = Prefs(suite: #function)
		let EXPECTED_DEFAULT_VALUE = "default value"
		
		//When
		@PrefsValue(.firstName, prefs: prefs) var name = EXPECTED_DEFAULT_VALUE
		
		//Then
		XCTAssertEqual(name, EXPECTED_DEFAULT_VALUE)
	}
	
	func testShouldUsePrefsValue() {
		//Given
		let prefs = Prefs(suite: #function)
		let EXPECTED_VALUE = "bubu"
		prefs.edit().put(key: .lastName, EXPECTED_VALUE).commit()
		defer { prefs.edit().clear().commit() }
		
		//When
		@PrefsValue(.lastName, prefs: prefs) var name = "default value"
		
		//Then
		XCTAssertEqual(name, EXPECTED_VALUE)
	}
	
	func testShouldUpdatePrefs_whenAssigningNewValue() {
		//Given
		let prefs = Prefs(suite: #function)
		@PrefsValue(.age, prefs: prefs) var age = 10
		
		//When
		age = 15
		
		//Then
		XCTAssertEqual(prefs.int(key: .age), age)
	}
	
	func testShouldUpdatePrefsValue_whenEditingPrefs() {
		//Given
		let prefs = Prefs(suite: #function)
		@PrefsValue(.isAlive, prefs: prefs) var isAlive = false
		defer { prefs.edit().clear().commit() }
		
		//When
		prefs.edit().put(key: .isAlive, true).commit()
		
		//Then
		XCTAssertTrue(isAlive)
	}
}

fileprivate extension PrefKey {
	static let firstName = PrefKey(value: "firstName")
	static let lastName = PrefKey(value: "lastName")
	static let isAlive = PrefKey(value: "isAlive")
	static let age = PrefKey(value: "age")
}
