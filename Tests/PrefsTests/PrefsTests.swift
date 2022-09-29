import XCTest
import Combine
import SimpleEncryptor
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
		defer { remove(file: url) }
		
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
	
	func testShouldReadInt() throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_NUMBER = 4
		try writeContent(at: url, content: [PrefKey.age.value: "\(EXPECTED_NUMBER)"])
		let prefs = Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let num = prefs.int(key: .age)
		
		//Then
		XCTAssertEqual(num, EXPECTED_NUMBER)
	}
	
	func testShouldReadString() throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_STRING = "Deadpool"
		try writeContent(at: url, content: [PrefKey.name.value: EXPECTED_STRING])
		let prefs = Prefs(url: url)
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
		try writeContent(at: url, content: [PrefKey.isAlive.value: "\(EXPECTED_BOOL)"])
		let prefs = Prefs(url: url)
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
		let prefs = Prefs(url: url)
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
		try writeContent(at: url, content: [PrefKey.payload.value: payloadString])
		let prefs = Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let payload = prefs.codable(key: .payload, as: Payload.self)
		
		//Then
		XCTAssertEqual(payload, EXPECTED_PAYLOAD)
	}
	
	func testShouldReturnNil_whenValueMissing() {
		//Given
		let url = url(from: #function)
		let prefs = Prefs(url: url)
		
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
		try writeContent(at: url, content: [PrefKey.name.value: "Bubu"])
		let prefs = Prefs(url: url)
		defer { remove(file: url) }
		
		//When
		let valueExists = prefs.contains(.name)
		
		//Then
		XCTAssertTrue(valueExists)
	}
	
	func testShouldReturnFalse_whenNotContainingValue() throws {
		//Given
		let url = url(from: #function)
		let prefs = Prefs(url: url)
		
		//When
		let valueExists = prefs.contains(.name)
		
		//Then
		XCTAssertFalse(valueExists)
	}
	
	func testShouldHandleParallelWrite() async throws {
		//Given
		let url = url(from: #function)
		let prefs = Prefs(url: url, writeStrategy: .immediate)
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
					prefs.edit()
						.put(key: PrefKey(value: "key - \(i)"), i)
						.commit()
				}
			}
		})
		
		//Then
		XCTAssertEqual(prefs.dict, EXPECTED_COTENT)
		let content = await syncRead(prefs)
		XCTAssertEqual(content, EXPECTED_COTENT)
	}
	
	func testShouldBatchCommits() async throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_BATCH_DELAY = 0.01
		let EXPECTED_CONTENT: PrefsContent = [
			PrefKey.name.value: "Bubu",
			PrefKey.age.value: "10"
		]
		let prefs = Prefs(url: url, writeStrategy: .batch(delay: EXPECTED_BATCH_DELAY))
		defer { remove(file: url) }
		
		//When
		prefs.edit()
			.put(key: .name, "Bubu")
			.commit()
		
		prefs.edit()
			.put(key: .age, 10)
			.commit()
		
		
		//Then
		XCTAssertEqual(prefs.string(key: .name), "Bubu")
		XCTAssertEqual(prefs.int(key: .age), 10)
		XCTAssertFalse(fileExists(at: url))
		
		try await Task.sleep(nanoseconds: UInt64(EXPECTED_BATCH_DELAY * 1_000_000_000))
		let content = await syncRead(prefs)
		XCTAssertEqual(content, EXPECTED_CONTENT)
	}
	
	func testShouldCancelBatchWrite_whenDeinitBeforeTimeout() async throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_BATCH_DELAY = 0.01
		var prefs: Prefs? = Prefs(url: url, writeStrategy: .batch(delay: EXPECTED_BATCH_DELAY))
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
	
	func testShouldObserveChanges() {
		//Given
		let url = url(from: #function)
		let prefs = Prefs(url: url)
		var flags = [false, false]
		var store = Set<AnyCancellable>()
		prefs.publisher.sink { _ in flags[0] = true }.store(in: &store)
		prefs.publisher.sink { _ in flags[1] = true }.store(in: &store)
		
		//When
		prefs.edit()
			.put(key: .name, "Bubu")
			.commit();
		
		//Then
		XCTAssertTrue(flags[0])
		XCTAssertTrue(flags[1])
	}
}

func writeContent(at url: URL, content: PrefsContent) throws {
	let json = try JSONEncoder().encode(content)
	let endData = try SimpleEncryptor(type: .gcm).encrypt(data: json)
	try endData.write(to: url)
}

func syncRead(_ prefs: Prefs) async -> PrefsContent? {
	return await withUnsafeContinuation { continuation in
		prefs.queue.async {
			let encryptor = SimpleEncryptor(type: .gcm)
			guard let encData = try? Data(contentsOf: prefs.url),
				  let data = try? encryptor.decrypt(data: encData) else {
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
	static let payload = PrefKey(value: "payload")
}

