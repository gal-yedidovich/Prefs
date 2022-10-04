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
	lazy var prefs = Prefs(suite: name, content: TestContent())
	
	override func tearDown() {
		try? prefs.clear()
	}

	func testShouldBeInitialValue() {
		//Given
		
		//When
		@PrefsValue(prefs, \.firstName) var name: String
		
		//Then
		XCTAssertEqual(name, "")
	}
	
	func testShouldUpdatePrefs_whenAssigningNewValue() {
		//Given
		@PrefsValue(prefs, \.age) var age: Int
		
		//When
		age = 15
		
		//Then
		XCTAssertEqual(prefs[\.age], age)
	}
	
	func testShouldUpdatePrefsValue_whenEditingPrefs() {
		//Given
		@PrefsValue(prefs, \.isAlive) var isAlive: Bool
		
		//When
		prefs[\.isAlive] = true
		
		//Then
		XCTAssertTrue(isAlive)
	}
	
	struct TestContent: Codable & Equatable {
		var firstName: String = ""
		var lastName: String = ""
		var isAlive: Bool = false
		var age: Int = 0
	}
}
