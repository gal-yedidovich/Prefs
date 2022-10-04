//
//  Repository.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation
import SimpleEncryptor

struct EncryptedFileRepository<Content: Codable> {
	let url: URL
	let encryptor = SimpleEncryptor(type: .gcm)
	
	func read() throws -> Content {
		let encData = try Data(contentsOf: url)
		let data = try encryptor.decrypt(data: encData)
		let content = try JSONDecoder().decode(Content.self, from: data)
		return content
	}
	
	func write(_ content: Content) throws {
		let data = try JSONEncoder().encode(content)
		let encData = try encryptor.encrypt(data: data)
		try encData.write(to: url, options: [.atomic])
	}
}
