//
//  PrefKey.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation

/// String wrapper for representing a key in a `Prefs` instance.
public struct PrefKey {
	let value: String
	
	public init(value: String) {
		self.value = value
	}
}
