//
//  BatchCommitter.swift
//  
//
//  Created by Gal Yedidovich on 27/09/2022.
//

import Foundation

internal struct Commit {
	let changes: [String: String?]
	let clearFlag: Bool
}

internal class BatchCommitter {
	private var triggered = false

	func commit(_ commit: Commit, to prefs: Prefs) {
		prefs.dispatcher.sync {
			prefs.assign(commit)
			if triggered { return }

			triggered = true
			prefs.dispatcher.async(delay: 0.1) { [weak self, weak prefs] in
				guard let self, let prefs else { return }

				self.triggered = false
				prefs.writeOrDelete()
			}
		}
	}
}

//MARK: - Helper functions
fileprivate extension Prefs {
	/// Assigns commit changes on the prefs inner dictionary.
	///
	/// This method does not write the changes to the disk.
	/// - Parameters:
	///   - commit: The changes to apply
	///   - prefs: Target `prefs` instance
	func assign(_ commit: Commit) {
		if commit.clearFlag { dict = [:] }
		
		for (key, value) in commit.changes {
			if value == nil { dict.removeValue(forKey: key) }
			else { dict[key] = value }
		}
	}
	
	func writeOrDelete() {
		if dict.isEmpty { delete() }
		else { write() }
	}
	
	func write() {
		do {
			try repository.write(dict)
			logger.debug("Updated file: '\(self.url, privacy: .private(mask: .hash))'")
		} catch {
			logger.error("Failed to write commit into file '\(self.url, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
	
	func delete() {
		do {
			try FileManager.default.removeItem(at: url)
			logger.debug("Deleted file: '\(self.url, privacy: .private(mask: .hash))'")
		} catch {
			logger.error("Failed to delete file '\(self.url, privacy: .private(mask: .hash))', error: \(error.localizedDescription, privacy: .sensitive(mask: .hash))")
		}
	}
}
