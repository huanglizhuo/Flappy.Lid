import SwiftUI

struct ContentView: View {
    @StateObject var gameEngine = GameViewModel()
    // We need a shared LidMonitor because both modes use it.
    // Ideally, GameViewModel owns it or it's a separate environment object.
    // In current refactor, GameView creates it. Let's hoist it too.
    @StateObject var lidMonitor = LidAngleMonitor()
    
    var body: some View {
        ZStack {
            switch gameEngine.appMode {
            case .game:
                GameView(gameEngine: gameEngine, lidMonitor: lidMonitor)
            case .keySimulator:
                KeySimulatorView(lidMonitor: lidMonitor)
            case .selecting:
                ModeSelectionView(gameEngine: gameEngine)
            }
        }
        .onAppear {
            // Ensure ViewModel has the monitor
            gameEngine.setLidMonitor(lidMonitor)
        }
    }
}

struct ModeSelectionView: View {
    @ObservedObject var gameEngine: GameViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Text("FLAPPY LID")
                .font(.flappy(size: 80))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            Text("CHOOSE MODE")
                .font(.flappy(size: 30))
                .foregroundColor(.yellow)
            
            HStack(spacing: 40) {
                // Game Mode Button
                Button(action: {
                    withAnimation {
                        gameEngine.appMode = .game
                    }
                }) {
                    VStack {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        Text("GAME")
                            .font(.flappy(size: 30))
                            .foregroundColor(.white)
                    }
                    .frame(width: 200, height: 200)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                .buttonStyle(.plain)
                
                // Key Simulator Button
                Button(action: {
                    withAnimation {
                        gameEngine.appMode = .keySimulator
                    }
                }) {
                    VStack {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        Text("KEY SIM")
                            .font(.flappy(size: 30))
                            .foregroundColor(.white)
                    }
                    .frame(width: 200, height: 200)
                    .background(Color.purple)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
