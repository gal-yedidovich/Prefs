//
//  Repository.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation

protocol Repository {
	func read() throws -> PrefsContent

	func write(_ content: PrefsContent) throws
}

struct ClearFileRepository: Repository {
	let url: URL
	
	func read() throws -> PrefsContent {
		let data = try Data(contentsOf: url)
		let dict = try JSONDecoder().decode(PrefsContent.self, from: data)
		return dict
	}
	
	func write(_ content: PrefsContent) throws {
		let data = try JSONEncoder().encode(content)
		try data.write(to: url)
	}
}

//struct EncryptedRepository: FileRepository {
//	let url: URL
//
//	func read() throws -> [String: String] {
//		let data = try Data(contentsOf: url)
//		let dict = try JSONDecoder().decode([String: String].self, from: data)
//		return dict
//	}
//
//	func write(_ content: [String: String]) throws {
//		let data = try JSONEncoder().encode(content)
//		try data.write(to: url)
//	}
//}
