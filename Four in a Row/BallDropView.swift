//
//  BallDropView.swift
//  Four in a Row
//
//  Created by Michael Griebling on 15.11.2026.
//

import SwiftUI

struct BallDropView: View {
	let board: Board
	let column: Int
	let tap: () -> ()
	
	static let height: CGFloat = 400
	static let containerWallWidth: CGFloat = 4
	
	@State private var viewHeight = height
	@State private var scale: CGFloat = 1
	@State private var offset: CGFloat = 0

	var body: some View {
		let containerHeight: CGFloat = 380
		let ballWidth: CGFloat = 64
		let orgScale = ballWidth/containerHeight
		let initialBallHeight = -500.0 * scale
		
		VStack(spacing: 0) {
			ForEach(0..<Board.height, id:\.self) { row in
				let chip = board.chip(in: Position(row: row, col: column))
				let drop = chip != ChipColor.none
				ChipView(color: chip.color)
					.aspectRatio(1, contentMode: .fit)
					.offset(y: drop ? 0 : initialBallHeight)
					.animation(.easeIn(duration: 0.5), value: drop)
			}
		}
		.contentShape(TestTubeShape())
		.onTapGesture(perform: tap)
		.overlay {
			TestTubeShape()
				.stroke(Color(.systemGray), lineWidth: Self.containerWallWidth)
				.aspectRatio(orgScale, contentMode: .fit)
				.onGeometryChange(for: CGSize.self) { proxy in
					proxy.size
				} action: { newSize in
					viewHeight = newSize.height
					scale = viewHeight / Self.height
				}
		}
	}
}

struct TestTubeShape: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		let radius = rect.width / 2
		
		// 1. Start at top-left
		path.move(to: CGPoint(x: rect.minX, y: rect.minY))
		
		// 2. Line down to the start of the bottom-left curve
		path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
		
		// 3. Semicircular bowl across the bottom
		path.addArc(
			center: CGPoint(x: rect.midX, y: rect.maxY - radius),
			radius: radius,
			startAngle: .degrees(180),
			endAngle: .degrees(0),
			clockwise: true // Draws downward through 90° (bottom)
		)
		
		// 4. Line up to top-right (leave open by omitting closeSubpath)
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
		return path
	}
}


#Preview {
	@Previewable @State var board = Board()
	let column = 0
	BallDropView(board: board, column: column) {
		if let _ = board.nextEmptySlot(in: column) {
			board.add(chip: board.currentPlayer.chip, in: column)
		}
	}
}
