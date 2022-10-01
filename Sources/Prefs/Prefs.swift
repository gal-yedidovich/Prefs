//
//  Prefs.swift
//
//
//  Created by Gal Yedidovich on 27/09/2022.
//
import Foundation
import Combine
import os

typealias PrefsContent = [String: String]

let logger = Logger()

enum PrefsError: LocalizedError {
	case invalidUrl
	
	var errorDescription: String? {
		switch self {
		case .invalidUrl:
			return "invalid url, must be a local file url"
		}
	}
}

public class Prefs {
	public static let standard = Prefs(suite: "_")

	internal let queue = DispatchQueue(label: "prefs", qos: .background)
	internal let url: URL
	internal let strategy: WriteStrategy
	internal let repository: Repository
	internal var dict: PrefsContent = [:]

	private let changeSubject = PassthroughSubject<Prefs, Never>()
	
	
	/// Initialize new Prefs instance with a suite name, and loading its content
	/// - Parameter suite: name of the prefs suite in the filesystem
	public convenience init(suite: String) {
		let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = dir.appendingPathComponent(suite)
		try! self.init(url: url)
	}
	
	/// Initialize new Prefs instance link to a given url, and loading its content
	/// - Parameter url: filepath in filesystem
	public convenience init(url: URL) throws {
		try self.init(url: url, writeStrategy: .batch)
	}
	
	/// Initialize new Prefs instance link to a given url and a writing strartegy, and loading its content
	/// - Parameter url: filepath in filesystem,
	/// - Parameter writeStrategy: Strategy for writing to the filesystem
	internal init(url: URL, writeStrategy: WriteStrategyType = .batch) throws {
		guard url.isFileURL else {
			throw PrefsError.invalidUrl
		}
		
		self.url = url
		self.strategy = writeStrategy.createStrategy()
		self.repository = EncryptedFileRepository(url: url)
		
		tryLoadContent()
	}
	
	private func tryLoadContent() {
		guard FileManager.default.fileExists(atPath: url.path) else { return }
		
		do {
			try reload()
		} catch {
			logger.error("Failed to load file '\(self.url, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
	
	/// Loads the content from the target file, into memory
	/// - Throws: When fails to load. Usually when the file does not exists, could not be decrypted or could not be decoded
	public func reload() throws {
		dict = try repository.read()
	}
	
	/// Get a string value from `Prefs` by given key, or nil if its not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: String value of the given key, or nil if its not found
	public func string(key: Key) -> String? { dict[key.value] }
	
	/// Get an int value from `Prefs` by given key, or nil if not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: Int value of the given key, or nil if its not found
	public func int(key: Key) -> Int? { codable(key: key) }
	
	/// Gets a boolean value from `Prefs` by given key, or uses the fallback value if not found
	/// - Parameters:
	///   - key: The wanted key, linked to the wanted value
	///   - fallback: The default value in case the key is not found
	/// - Returns: Bool value of the given key, or the fallback if its not found.
	public func bool(key: Key, fallback: Bool = false) -> Bool { codable(key: key) ?? fallback }
	
	/// Get a date value from `Prefs` by given key, or nil if not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Returns: Date value of the given key, or nil if not found
	public func date(key: Key) -> Date? { codable(key: key) }
	
	/// Get a Decodable value from `Prefs` by given key, or nil if not found
	/// - Parameter key: The wanted key, linked to the wanted value
	/// - Parameter type: The resulting `Decodable` type. Defaults to the inferred type from the caller.
	/// - Returns: Some Decodable, or nil if key is not found
	public func codable<Content: Decodable>(key: Key, as type: Content.Type = Content.self) -> Content? {
		guard let str = dict[key.value] else { return nil }
		if Content.self == String.self { return str as? Content }
		
		let data = Data(str.utf8)
		return try? JSONDecoder().decode(Content.self, from: data)
	}
	
	/// check if values exist for given keys.
	/// - Parameter keys: pref keys to check
	/// - Returns: true if all of the keys exist, otherwise false
	public func contains(_ keys: Key...) -> Bool {
		keys.allSatisfy { dict[$0.value] != nil }
	}
	
	/// Create new editor instance, to start editing the Prefs
	/// - Returns: new Editor isntance, referencing to this Prefs instance
	public func edit() -> Editor { Editor(prefs: self) }
	
	/// write commit and alert all subscribers that changes were made.
	/// - Parameter commit: The commited changes to be made.
	internal func apply(_ commit: Commit) {
		strategy.commit(commit, to: self)
		changeSubject.send(self)
	}
	
	/// A Combine publisher that publishes whenever the prefs commit changes.
	public var publisher: AnyPublisher<Prefs, Never> {
		changeSubject.eraseToAnyPublisher()
	}
}
