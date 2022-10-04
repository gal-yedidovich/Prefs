//
//  PrefsValue.swift
//  
//
//  Created by Gal Yedidovich on 01/10/2022.
//

import SwiftUI
import Combine

@propertyWrapper
public struct PrefsValue<Content: Codable & Equatable, Value: Codable & Equatable>: DynamicProperty {
	private let key: WritableKeyPath<Content, Value>
	private let prefs: Prefs<Content>
	@StateObject private var prefsObserver: PublisherObservableObject
	
	nonisolated public init(_ prefs: Prefs<Content>, _ key: WritableKeyPath<Content, Value>) {
		self.prefs = prefs
		self.key = key
		let publisher = prefs.publisher
			.map { $0[keyPath: key] }
			.removeDuplicates()
		_prefsObserver = StateObject(wrappedValue: PublisherObservableObject(publisher: publisher))
	}
	
	public var wrappedValue: Value {
		get { prefs[key] }
		nonmutating set { prefs[key] = newValue }
	}
	
	public var projectedValue: Binding<Value> {
		Binding (
			get: { self.wrappedValue },
			set: { self.wrappedValue = $0 }
		)
	}
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
