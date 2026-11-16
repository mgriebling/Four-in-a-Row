import SwiftUI

@main struct FourInARow: App {
	@State private var board = Board()
	
    var body: some Scene {
        WindowGroup {
			NavigationStack {
				BoardView(board: board)
			}
        }
    }
}
