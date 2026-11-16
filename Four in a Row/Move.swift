//
//  Move.swift
//  Project34
//
//  Created by Michael Griebling on 14.11.2026.
//

import GameplayKit

class Move: NSObject, GKGameModelUpdate {
	var value = 0
	var column: Int
	
	init(column: Int) {
		self.column = column
	}
}
