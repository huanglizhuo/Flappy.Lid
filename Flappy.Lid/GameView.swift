import SwiftUI

struct GameView: View {
    @StateObject private var gameEngine = GameViewModel()
    @StateObject private var lidMonitor = LidAngleMonitor()
    @State private var isSettingsPresented = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.blue.opacity(0.6) // TODO: Replace with Image("Background")
                    .ignoresSafeArea()
                
                // Game Layer
                ZStack {
                    // Pipes
                    ForEach(gameEngine.pipes) { pipe in
                        // Top Pipe
                        PipeView(isTop: true, height: pipe.y - (gameEngine.gameMode.pipeGap/2))
                            .position(x: pipe.x, y: (pipe.y - (gameEngine.gameMode.pipeGap/2)) / 2)
                        
                        // Bottom Pipe
                        let bottomPipeHeight = geometry.size.height - (pipe.y + (gameEngine.gameMode.pipeGap/2))
                        PipeView(isTop: false, height: bottomPipeHeight)
                            .position(x: pipe.x, y: geometry.size.height - (bottomPipeHeight / 2))
                    }
                    
                    // Bird
                    BirdView(rotation: gameEngine.birdRotation)
                        .position(gameEngine.birdPosition)
                    
                    // Ground (Visual)
                    // We can add a scrolling ground here if we track offset
                }
                .blur(radius: isSettingsPresented ? 5 : 0) // Blur when settings open
                
                // UI Layer
                VStack {
                    HStack {
                        Text("Score: \(gameEngine.score)")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Spacer()
                        
                        // Live Sensor Value (Debug/Feedback)
                        VStack(alignment: .trailing) {
                            Text("Angle: \(String(format: "%.1f", lidMonitor.currentAngle))°")
                                .font(.monospacedDigit(.headline)())
                                .foregroundColor(.white)
                            Text("Angle Δ: \(String(format: "%.1f", lidMonitor.currentDelta))")
                                .font(.monospacedDigit(.headline)())
                                .foregroundColor(abs(lidMonitor.currentDelta) > lidMonitor.jumpThreshold ? .green : .white)
                            Text("Mode: \(lidMonitor.triggerMode.rawValue.capitalized)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.trailing, 20)
                        
                        // Settings Button (Visual hint)
                        Button(action: { isSettingsPresented = true }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.title)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    Spacer()
                }
                
                // State Overlay
                if gameEngine.gameState == .ready && !isSettingsPresented {
                    VStack(spacing: 20) {
                        Text("Flappy Lid")
                            .font(.system(size: 50, weight: .heavy))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        
                        Text("Move Lid to Jump")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        if gameEngine.isSpaceJumpEnabled {
                            Text("(or press Space)")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("Shift + Space for Settings")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 20) {
                            Button("Simple Mode") {
                                gameEngine.gameMode = .simple
                                gameEngine.startGame()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Normal Mode") {
                                gameEngine.gameMode = .normal
                                gameEngine.startGame()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .background(Color.black.opacity(0.4).cornerRadius(20).padding(-20))
                } else if gameEngine.gameState == .gameOver && !isSettingsPresented {
                    VStack(spacing: 20) {
                        Text("Game Over")
                            .font(.system(size: 50, weight: .heavy))
                            .foregroundColor(.red)
                            .shadow(radius: 4)
                        
                        Text("Score: \(gameEngine.score)")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Button("Restart") {
                            gameEngine.resetGame()
                        }
                        .font(.title2)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .background(Color.black.opacity(0.4).cornerRadius(20).padding(-20))
                }
                
                // Settings Overlay
                if isSettingsPresented {
                    SettingsView(isPresented: $isSettingsPresented, gameEngine: gameEngine, lidMonitor: lidMonitor)
                }
            }
            .onAppear {
                gameEngine.screenSize = geometry.size
                gameEngine.setLidMonitor(lidMonitor)
                gameEngine.resetGame() // Ensure init pos is correct based on size
            }
            .onChange(of: geometry.size) { newSize in
                gameEngine.screenSize = newSize
            }
            // Keyboard Input (Fallback & Settings)
            .background(
                ZStack {
                    // Jump shortcut
                    Button("") {
                        if !isSettingsPresented && gameEngine.isSpaceJumpEnabled { 
                            gameEngine.jump() 
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .opacity(0)
                    
                    // Settings shortcut
                    Button("") {
                        isSettingsPresented.toggle()
                    }
                    .keyboardShortcut(.space, modifiers: .shift)
                    .opacity(0)
                }
            )
        }
    }
}

#Preview {
    GameView()
}
