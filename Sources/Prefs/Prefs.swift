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

public class Prefs<Content: Codable & Equatable> {
	internal let queue = DispatchQueue(label: "prefs", qos: .background)
	internal let url: URL
	internal let repository: EncryptedFileRepository<Content>
	internal var content: Content

	private var subscription = Set<AnyCancellable>()
	private let changeSubject = PassthroughSubject<Prefs, Never>()
	
	/// Initialize new Prefs instance with a suite name, and loading its content
	/// - Parameter suite: name of the prefs suite in the filesystem
	public convenience init(suite: String, content: Content) {
		let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let url = dir.appendingPathComponent(suite)
		try! self.init(url: url, content: content)
	}

	/// Initialize new Prefs instance link to a given url and a writing strartegy, and loading its content
	/// - Parameter url: filepath in filesystem,
	/// - Parameter writeStrategy: Strategy for writing to the filesystem
	internal init(url: URL, content: Content) throws {
		guard url.isFileURL else {
			throw PrefsError.invalidUrl
		}
		
		self.url = url
		self.repository = EncryptedFileRepository<Content>(url: url)
		self.content = content
		
		tryLoadContent()
		publisher
			.sink { prefs in prefs.writeContent() }
			.store(in: &subscription)
	}
	
	private func tryLoadContent() {
		guard FileManager.default.fileExists(atPath: url.path) else { return }
		
		do {
			try reload()
		} catch {
			logger.error("Failed to load file '\(self.url, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
	
	private func writeContent() {
		do {
			try repository.write(content)
		}
		catch {
			logger.error("Failed to write to file '\(self.url, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
	
	/// Loads the content from the target file, into memory
	/// - Throws: When fails to load. Usually when the file does not exists, could not be decrypted or could not be decoded
	public func reload() throws {
		content = try repository.read()
	}
	
	public func clear() throws {
		try FileManager.default.removeItem(at: url)
	}
	
	public subscript<Value: Codable>(_ keyPath: WritableKeyPath<Content, Value>) -> Value {
		get { content[keyPath: keyPath] }
		set {
			content[keyPath: keyPath] = newValue
			changeSubject.send(self)
		}
	}
	
	/// A Combine publisher that publishes whenever the prefs commit changes.
	public var publisher: AnyPublisher<Prefs, Never> {
		changeSubject
			.debounce(for: 0.1, scheduler: queue)
			.eraseToAnyPublisher()
	}
}
