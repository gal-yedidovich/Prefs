//
//  Dispatcher.swift
//  
//
//  Created by Gal Yedidovich on 04/03/2023.
//

import Foundation
protocol Dispatcher {
	func sync(block: () -> Void)
	func async(delay: Double, block: @escaping () -> Void)
}

struct MockDispatcher: Dispatcher {
	func sync(block: () -> Void) {
		block()
	}
	
	func async(delay: Double, block: @escaping () -> Void) {
		block()
	}
}

struct QueueDispatcher: Dispatcher {
	private let queue: DispatchQueue = DispatchQueue(label: "Prefs", qos: .background)
	
	func sync(block: () -> Void) {
		queue.sync(execute: block)
	}
	
	func async(delay: Double, block: @escaping () -> Void) {
		queue.asyncAfter(deadline: .now() + delay, execute: block)
	}
}
