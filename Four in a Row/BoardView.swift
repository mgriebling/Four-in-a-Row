import SwiftUI
import GameplayKit

struct BoardView: View {
	var board: Board
	var strategist = GKMinmaxStrategist()
	
	@State private var chipPosition: Int = -1
	@State private var stack: Int = -1
	@State private var showingAlert = false
	@State private var disableMoves = false
	@State private var gameOverTitle = ""
	@State private var title = ""
	@State private var playComputer = true
	
	var body: some View {
		ZStack {
			HStack(spacing: 3) {
				ForEach(0..<Board.width, id:\.self) { column in
					BallDropView(board: board, column: column) {
						// tap gesture
						if !disableMoves {
							self.makeMove(in: column)
						}
					}
				}
			}
			.padding(.horizontal)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.onAppear {
				// 3 - pretty good (without random)
				self.strategist.maxLookAheadDepth = 3
				self.strategist.randomSource = nil // GKARC4RandomSource()
				resetBoard()
			}
			.navigationTitle(title)
			.alert(gameOverTitle, isPresented: $showingAlert) {
				Button("Play Again", role: .cancel) {
					resetBoard()
				}
			}
			
			// Busy Indicator overlay
			if disableMoves {
				Color.primary.opacity(0.25)
					.ignoresSafeArea()
				ProgressView("AI is thinking...")
					.padding()
					.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
			}
		}
		.toolbar {
			ToolbarItemGroup(placement: .bottomBar) {
				Button {
					resetBoard()
				} label: {
					Text("New Game")
				}
				Spacer()
				Picker("Opponent:", selection: $playComputer) {
					Text("AI").tag(true)
					Text("Person").tag(false)
				}
				.pickerStyle(.segmented)
			}
		}
	}
	
	func resetBoard() {
		board.reset()
		gameOverTitle = ""
		strategist.gameModel = board
		updateUI()
	}
	
	func updateUI() {
		title = "\(board.currentPlayer.name)'s Turn"
		if board.currentPlayer.chip == .yellow, playComputer {
			startAIMove()
		}
	}
	
	func columnForAIMove() -> Int? {
		if let aiMove = strategist.bestMove(for: board.currentPlayer) as? Move {
			return aiMove.column
		}
		return nil
	}
	
	func makeAIMove(in column: Int) {
		if let _ = board.nextEmptySlot(in: column) {
			board.add(chip: board.currentPlayer.chip, in: column)
			continueGame()
		}
	}
	
	func startAIMove() {
		disableMoves = true  // no player action allowed
		
		DispatchQueue.global().async {
			let strategistTime = CFAbsoluteTimeGetCurrent()
			guard let column = self.columnForAIMove() else { return }
			let delta = CFAbsoluteTimeGetCurrent() - strategistTime
			
			let aiTimeCeiling = 1.0 // seconds
			let delay = aiTimeCeiling - delta
			
			DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
				self.makeAIMove(in: column)
				self.disableMoves = false
			}
		}
	}
	
	func makeMove(in column: Int) {
		if let _ = board.nextEmptySlot(in: column) {
			board.add(chip: board.currentPlayer.chip, in: column)
			continueGame()
		}
	}
	
	func continueGame() {
		if board.isWin(for: board.currentPlayer) {
			gameOverTitle = "\(board.currentPlayer.name) Wins!"
		} else if board.isFull() {
			gameOverTitle = "Draw!"
		}
		
		if !gameOverTitle.isEmpty {
			title = gameOverTitle
			showingAlert = true
			return
		}
		
		board.currentPlayer = board.currentPlayer.opponent
		updateUI()
	}

}

#Preview {
	@Previewable @State var board = Board()
	NavigationStack {
		BoardView(board: board)
	}
}
