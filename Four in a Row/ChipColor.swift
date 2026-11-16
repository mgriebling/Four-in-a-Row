//
//  ChipColor.swift
//  Project34
//
//  Created by Michael Griebling on 13.11.2026.
//

import SwiftUI

enum ChipColor: Int {
	case none = 0, blue, yellow
	
	var color: Color {
		switch self {
			case .blue: Color(.systemBlue)
			case .yellow: Color(.systemYellow)
			default: Color.clear
		}
	}
	
	var name: String {
		switch self {
			case .blue: "Blue"
			case .yellow: "Yellow"
			default: ""
		}
	}
}
