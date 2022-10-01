//
//  PrefsValue.swift
//  
//
//  Created by Gal Yedidovich on 01/10/2022.
//

import SwiftUI
import Combine

@propertyWrapper
public struct PrefsValue<Value: Codable>: DynamicProperty {
	private let defaultValue: Value
	private let key: Prefs.Key
	private let prefs: Prefs
	@ObservedObject private var preferencesObserver: PublisherObservableObject
	
	public init(wrappedValue defValue: Value, _ key: Prefs.Key, prefs: Prefs = .standard) {
		self.key = key
		self.prefs = prefs
		self.defaultValue = defValue
		let publisher = prefs.publisher
			.map { _ in () }
			.eraseToAnyPublisher()
		preferencesObserver = .init(publisher: publisher)
	}
	
	public var wrappedValue: Value {
		get { prefs.codable(key: key) ?? defaultValue }
		nonmutating set { prefs.edit().put(key: key, newValue).commit() }
	}
	
	public var projectedValue: Binding<Value> {
		Binding (
			get: { self.wrappedValue },
			set: { self.wrappedValue = $0 }
		)
	}
}

private final class PublisherObservableObject: ObservableObject {
	var subscriber: (any Cancellable)?
	
	init(publisher: some Publisher) {
		subscriber = publisher.sink { _ in } receiveValue: { [weak self] _ in
			self?.objectWillChange.send()
		}
	}
}
