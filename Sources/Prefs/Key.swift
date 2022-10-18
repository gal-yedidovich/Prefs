//
//  Key.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation

public typealias PrefsValueType = Codable & Equatable
public protocol PrefsKeyProtocol {
	associatedtype ValueType: PrefsValueType
	
	var value: String { get }
}

public extension Prefs {
	struct Key<V: PrefsValueType>: PrefsKeyProtocol {
		public typealias ValueType = V
		
		public let value: String
		
		public init(string value: String) {
			self.value = value
		}
	}
}
