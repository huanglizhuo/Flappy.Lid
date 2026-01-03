import SwiftUI

struct GameView: View {
    @StateObject private var gameEngine = GameViewModel()
    @StateObject private var lidMonitor = LidAngleMonitor()
    @State private var isSettingsPresented = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
//                Image("backgroundImg")
//                    .ignoresSafeArea()
                Color(red: 162/255, green: 211/255, blue: 244/255) // #A2D3F4
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
                    ZStack(alignment: .top) {
                        // Centered Score
                        Text("\(gameEngine.score)")
                            .font(.flappy(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        // Right-aligned Controls
                        HStack {
                            Spacer()
                            
                            // Live Sensor Value (Debug/Feedback)
                            VStack(alignment: .trailing) {
                                Text("ANGLE: \(String(format: "%.1f", lidMonitor.currentAngle))°")
                                    .font(.flappy(size: 16))
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 10)
                            
                            // Settings Button (Visual hint)
                            Button(action: { isSettingsPresented = true }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    Spacer()
                }
                
                // State Overlay
                if gameEngine.gameState == .ready && !isSettingsPresented {
                    VStack(spacing: 20) {
                        Text("FLAPPY LID")
                            .font(.flappy(size: 80))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                        
                        Text("MOVE LID TO JUMP")
                            .font(.flappy(size: 30))
                            .foregroundColor(.white)
                        
                        if gameEngine.isSpaceJumpEnabled {
                            Text("(OR PRESS SPACE)")
                                .font(.flappy(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("SHIFT + SPACE FOR SETTINGS")
                            .font(.flappy(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 20) {
                            Button("SIMPLE MODE") {
                                gameEngine.gameMode = .simple
                                gameEngine.startGame()
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.flappy(size: 16))
                            
                            Button("NORMAL MODE") {
                                gameEngine.gameMode = .normal
                                gameEngine.startGame()
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.flappy(size: 16))
                        }
                    }
                    .background(Color.black.opacity(0.4).cornerRadius(20).padding(-20))
                } else if gameEngine.gameState == .gameOver && !isSettingsPresented {
                    VStack(spacing: 20) {
                        Text("GAME OVER")
                            .font(.flappy(size: 60))
                            .foregroundColor(.red)
                            .shadow(radius: 4)
                        
                        Text("SCORE: \(gameEngine.score)")
                            .font(.flappy(size: 40))
                            .foregroundColor(.white)
                        
                        Button("RESTART") {
                            gameEngine.resetGame()
                        }
                        .font(.flappy(size: 30))
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
