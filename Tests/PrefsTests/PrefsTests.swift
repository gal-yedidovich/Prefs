import XCTest
import Combine
@testable import Prefs

final class PrefsTests: XCTestCase {
	func testShouldInitWithEmptyValues() {
		//Given
		let url = url(from: #function)
		
		//When
		let prefs = Prefs(url: url)
		
		//Then
		XCTAssertEqual(prefs.dict, [:])
	}
	
	func testShouldLoadValuesOnInit() throws {
		//Given
		let url: URL = url(from: #function)
		let EXPECTED_CONTENT: [String: String] = ["Key": "Bubu"]
		try writeContent(at: url, content: EXPECTED_CONTENT)
		defer { remove(file: url) }
		
		//When
		let prefs = Prefs(url: url)
		
		//Then
		XCTAssertEqual(prefs.dict, EXPECTED_CONTENT)
	}
	
	func testShouldInsertValue() async {
		//Given
		let url: URL = url(from: #function)
		let prefs = Prefs(url: url, writeStrategy: .immediate)
		let EXPECTED_VALUE = "Bubu"
		defer { remove(file: url) }
		
		//When
		prefs.edit().put(key: .name, EXPECTED_VALUE).commit()
		
		//Then
		XCTAssertEqual(prefs.dict[PrefKey.name.value], EXPECTED_VALUE)
		let content = await syncRead(prefs)
		XCTAssertEqual(content?[PrefKey.name.value], EXPECTED_VALUE)
	}
	
	func testShouldReplaceValue() async throws {
		//Given
		let EXPECTED_VALUE = "Groot"
		let url: URL = url(from: #function)
		try writeContent(at: url, content: [PrefKey.name.value: "Bubu 1"])
		let prefs = Prefs(url: url, writeStrategy: .immediate)
		defer { remove(file: url) }
		
		//When
		prefs.edit().put(key: .name, EXPECTED_VALUE).commit()
		
		//Then
		XCTAssertEqual(prefs.dict[PrefKey.name.value], EXPECTED_VALUE)
		let dict = await syncRead(prefs)
		XCTAssertEqual(dict?[PrefKey.name.value], EXPECTED_VALUE)
	}
	
	func testShouldRemoveValue() async throws {
		//Given
		let url: URL = url(from: #function)
		try writeContent(at: url, content: [PrefKey.name.value: "Bubu", "Key2": "some"])
		let prefs = Prefs(url: url, writeStrategy: .immediate)
		
		//When
		prefs.edit().remove(key: .name).commit()
		
		//Then
		XCTAssertNil(prefs.dict[PrefKey.name.value])
		let dict = await syncRead(prefs)
		XCTAssertNil(dict?[PrefKey.name.value])
	}
	
	func testShouldClearAllValues() async throws {
		//Given
		let url = url(from: #function)
		try writeContent(at: url, content: ["Key": "Bubu", "Key 2": "4"])
		let prefs = Prefs(url: url, writeStrategy: .immediate)
		defer { remove(file: url) }
		
		//When
		prefs.edit().clear().commit()
		
		//Then
		XCTAssertEqual(prefs.dict, [:])
		_ = await syncRead(prefs)
		XCTAssertFalse(fileExists(at: url))
	}
	
	/*
	 TODO: add read tests
	 testShouldReadInt
	 testShouldReadString
	 testShouldReadBool
	 testShouldReadCodable
	 testShouldReturnNil_whenValueMissing
	 testShouldReturnTrue_whenContainsValue
	 testShouldReturnFalse_whenNotContainingValue
	 
	 TODO: add other tests
	 testShouldHandleParallelWrite
	 testShuoldBatchCommits
	 testShuoldObserveChanges
	 testShouldCancelBatchWrite_whenDeinitBeforeTimeout
	 */
}

private extension PrefsTests {
	func teardown(_ prefs: Prefs...) throws {
		for p in prefs {
			try p.queue.sync {
				try FileManager.default.removeItem(at: p.url)
			}
		}
	}
	
	func afterWrite(at prefs: Prefs, test: @escaping TestHandler) {
		let expectation = XCTestExpectation(description: "wait to write to Prefs")
		
		prefs.queue.async { //after written to storage
//			self.check(prefs, expectation, test: test) // TODO: read file
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
//	func check(_ prefs: Prefs, _ expectation: XCTestExpectation, test: @escaping TestHandler) {
//		do {
//			test(try Filer.load(json: prefs.filename))
//		} catch {
//			XCTFail(error.localizedDescription)
//		}
//		expectation.fulfill()
//	}
}

func writeContent(at url: URL, content: PrefsContent) throws {
	let json = try JSONEncoder().encode(content)
	try json.write(to: url)
}

func syncRead(_ prefs: Prefs) async -> PrefsContent? {
	return await withUnsafeContinuation { continuation in
		prefs.queue.async {
			guard let data = try? Data(contentsOf: prefs.url) else {
				continuation.resume(returning: nil)
				return
			}
			let content = try? JSONDecoder().decode(PrefsContent.self, from: data)
			continuation.resume(returning: content)
		}
	}
}

func remove(file url: URL) {
	try? FileManager.default.removeItem(at: url)
}

func fileExists(at url: URL) -> Bool {
	return FileManager.default.fileExists(atPath: url.path)
}

func url(from name: String) -> URL {
	let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
	return dir.appendingPathComponent(name)
}

fileprivate typealias TestHandler = ([String:String]) -> Void

fileprivate extension PrefKey {
	static let name = PrefKey(value: "name")
	static let age = PrefKey(value: "age")
	static let isAlive = PrefKey(value: "isAlive")
	static let numbers = PrefKey(value: "numbers")
}

