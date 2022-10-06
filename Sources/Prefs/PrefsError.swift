//
//  PrefsError.swift
//  
//
//  Created by Gal Yedidovich on 06/10/2022.
//

import Foundation

enum PrefsError: LocalizedError {
	case invalidUrl
	
	var errorDescription: String? {
		switch self {
		case .invalidUrl:
			return "invalid url, must be a local file url"
		}
	}
}
