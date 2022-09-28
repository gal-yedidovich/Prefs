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
//
//	func testCodable() throws {
//		let prefs = createPrefs()
//
//		let dict = ["one": 1, "two": 2]
//		prefs.edit().put(key: .numbers, dict).commit()
//
//		XCTAssertEqual(dict, prefs.codable(key: .numbers))
//		XCTAssertEqual(dict, prefs.codable(key: .numbers, as: [String: Int].self))
//
//		afterWrite(at: prefs) { json in
//			do {
//				guard let dictStr = json[PrefKey.numbers.value] else {
//					XCTFail("numbers dictionary is nil")
//					return
//				}
//
//				let dict2: [String: Int] = try .from(json: dictStr)
//				XCTAssertEqual(dict, dict2)
//			} catch {
//				XCTFail(error.localizedDescription)
//			}
//		}
//
//		try teardown(prefs)
//	}
//
//	func testParallelWrites() throws {
//		let prefs = createPrefs()
//
//		let prefixes = ["Bubu", "Groot", "Deadpool"]
//		let range = 0...9
//
//		let expectation = XCTestExpectation(description: "for concurrent writing")
//		expectation.expectedFulfillmentCount = prefixes.count
//		for prefix in prefixes {
//			async {
//				for i in range {
//					prefs.edit()
//						.put(key: PrefKey(value: "\(prefix)-\(i)"), i)
//						.commit()
//				}
//				expectation.fulfill()
//			}
//		}
//		wait(for: [expectation], timeout: 2)
//
//		afterWrite(at: prefs) { json in
//			XCTAssertEqual(json.count, prefixes.count * range.count)
//
//			for prefix in prefixes {
//				for i in range {
//					XCTAssertEqual(json["\(prefix)-\(i)"], "\(i)")
//				}
//			}
//		}
//
//		try teardown(prefs)
//	}
//
//	func testMultiplePrefs() throws {
//		let prefs1 = createPrefs(name: #function + "1")
//		let prefs2 = createPrefs(name: #function + "2")
//
//		let e = XCTestExpectation(description: "waiting for concurrent prefs")
//		async {
//			prefs1.edit()
//				.put(key: .name, "Bubu")
//				.put(key: .age, 100)
//				.commit()
//
//			XCTAssertEqual(prefs1.dict.count, 2)
//
//			self.afterWrite(at: prefs1) { json in
//				XCTAssertEqual(json.count, 2)
//			}
//
//			e.fulfill()
//		}
//		wait(for: [e], timeout: 10)
//
//		prefs2.edit()
//			.put(key: .name, "Groot")
//			.put(key: .age, 200)
//			.put(key: .isAlive, true)
//			.commit()
//
//		XCTAssertEqual(prefs2.dict.count, 3)
//
//		afterWrite(at: prefs2) { json in
//			XCTAssertEqual(json.count, 3)
//		}
//
//		try teardown(prefs1, prefs2)
//	}
//
//	func testStringAsCodable() throws {
//		let prefs = createPrefs()
//
//		prefs.edit().put(key: .name, "Bubu").commit()
//
//		let str1 = prefs.string(key: .name)
//		let str2: String? = prefs.codable(key: .name)
//
//		XCTAssertEqual(str1, str2)
//
//		try teardown(prefs)
//	}
//
//	func testBatchingStrategy() throws {
//		let prefs = createPrefs(strategy: .batch)
//
//		for i in 1...10 {
//			prefs.edit().put(key: .age, i).commit()
//			XCTAssertEqual(prefs.int(key: .age), i)
//		}
//
//		let expectation = XCTestExpectation(description: "wait to write batch to Prefs")
//		prefs.queue.asyncAfter(deadline: .now() + DEFAULT_BATCH_DELAY) {
//			self.check(prefs, expectation) { json in
//				XCTAssertEqual(json[PrefKey.age.value], "10")
//			}
//		}
//		wait(for: [expectation], timeout: 10)
//
//		try teardown(prefs)
//	}
//
//	func testContains() throws {
//		let prefs = createPrefs()
//
//		prefs.edit()
//			.put(key: .age, 10)
//			.put(key: .name, "gal")
//			.commit()
//
//		XCTAssert(prefs.contains(.age))
//		XCTAssert(prefs.contains(.age, .name))
//		XCTAssertFalse(prefs.contains(.isAlive))
//		XCTAssertFalse(prefs.contains(.age, .name, .isAlive))
//
//		try teardown(prefs)
//	}
//
//	func testObservers() throws {
//		let prefs = createPrefs()
//		var didNotify = [false, false]
//
//		var store = Set<AnyCancellable>()
//		prefs.publisher.sink { _ in didNotify[0] = true }.store(in: &store)
//		prefs.publisher.sink { _ in didNotify[1] = true }.store(in: &store)
//
//		prefs.edit().put(key: .name, "gal").commit()
//
//		XCTAssertTrue(didNotify[0])
//		XCTAssertTrue(didNotify[1])
//		store.removeAll()
//
//		try teardown(prefs)
//	}
//
//	func testWriteBatchIgnoredAfterDeinit() throws {
//		let filename = #function
//		var prefs: Prefs? = createPrefs(name: filename, strategy: .batch)
//		prefs?.edit().put(key: .name, "gal").commit()
//		prefs = nil
//
//		let expectation = XCTestExpectation(description: "waiting for delay")
//		prefs?.queue.asyncAfter(deadline: .now() + DEFAULT_BATCH_DELAY) {
//			expectation.fulfill()
//		}
//		wait(for: [expectation], timeout: 10)
//
//		XCTAssertFalse(fileExists(at: filename))
//	}
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

func writeContent(at url: URL, content: [String: String]) throws {
	let json = try JSONEncoder().encode(content)
	try json.write(to: url)
}

func syncRead(_ prefs: Prefs) async -> [String: String]? {
	return await withUnsafeContinuation { continuation in
		prefs.queue.async {
			guard let data = try? Data(contentsOf: prefs.url) else {
				continuation.resume(returning: nil)
				return
			}
			let content = try? JSONDecoder().decode([String: String].self, from: data)
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

