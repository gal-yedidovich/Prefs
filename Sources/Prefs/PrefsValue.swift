//
//  PrefsValue.swift
//  
//
//  Created by Gal Yedidovich on 01/10/2022.
//

import SwiftUI
import Combine

@propertyWrapper
public struct PrefsValue<Value: Codable & Equatable>: DynamicProperty {
	private let defaultValue: Value
	private let key: Prefs.Key
	private let prefs: Prefs
	@StateObject private var prefsObserver: PublisherObservableObject
	
	nonisolated public init(wrappedValue defValue: Value, _ key: Prefs.Key, prefs: Prefs = .standard) {
		self.key = key
		self.prefs = prefs
		self.defaultValue = defValue
		let publisher = prefs.publisher
			.map { prefs in prefs.codable(key: key, as: Value.self) }
			.removeDuplicates()
		_prefsObserver = StateObject(wrappedValue: PublisherObservableObject(publisher: publisher))
	}
	
	public var wrappedValue: Value {
		get { prefs.codable(key: key) ?? defaultValue }
		nonmutating set {
			if let optional = newValue as? AnyOptional, optional.isNil {
				prefs.edit().remove(key: key).commit()
			} else {
				prefs.edit().put(key: key, newValue).commit()
			}
		}
	}
	
	public var projectedValue: Binding<Value> {
		Binding (
			get: { self.wrappedValue },
			set: { self.wrappedValue = $0 }
		)
	}
}

//MARK: - Nil values
public extension PrefsValue where Value: ExpressibleByNilLiteral {
	init(_ key: Prefs.Key, prefs: Prefs = .standard) {
		self.init(wrappedValue: nil, key, prefs: prefs)
	}
}

private protocol AnyOptional {
	var isNil: Bool { get }
}

extension Optional: AnyOptional {
	var isNil: Bool { self == nil }
}

//MARK: - Publshing UI updates
private final class PublisherObservableObject: ObservableObject {
	var subscriber: (any Cancellable)?
	
	init<Pub: Publisher>(publisher: Pub) where Pub.Failure == Never {
		subscriber = publisher.sink { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
}
