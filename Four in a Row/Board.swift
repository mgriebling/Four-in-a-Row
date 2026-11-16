//
//  Board.swift
//  Project34
//
//  Created by Michael Griebling on 13.11.2026.
//
import SwiftUI
import GameplayKit

struct Position: Codable, Hashable, Equatable {
	var row: Int
	var col: Int
	
	/// convenience method
	func inc(_ row: Int = 0, col: Int = 0) -> Position {
		Position(row: self.row + row, col: self.col + col)
	}
}

typealias NavigationFunction = (inout Position) -> ()

@Observable
class Board: NSObject {
	
	static var width = 7
	static var height = 6
	
	var slots = [ChipColor]()
	var currentPlayer: Player
	var itemsInARow: Int
	
	init(itemsInARow: Int = 4) {
		self.currentPlayer = Player.allPlayers[0]
		self.itemsInARow = itemsInARow
		super.init()
		reset()
	}
	
	func reset() {
		slots = Array(repeating: ChipColor.none, count: Self.height * Self.width)
		currentPlayer = Player.allPlayers[0]
	}
	
	func isFull() -> Bool {
		slots.count { $0 == .none } == 0
	}
	
	func squaresMatch(initialChip: ChipColor, pos: Position, moveX: Int, moveY: Int) -> Bool {
		// bail out early if we can't win from here
		if pos.inc(moveY * 3).row 	   <  0 		   { return false }
		if pos.inc(moveY * 3).row 	   >= Board.height { return false }
		if pos.inc(col: moveX * 3).col <  0 		   { return false }
		if pos.inc(col: moveX * 3).col >= Board.width  { return false }
		
		// now we need to check all positions
		for items in 0..<itemsInARow {
			if chip(in: pos.inc(moveY*items, col: moveX*items))	!= initialChip { return false }
		}
		return true
	}
	
	func isWin(for player: GKGameModelPlayer) -> Bool {
		let chip = (player as! Player).chip
		
		for row in 0..<Board.height {
			for col in 0..<Board.width {
				let pos = Position(row: row, col: col)
				if squaresMatch(initialChip: chip, pos: pos, moveX: 1, moveY: 0) {
					return true
				} else if squaresMatch(initialChip: chip, pos: pos, moveX: 0, moveY: 1) {
					return true
				} else if squaresMatch(initialChip: chip, pos: pos, moveX: 1, moveY: 1) {
					return true
				} else if squaresMatch(initialChip: chip, pos: pos, moveX: 1, moveY: -1) {
					return true
				}
			}
		}
		return false
	}
	
	func chip(in pos: Position) -> ChipColor {
		slots[pos.row + pos.col * Self.height]
	}
	
	func set(chip: ChipColor, in pos: Position) {
		slots[pos.row + pos.col * Self.height] = chip
	}
	
	func nextEmptySlot(in column: Int) -> Int? {
		// need to check in reverse order so chips are stacked from bottom to top
		for row in (0..<Board.height).reversed() {
			if chip(in: Position(row: row, col: column)) == .none {
				return row
			}
		}
		return nil
	}
	
	func canMove(in column: Int) -> Bool {
		nextEmptySlot(in: column) != nil
	}
	
	func add(chip: ChipColor, in column: Int) {
		if let row = nextEmptySlot(in: column) {
			set(chip: chip, in: Position(row: row, col: column))
		}
	}
}

extension Board: GKGameModel {
	/// Compliance with GKGameModel
	///
	var players: [any GKGameModelPlayer]? {
		Player.allPlayers
	}
	
	var activePlayer: (any GKGameModelPlayer)? {
		currentPlayer
	}

	func setGameModel(_ gameModel: any GKGameModel) {
		if let board = gameModel as? Board {
			slots = board.slots
			currentPlayer = board.currentPlayer
		}
	}
	
	func gameModelUpdates(for player: any GKGameModelPlayer) -> [any GKGameModelUpdate]? {
		if let playerObject = player as? Player {
			if isWin(for: playerObject) || isWin(for: playerObject.opponent) {
				return nil
			}
			
			var moves = [Move]()
			for column in 0..<Self.width {
				if canMove(in: column) {
					moves.append(Move(column: column))
				}
			}
			return moves
		}
		return nil
	}
	
	func apply(_ gameModelUpdate: any GKGameModelUpdate) {
		if let move = gameModelUpdate as? Move {
			add(chip: currentPlayer.chip, in: move.column)
			currentPlayer = currentPlayer.opponent
		}
	}
	
	func score(for player: any GKGameModelPlayer) -> Int {
		if let playerObject = player as? Player {
			if isWin(for: playerObject) {
				return 1000
			} else if isWin(for: playerObject.opponent) {
				return -1000
			}
		}
		return 0
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		let copy = Board()
		copy.setGameModel(self)
		return copy
	}
}
