import XCTest
import Combine
import SimpleEncryptor
@testable import Prefs

final class PrefsTests: XCTestCase {
	func testShouldLoadValuesOnInit() throws {
		//Given
		let url: URL = url(from: #function)
		let EXPECTED_CONTENT = TestContent(name: "Bubu", age: 5, temperature: 36.6, isAlive: true)
		try EncryptedFileRepository(url: url).write(EXPECTED_CONTENT)
		defer { remove(file: url) }
		
		//When
		let prefs = try Prefs(url: url, content: TestContent())
		
		//Then
		XCTAssertEqual(prefs.content, EXPECTED_CONTENT)
	}
	
	func testShouldAssignValue() async throws {
		//Given
		let url: URL = url(from: #function)
		let prefs = try Prefs(url: url, content: TestContent())
		let EXPECTED_VALUE = "Bubu"
		defer { remove(file: prefs.url) }
		
		//When
		prefs[\.name] = EXPECTED_VALUE
		
		//Then
		XCTAssertEqual(prefs.content.name, EXPECTED_VALUE)
		await delay(0.1, on: prefs.queue)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content.name, EXPECTED_VALUE)
	}
	
	func testShouldHandleParallelWrite() async throws {
		//Given
		let url = url(from: #function)
		let prefs = try Prefs(url: url, content: TestContent())
		let EXPECTED_COTENT: TestContent = TestContent(
			name: "Bubu",
			age: 1,
			temperature: 1.2,
			isAlive: false
		)
		defer { remove(file: url) }
		
		//When
		await withTaskGroup(of: Void.self, body: { group in
			group.addTask { prefs[\.name] = EXPECTED_COTENT.name }
			group.addTask { prefs[\.age] = EXPECTED_COTENT.age }
			group.addTask { prefs[\.temperature] = EXPECTED_COTENT.temperature }
			group.addTask { prefs[\.isAlive] = EXPECTED_COTENT.isAlive }
		})
		
		//Then
		XCTAssertEqual(prefs.content, EXPECTED_COTENT)
		await delay(0.1, on: prefs.queue)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content, EXPECTED_COTENT)
	}
	
	func testShouldBatchCommits() async throws {
		//Given
		let url = url(from: #function)
		let EXPECTED_CONTENT = TestContent(name: "asd", isAlive: true)
		let prefs = try Prefs(url: url, content: TestContent())
		defer { remove(file: url) }
		
		//When
		prefs[\.name] = "asd"
		prefs[\.isAlive] = true
		
		
		//Then
		XCTAssertEqual(prefs[\.name], "asd")
		XCTAssertEqual(prefs[\.isAlive], true)
		XCTAssertFalse(fileExists(at: url))
		
		await delay(0.1, on: prefs.queue)
		let content = try readContent(of: prefs)
		XCTAssertEqual(content, EXPECTED_CONTENT)
	}
	
	func testShouldCancelBatchWrite_whenDeinitBeforeTimeout() async throws {
		//Given
		let url = url(from: #function)
		var prefs: Prefs? = try Prefs(url: url, content: TestContent())
		let queue = prefs!.queue

		//When
		prefs?[\.name] = "New Value"
		prefs = nil

		//Then
		await delay(0.1, on: queue)
		XCTAssertFalse(fileExists(at: url))
	}
	
	func testShouldObserveChanges() async throws {
		//Given
		let prefs = Prefs(suite: #function, content: TestContent())
		var flags = [false, false]
		var store = Set<AnyCancellable>()
		prefs.publisher.sink { _ in flags[0] = true }.store(in: &store)
		prefs.publisher.sink { _ in flags[1] = true }.store(in: &store)
		defer { remove(file: prefs.url) }
		
		//When
		prefs[\.name] = "Bubu"
		
		//Then
		await delay(0.1, on: prefs.queue)
		XCTAssertTrue(flags[0])
		XCTAssertTrue(flags[1])
	}
	
	func testShouldThrowError_whenInitWithInvalidUrl() throws {
		//Given
		let url = URL(string: "https://www.google.com")!
		
		//When
		//Then
		XCTAssertThrowsError(try Prefs(url: url, content: TestContent()))
	}
	
	
	struct TestContent: Codable, Equatable {
		var name: String = ""
		var age: Int = 0
		var temperature: Double = 0.0
		var isAlive: Bool = false
		var payload: TestInnerContent? = nil
		
		struct TestInnerContent: Codable, Equatable {
			var value: String = ""
		}
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

func readContent<Content: Codable & Equatable>(of prefs: Prefs<Content>) throws -> Content {
	let encryptor = SimpleEncryptor(type: .gcm)
	return try prefs.queue.sync {
		let encData = try Data(contentsOf: prefs.url)
		let data = try encryptor.decrypt(data: encData)
		return try JSONDecoder().decode(Content.self, from: data)
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
