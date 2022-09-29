//
//  Repository.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation
import SimpleEncryptor

protocol Repository {
	func read() throws -> PrefsContent

	func write(_ content: PrefsContent) throws
}

struct EncryptedFileRepository: Repository {
	let url: URL
	let encryptor = SimpleEncryptor(type: .gcm)
	
	func read() throws -> PrefsContent {
		let encData = try Data(contentsOf: url)
		let data = try encryptor.decrypt(data: encData)
		let dict = try JSONDecoder().decode(PrefsContent.self, from: data)
		return dict
	}
	
	func write(_ content: PrefsContent) throws {
		let data = try JSONEncoder().encode(content)
		let encData = try encryptor.encrypt(data: data)
		try encData.write(to: url, options: [.atomic])
	}
}
