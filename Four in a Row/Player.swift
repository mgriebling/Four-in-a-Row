//
//  Player.swift
//  Project34
//
//  Created by Michael Griebling on 13.11.2026.
//

import SwiftUI
import GameplayKit

class Player: NSObject, GKGameModelPlayer {
	var chip: ChipColor
	var color: Color
	var name: String
	var playerId: Int
	var opponent: Player {
		if chip == .blue {
			Player.allPlayers[1]
		} else {
			Player.allPlayers[0]
		}
	}
	
	init(chip: ChipColor) {
		self.chip = chip
		self.color = chip.color
		self.name = chip.name
		self.playerId = chip.rawValue
		super.init()
	}
	
	static var allPlayers = [Player(chip: .blue), Player(chip: .yellow)]
}
