//
//  ChipView.swift
//  Project34
//
//  Created by Michael Griebling on 13.11.2026.
//

import SwiftUI

struct ChipView: View {
	let color: Color
	
    var body: some View {
		Circle()
			.fill(color.gradient)
    }
}

#Preview {
	ChipView(color: .red)
}
