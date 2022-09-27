//
//  Repository.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation

protocol Repository {
	func read() throws -> [String: String]

	func write(_ content: [String: String]) throws
}

class MemoryRepository: Repository {
	var dict: [String: String]
	
	init(dict: [String : String] = [:]) {
		self.dict = dict
	}
	
	func read() throws -> [String: String] {
		return dict
	}
	
	func write(_ content: [String: String]) throws {
		self.dict = content
	}
}

struct ClearFileRepository: Repository {
	let url: URL
	
	func read() throws -> [String: String] {
		let data = try Data(contentsOf: url)
		let dict = try JSONDecoder().decode([String: String].self, from: data)
		return dict
	}
	
	func write(_ content: [String: String]) throws {
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
