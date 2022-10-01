//
//  Key.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation

extension Prefs {
	/// String wrapper for representing a key in a `Prefs` instance.
	public struct Key {
		let value: String
		
		public init(value: String) {
			self.value = value
		}
	}

}
