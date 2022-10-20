import XCTest
import Combine
import SimpleEncryptor
@testable import Prefs

final class PrefsTests: XCTestCase {
	func testShouldInitWithEmptyValues() {
		//Given
		
		//When
		let prefs = Prefs(suite: #function)
		
		//Then
		XCTAssertEqual(prefs.dict, [:])
	}
	
	func testShouldLoadValuesOnInit() throws {
		//Given
		let url: URL = url(from: #function)
		let EXPECTED_CONTENT: PrefsContent = ["Key": "Bubu"]
		try writeContent(at: url, content: EXPECTED_CONTENT)
		defer { remove(file: url) }
		
		//When
		let prefs = try Prefs(url: url)
		
		//Then
		XCTAssertEqual(prefs.dict, EXPECTED_CONTENT)
	}
	
	func testShouldInsertValue() throws {
		//Given
		let url: URL = url(from: #function)
		let prefs = try Prefs(url: url, writeStrategy: .immediate)
		let EXPECTED_VALUE = "Bubu"
		defer { remove(file: prefs.url) }
		
		//When
		prefs.edit().put(key: .name, EXPECTED_VALUE).commit()
		
		//Then
		XCTAssertEqual(prefs.string(key: .name), EXPECTED_VALUE)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content[Prefs.Key.name.value], EXPECTED_VALUE)
	}
	
	func testShouldReplaceValue() throws {
		//Given
		let EXPECTED_VALUE = "Groot"
		let url: URL = url(from: #function)
		try writeContent(at: url, content: [Prefs.Key.name.value: "Bubu 1"])
		let prefs = try Prefs(url: url, writeStrategy: .immediate)
		defer { remove(file: url) }
		
		//When
		prefs.edit().put(key: .name, EXPECTED_VALUE).commit()
		
		//Then
		XCTAssertEqual(prefs.string(key: .name), EXPECTED_VALUE)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content[Prefs.Key.name.value], EXPECTED_VALUE)
	}
	
	func testShouldRemoveValue() throws {
		//Given
		let url: URL = url(from: #function)
		try writeContent(at: url, content: [Prefs.Key.name.value: "Bubu", "Key2": "some"])
		let prefs = try Prefs(url: url, writeStrategy: .immediate)
		defer { remove(file: url) }
		
		//When
		prefs.edit().remove(key: .name).commit()
		
		//Then
		XCTAssertNil(prefs.string(key: .name))
		let dict = try readContent(of: prefs)
		XCTAssertNil(dict[Prefs.Key.name.value])
	}
	
	func testShouldClearAllValues() throws {
		//Given
		let url = url(from: #function)
		try writeContent(at: url, content: ["Key": "Bubu", "Key 2": "4"])
		let prefs = try Prefs(url: url, writeStrategy: .immediate)
		defer { remove(file: url) }
		
		//When
		prefs.edit().clear().commit()
		
		//Then
		XCTAssertEqual(prefs.dict, [:])
		XCTAssertFalse(fileExists(at: url))
	}
	
	func testShouldDeleteFileRemovingLastValue() throws {
		//Given
		let url: URL = url(from: #function)
		try writeContent(at: url, content: [Prefs.Key.name.value: "Last"])
		let prefs = try Prefs(url: url, writeStrategy: .immediate)
		
		//When
		prefs.edit().remove(key: .name).commit()
		
		//Then
		XCTAssertFalse(fileExists(at: url))
	}
	
	func testShouldReadInt() throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_NUMBER = 4
		try writeContent(at: url, content: [Prefs.Key.age.value: "\(EXPECTED_NUMBER)"])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let num = prefs.int(key: .age)
		
		//Then
		XCTAssertEqual(num, EXPECTED_NUMBER)
	}
	
	func testShouldReadDouble() throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_NUMBER = 36.6
		try writeContent(at: url, content: [Prefs.Key.temperature.value: "\(EXPECTED_NUMBER)"])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let temp = prefs.double(key: .temperature)
		
		//Then
		XCTAssertEqual(temp, EXPECTED_NUMBER)
	}
	
	func testShouldReadString() throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_STRING = "Deadpool"
		try writeContent(at: url, content: [Prefs.Key.name.value: EXPECTED_STRING])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let str = prefs.string(key: .name)
		
		//Then
		XCTAssertEqual(str, EXPECTED_STRING)
	}
	
	func testShouldReadBool() throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_BOOL = true
		try writeContent(at: url, content: [Prefs.Key.isAlive.value: "\(EXPECTED_BOOL)"])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let bool = prefs.bool(key: .isAlive)
		
		//Then
		XCTAssertEqual(bool, EXPECTED_BOOL)
	}
	
	func testShouldReadBoolFallback() throws {
		//Given
		let url = url(from: #function)
		try writeContent(at: url, content: [:])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let bool = prefs.bool(key: .isAlive)
		
		//Then
		XCTAssertFalse(bool)
	}
	
	func testShouldReadCodable() throws {
		//Given
		struct Payload: Codable, Equatable { var field: String }
		let EXPECTED_PAYLOAD: Payload = Payload(field: "Some Value")
		let payloadString = try String(decoding: JSONEncoder().encode(EXPECTED_PAYLOAD), as: UTF8.self)
		let url = url(from: #function)
		try writeContent(at: url, content: [Prefs.Key.payload.value: payloadString])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let payload = prefs.codable(key: .payload, as: Payload.self)
		
		//Then
		XCTAssertEqual(payload, EXPECTED_PAYLOAD)
	}
	
	func testShouldReturnNil_whenValueMissing() throws {
		//Given
		let url = url(from: #function)
		let prefs = try Prefs(url: url)
		
		//When
		let string = prefs.string(key: .age)
		let num = prefs.int(key: .age)
		let bool = prefs.bool(key: .age)
		let codable = prefs.codable(key: .age, as: [String].self)
		
		//Then
		XCTAssertNil(string)
		XCTAssertNil(num)
		XCTAssertFalse(bool)
		XCTAssertNil(codable)
	}
	
	func testShouldReturnTrue_whenContainsValue() throws {
		//Given
		let url = url(from: #function)
		try writeContent(at: url, content: [Prefs.Key.name.value: "Bubu"])
		let prefs = try Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let valueExists = prefs.contains(.name)
		
		//Then
		XCTAssertTrue(valueExists)
	}
	
	func testShouldReturnFalse_whenNotContainingValue() throws {
		//Given
		let url = url(from: #function)
		let prefs = try Prefs(url: url)
		
		//When
		let valueExists = prefs.contains(.name)
		
		//Then
		XCTAssertFalse(valueExists)
	}
	
	func testShouldHandleParallelWrite() async throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_BATCH_DELAY = 0.01
		let prefs = try Prefs(url: url, writeStrategy: .batch(delay: EXPECTED_BATCH_DELAY))
		let EXPECTED_COTENT: PrefsContent = [
			"key - 1": "1",
			"key - 2": "2",
			"key - 3": "3",
			"key - 4": "4",
			"key - 5": "5",
		]
		defer { remove(file: url) }
		
		//When
		await withTaskGroup(of: Void.self, body: { group in
			for i in 1...5 {
				group.addTask {
					prefs.edit().put(key: Prefs.Key(value: "key - \(i)"), i).commit()
				}
			}
		})
		
		//Then
		XCTAssertEqual(prefs.dict, EXPECTED_COTENT)
		await delay(EXPECTED_BATCH_DELAY, on: prefs.queue)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content, EXPECTED_COTENT)
	}
	
	func testShouldBatchCommits() async throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_BATCH_DELAY = 0.01
		let EXPECTED_CONTENT: PrefsContent = [
			Prefs.Key.name.value: "Bubu",
			Prefs.Key.age.value: "10"
		]
		let prefs = try Prefs(url: url, writeStrategy: .batch(delay: EXPECTED_BATCH_DELAY))
		defer { remove(file: url) }
		
		//When
		prefs.edit().put(key: .name, "Bubu").commit()
		prefs.edit().put(key: .age, 10).commit()
		
		
		//Then
		XCTAssertEqual(prefs.string(key: .name), "Bubu")
		XCTAssertEqual(prefs.int(key: .age), 10)
		XCTAssertFalse(fileExists(at: url))
		
		await delay(EXPECTED_BATCH_DELAY, on: prefs.queue)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content, EXPECTED_CONTENT)
	}
	
	func testShouldCancelBatchWrite_whenDeinitBeforeTimeout() async throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_BATCH_DELAY = 0.01
		var prefs: Prefs? = try Prefs(url: url, writeStrategy: .batch(delay: EXPECTED_BATCH_DELAY))
		let queue = prefs!.queue
		defer { remove(file: url) }
		
		//When
		prefs?.edit()
			.put(key: .name, "To be cancelled")
			.commit()
		prefs = nil
		
		//Then
		let e = XCTestExpectation(description: "waiting for batch timeout")
		queue.asyncAfter(deadline: .now() + EXPECTED_BATCH_DELAY) {
			XCTAssertFalse(fileExists(at: url))
			e.fulfill()
		}
		wait(for: [e], timeout: 10)
	}
	
	func testShouldObserveChanges() throws {
		//Given
		let prefs = Prefs(suite: #function)
		var flags = [false, false]
		var store = Set<AnyCancellable>()
		prefs.publisher.sink { _ in flags[0] = true }.store(in: &store)
		prefs.publisher.sink { _ in flags[1] = true }.store(in: &store)
		
		//When
		prefs.edit().put(key: .name, "Bubu").commit();
		
		//Then
		XCTAssertTrue(flags[0])
		XCTAssertTrue(flags[1])
	}
	
	func testShouldNotNotifyObserverOnEmptyCommit() throws {
		//Given
		let prefs = Prefs(suite: #function)
		var flag = false
		var store = Set<AnyCancellable>()
		prefs.publisher.sink { _ in flag = true }.store(in: &store)
		
		//When
		prefs.edit().commit()
		
		//Then
		XCTAssertFalse(flag)
	}
	
	func testShouldThrowError_whenInitWithInvalidUrl() throws {
		//Given
		let url = URL(string: "https://www.google.com")!
		
		//When
		//Then
		XCTAssertThrowsError(try Prefs(url: url))
	}
}

func writeContent(at url: URL, content: PrefsContent) throws {
	let json = try JSONEncoder().encode(content)
	let endData = try SimpleEncryptor(type: .gcm).encrypt(data: json)
	try endData.write(to: url)
}

func delay(_ delay: Double, on queue: DispatchQueue) async {
	return await withUnsafeContinuation { continuation in
		queue.asyncAfter(deadline: .now() + delay) {
			continuation.resume()
		}
	}
}

func readContent(of prefs: Prefs) throws -> PrefsContent {
	let encryptor = SimpleEncryptor(type: .gcm)
	return try prefs.queue.sync {
		let encData = try Data(contentsOf: prefs.url)
		let data = try encryptor.decrypt(data: encData)
		return try JSONDecoder().decode(PrefsContent.self, from: data)
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

fileprivate extension Prefs.Key {
	static let name = Prefs.Key(value: "name")
	static let age = Prefs.Key(value: "age")
	static let temperature = Prefs.Key(value: "temperature")
	static let isAlive = Prefs.Key(value: "isAlive")
	static let payload = Prefs.Key(value: "payload")
}
