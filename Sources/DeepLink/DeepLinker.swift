//
//  DeepLinker.swift
//  AppwiseCore
//
//  Created by David Jennes on 03/11/17.
//  Copyright © 2017 Appwise. All rights reserved.
//

import Foundation
import UIKit

/// A deep link stack item, for connecting an identifier to a matchable item.
public struct DeepLinkStackItem {
	/// The path component
	public let path: String
	weak var matchable: DeepLinkMatchable?
}

/// The general subsystem for performing (and keep track of) deep linking.
public final class DeepLinker {
	typealias Stack = [DeepLinkStackItem]

	/// This is a singleton
	public static let shared = DeepLinker()

	private var stack: Stack = []
	private var scheduledRoute: (path: [String], animated: Bool)?
	private init() {
	}

	/// Register a deep link stack item (a view controller) for a specific path component
	///
	/// Note: an internal behaviour will be added to the view controller, to keep track of
	/// when it's visible or not.
	///
	/// - parameter matchable: The view controller to register and keep track of.
	/// - parameter path: The path component this view controller represents.
	public func register(_ matchable: DeepLinkMatchable & UIViewController, for path: String) {
		if matchable is UITabBarController {
			addToStack(matchable, for: path)
		} else {
			let behaviour = DeepLinkMonitorBehaviour(matchable, for: path)
			matchable.add(behaviours: [behaviour])
		}
	}

	func addToStack(_ matchable: DeepLinkMatchable, for path: String) {
		guard !stack.compactMap({ $0.matchable }).contains(where: { $0.isEqual(matchable) }) else { return }

		stack = cleanupWeakReferences()
		stack.append(DeepLinkStackItem(path: path, matchable: matchable))

		if let route = scheduledRoute, navigate(to: route.path, animated: route.animated) {
			scheduledRoute = nil
		}
	}

	func removeFromStack(_ matchable: DeepLinkMatchable) {
		stack = cleanupWeakReferences().filter { !($0.matchable?.isEqual(matchable) ?? false) }
	}

	/// Try to open a deep link (a path)
	///
	/// - parameter path: The path to open, for example: "/root/some/thing/here"
	/// - parameter animated: Whether this should be animated or not.
	///
	/// - returns: True if successful. Otherwise, the link will be kept and the system will
	/// try to open it at a later time (unless you try to open a new link).
	@discardableResult
	public func open(path: String, animated: Bool) -> Bool {
		let route = path.split(separator: "/").map { String($0) }
		guard !route.isEmpty else { return false }

		if navigate(to: route, animated: animated) {
			return true
		} else {
			scheduledRoute = (path: route, animated: animated)
			return false
		}
	}

	private func cleanupWeakReferences() -> Stack {
		return stack.filter { item in
			item.matchable != nil
		}
	}
}

// MARK: - Navigation

extension DeepLinker {
	private func navigate(to route: [String], animated: Bool) -> Bool {
		let stack = cleanupWeakReferences()

		// if we don't have a stack, store the request for later
		guard let firstDifferent = findFirstDifferentIndex(stack: stack, route: route) else {
			return false
		}

		// if common < stack -> dismiss stack items
		guard let destroyedStack = destroyStack(existing: stack, to: firstDifferent, animated: animated) else {
			return false
		}

		// if common > stack -> build stack up
		let lastCommon = stack.index(before: firstDifferent)
		guard let builtStack = buildUpStack(existing: destroyedStack, for: route, lastCommon: lastCommon, animated: animated) else {
			return false
		}

		self.stack = builtStack
		return true
	}

	private func findFirstDifferentIndex(stack: Stack, route: [String]) -> Array<String>.Index? {
		if let index = Array(zip(route, stack)).index(where: { $0 != $1.path }),
			index > stack.startIndex {
			return index
		} else {
			return min(route.endIndex, stack.endIndex)
		}
	}

	private func destroyStack(existing: Stack, to index: Int, animated: Bool) -> Stack? {
		var stack = existing
		let beforeIndex = stack.index(before: index)

		while stack.count > index {
			let start = stack.index(before: stack.index(before: stack.endIndex))
			guard start >= beforeIndex else { return nil }

			var dismissedSomething = false
			for offset in (beforeIndex...start).reversed() {
				guard let parent = stack[offset].matchable else { continue }
				let after = stack.index(after: offset)

				if parent.dismiss(items: Array(stack.suffix(from: after)), animated: animated) {
					stack = Array(stack.dropLast(stack.endIndex - after))
					dismissedSomething = true
					break
				}
			}

			if !dismissedSomething {
				return nil
			}
		}

		return stack
	}

	private func buildUpStack(existing: Stack, for route: [String], lastCommon: Int, animated: Bool) -> Stack? {
		var stack = existing

		for index in lastCommon..<route.index(before: route.endIndex) {
			guard let item = stack[index].matchable else { return nil }
			let next = route.index(after: index)

			if let matchable = item.present(link: Array(route.suffix(from: next)), animated: animated) {
				stack.append(DeepLinkStackItem(path: String(route[next]), matchable: matchable))
			} else {
				return nil
			}
		}

		return stack
	}
}
