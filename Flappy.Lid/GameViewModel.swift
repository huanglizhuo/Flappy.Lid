import SwiftUI
import Combine

enum GameState {
    case ready
    case playing
    case gameOver
}

enum GameMode: String {
    case simple
    case normal
    
    var pipeGap: CGFloat {
        switch self {
        case .simple: return 250 // Easier gap
        case .normal: return 160 // Standard/Harder gap
        }
    }
}

struct PipeModel: Identifiable {
    let id = UUID()
    var x: CGFloat
    // y represents the center of the gap, OR top of the bottom pipe? 
    // Let's us 'y' as the vertical center of the GAP.
    var y: CGFloat 
    var isPassed: Bool = false
}

class GameViewModel: ObservableObject {
    @Published var birdPosition: CGPoint = .zero
    @Published var birdVelocity: CGFloat = 0.0
    @Published var birdRotation: Double = 0.0
    
    @Published var pipes: [PipeModel] = []
    @Published var score: Int = 0
    @Published var gameState: GameState = .ready
    @Published var gameMode: GameMode {
        didSet {
            UserDefaults.standard.set(gameMode.rawValue, forKey: "gameMode")
        }
    }
    @Published var isSpaceJumpEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSpaceJumpEnabled, forKey: "isSpaceJumpEnabled")
        }
    }
    
    // Physics Constants
    private let gravity: CGFloat = 0.6
    private let jumpImpulse: CGFloat = -10.0
    private let pipeSpeed: CGFloat = 3.0
    private let pipeSpawnInterval: CGFloat = 300.0 // Points between pipes? Or time? 
    // Let's spawn based on distance traveled or time. Distance is easier for consistent gap.
    private var lastPipeSpawnX: CGFloat = 0.0
    private let pipeSpacing: CGFloat = 200.0
    
    // Screen Bounds (Will be updated from View)
    var screenSize: CGSize = .zero
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // Dependencies
    var lidMonitor: LidAngleMonitor?
    
    init() {
        // Load GameMode
        let savedMode = UserDefaults.standard.string(forKey: "gameMode") ?? "normal"
        self.gameMode = GameMode(rawValue: savedMode) ?? .normal
        
        // Load Space Jump Setting (Default to true for accessibility/testing)
        self.isSpaceJumpEnabled = UserDefaults.standard.object(forKey: "isSpaceJumpEnabled") as? Bool ?? true
        
        resetGame()
    }
    
    func setLidMonitor(_ monitor: LidAngleMonitor) {
        self.lidMonitor = monitor
        monitor.$jumpTriggered
            .sink { [weak self] triggered in
                if triggered {
                    self?.jump()
                }
            }
            .store(in: &cancellables)
    }
    
    func startGame() {
        resetGame()
        gameState = .playing
        lastPipeSpawnX = screenSize.width
        
        // Start Game Loop
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.gameLoop()
        }
    }
    
    func resetGame() {
        gameState = .ready
        score = 0
        birdPosition = CGPoint(x: 100, y: 300) // Initial pos
        birdVelocity = 0
        birdRotation = 0
        pipes.removeAll()
        timer?.invalidate()
    }
    
    func jump() {
        guard gameState == .playing else {
            if gameState == .ready || gameState == .gameOver {
                startGame()
            }
            return
        }
        birdVelocity = jumpImpulse
    }
    
    private func gameLoop() {
        guard gameState == .playing else { return }
        
        // 1. Update Bird Physics
        birdVelocity += gravity
        birdPosition.y += birdVelocity
        
        // Rotation (Visual)
        // If rising, tilt up. If falling, tilt down.
        let targetRotation = birdVelocity < 0 ? -30.0 : 90.0
        // rudimentary lerp or just set it for now? 
        // Flappy bird snaps up, rotates down slowly.
        if birdVelocity < 0 {
            birdRotation = -30
        } else {
            birdRotation += 3.0 // Rotate down slowly
            if birdRotation > 90 { birdRotation = 90 }
        }
        
        // 2. Move Pipes
        for i in indices(pipes) {
            pipes[i].x -= pipeSpeed
        }
        
        // 3. Spawning Pipes
        // If last pipe is far enough, spawn new one
        // Or if pipes is empty
        if pipes.isEmpty || (lastPipeSpawnX - pipes.last!.x > pipeSpacing) {
            spawnPipe()
        }
        
        // 4. Remove off-screen pipes
        pipes.removeAll { $0.x < -100 }
        
        // 5. Collision Detection
        checkCollisions()
    }
    
    private func spawnPipe() {
        // Random Gap Height
        // Screen height e.g. 600. Gap center should verify margins.
        let margin: CGFloat = 100
        let minY = margin + (gameMode.pipeGap / 2)
        let maxY = screenSize.height - margin - (gameMode.pipeGap / 2)
        
        let randomY = CGFloat.random(in: minY...maxY)
        
        let newPipe = PipeModel(x: screenSize.width + 50, y: randomY)
        pipes.append(newPipe)
        lastPipeSpawnX = newPipe.x // Not strictly needed if we check pipes.last
    }
    
    private func checkCollisions() {
        // Bird Rect
        // let's assume bird is 40x40
        let birdRect = CGRect(x: birdPosition.x - 20, y: birdPosition.y - 20, width: 40, height: 40)
        
        // Ground / Ceiling
        if birdPosition.y < 0 || birdPosition.y > screenSize.height {
            gameOver()
            return
        }
        
        let pipeWidth: CGFloat = 52
        
        for i in indices(pipes) {
            let pipe = pipes[i]
            let gapHalf = gameMode.pipeGap / 2
            
            // Top Pipe Rect
            // Top pipe goes from y=0 down to (gapCenter - gapHalf)
            let topPipeRect = CGRect(x: pipe.x - pipeWidth/2, y: 0, width: pipeWidth, height: pipe.y - gapHalf)
            
            // Bottom Pipe Rect
            // Bottom pipe goes from (gapCenter + gapHalf) to height
            let bottomPipeRect = CGRect(x: pipe.x - pipeWidth/2, y: pipe.y + gapHalf, width: pipeWidth, height: screenSize.height - (pipe.y + gapHalf))
            
            if birdRect.intersects(topPipeRect) || birdRect.intersects(bottomPipeRect) {
                gameOver()
                return
            }
            
            // Scoring
            if !pipe.isPassed && pipe.x < birdPosition.x {
                pipes[i].isPassed = true
                score += 1
            }
        }
    }
    
    private func gameOver() {
        gameState = .gameOver
        timer?.invalidate()
    }
    
    // Helper for indices to avoid copy-on-write issues in loops if needed, though 'indices(pipes)' is safer.
    private func indices(_ collection: [PipeModel]) -> Range<Int> {
        return 0..<collection.count
    }
}
