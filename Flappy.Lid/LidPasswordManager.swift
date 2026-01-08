import Foundation
import Combine
import SwiftUI
import ApplicationServices

enum LidPasswordState {
    case idle       // Angle > Threshold
    case monitoring // Angle < Threshold, waiting for gestures
    case success    // Triggered, typing
}

class LidPasswordManager: ObservableObject {
    static let shared = LidPasswordManager()
    
    // Configuration
    @Published var maxActivationAngle: Double {
        didSet { UserDefaults.standard.set(maxActivationAngle, forKey: "lidPass_maxAngle") }
    }
    @Published var targetPassword: String {
        didSet {
            // Enforce Printable ASCII only (32-126)
            let filtered = targetPassword.filter { char in
                guard let ascii = char.asciiValue else { return false }
                return ascii >= 32 && ascii <= 126
            }
            if filtered != targetPassword {
                targetPassword = filtered
            }
            UserDefaults.standard.set(targetPassword, forKey: "lidPass_password")
        }
    }
    
    // Runtime State
    @Published var state: LidPasswordState = .idle
    @Published var openCount: Int = 0
    
    private var lastAngle: Double = 0.0
    private var cancellables = Set<AnyCancellable>()
    
    // Logic Buffers
    private var gestureTimestamps: [Date] = []
    
    // Constants
    private let triggerDelta: Double = 2.0
    private let timeWindow: TimeInterval = 3.0
    
    // Configurable
    @Published var requiredCount: Int {
        didSet { UserDefaults.standard.set(requiredCount, forKey: "lidPass_requiredCount") }
    }
    @Published var isAutoEnterEnabled: Bool {
        didSet { UserDefaults.standard.set(isAutoEnterEnabled, forKey: "lidPass_autoEnter") }
    }
    
    init() {
        let savedAngle = UserDefaults.standard.double(forKey: "lidPass_maxAngle")
        self.maxActivationAngle = savedAngle == 0 ? 30.0 : savedAngle
        self.targetPassword = UserDefaults.standard.string(forKey: "lidPass_password") ?? ""
        
        // Default requiredCount to 4 ("more than 3 times as default" interpreted as >3, so 4 is safe default, logic handles 0)
        let savedCount = UserDefaults.standard.integer(forKey: "lidPass_requiredCount")
        self.requiredCount = savedCount == 0 ? 4 : savedCount
        
        self.isAutoEnterEnabled = UserDefaults.standard.bool(forKey: "lidPass_autoEnter") // Defaults to false
    } 
    
    func startMonitoring(lidMonitor: LidAngleMonitor) {
        stopMonitoring() // Clear previous subscriptions
        
        lidMonitor.$currentAngle
            .sink { [weak self] angle in
                self?.processAngleUpdate(angle)
            }
            .store(in: &cancellables)
    }
    
    func stopMonitoring() {
        cancellables.removeAll()
        state = .idle
        resetLogic()
    }
    
    private func processAngleUpdate(_ currentAngle: Double) {
        let delta = currentAngle - lastAngle
        lastAngle = currentAngle
        
        // 1. Check constraints
        if currentAngle > maxActivationAngle {
            if state != .idle {
                resetLogic()
                state = .idle
            }
            return
        } else {
            if state == .idle {
                state = .monitoring
            }
        }
        
        guard state == .monitoring else { return }
        
        // 2. Detect Positive Delta (Open)
        if delta > triggerDelta {
            registerGesture()
        }
    }
    
    private func registerGesture() {
        let now = Date()
        
        // Prune old gestures
        gestureTimestamps = gestureTimestamps.filter { now.timeIntervalSince($0) < timeWindow }
        
        // Add new one (Debounce slightly to avoid one big move counting as multiple? 
        // Logic says "close and open lid 3 times", so we assume significant motion.
        // We'll add a small debounce of 0.2s to prevent jitter counting)
        if let last = gestureTimestamps.last, now.timeIntervalSince(last) < 0.2 {
            return
        }
        
        gestureTimestamps.append(now)
        openCount = gestureTimestamps.count
        triggerFeedback(type: .generic)
        
        // Check Trigger
        if gestureTimestamps.count >= requiredCount {
            performUnlock()
            resetLogic() // Reset count immediately so we don't double trigger
        }
    }
    
    private func resetLogic() {
        gestureTimestamps.removeAll()
        openCount = 0
    }

    // Updated performUnlock to handle modifiers
    private func performUnlock() {
        state = .success
        triggerFeedback(type: .success)
        
        guard !targetPassword.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.state = .monitoring
            }
            return
        }
        
        let passwordToType = targetPassword
        let autoEnter = isAutoEnterEnabled
        
        DispatchQueue.global().async {
            // 1. Switch to ASCII Input Source (Safe IME Bypass)
            let switched = InputSourceManager.shared.switchToAsciiCapableSource()
            if switched { Thread.sleep(forTimeInterval: 0.1) } // Small delay for system switch
            
            for char in passwordToType {
                if let (code, needsShift) = self.keyCode(for: char) {
                    if needsShift {
                        // Hold Shift (56 = Left Shift)
                        KeySimulator.shared.simulateSpecificKey(56, downOnly: true)
                        Thread.sleep(forTimeInterval: 0.05)
                    }
                    
                    KeySimulator.shared.simulateSpecificKey(code)
                    
                    if needsShift {
                        // Release Shift
                        KeySimulator.shared.simulateSpecificKey(56, upOnly: true)
                    }
                    
                    Thread.sleep(forTimeInterval: 0.05)
                }
            }
            
            // Auto Enter
            if autoEnter {
                KeySimulator.shared.simulateSpecificKey(36)
            }
            
            // 2. Restore Input Source
            if switched {
                Thread.sleep(forTimeInterval: 0.1)
                InputSourceManager.shared.restorePreviousSource()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Unlock Sequence Complete")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.state = .monitoring
        }
    }
    
    // Returns (KeyCode, NeedsShift)
    private func keyCode(for char: Character) -> (CGKeyCode, Bool)? {
        guard let ascii = char.asciiValue else { return nil }
        
        // Basic Check
        if ascii < 32 || ascii > 126 { return nil }
        
        // Special mapping for common symbols
        switch char {
        case "a"..."z": return (keyCodeForLower(char), false)
        case "A"..."Z": return (keyCodeForLower(Character(char.lowercased())), true)
        case "0"..."9": return (keyCodeForDigit(char), false)
            
        // Shifted Symbols on Standard US Layout
        case "!": return (18, true) // Shift + 1
        case "@": return (19, true) // Shift + 2
        case "#": return (20, true) // Shift + 3
        case "$": return (21, true) // Shift + 4
        case "%": return (23, true) // Shift + 5
        case "^": return (22, true) // Shift + 6
        case "&": return (26, true) // Shift + 7
        case "*": return (28, true) // Shift + 8
        case "(": return (25, true) // Shift + 9
        case ")": return (29, true) // Shift + 0
        case "_": return (27, true) // Shift + -
        case "+": return (24, true) // Shift + =
        case "{": return (33, true) // Shift + [
        case "}": return (30, true) // Shift + ]
        case "|": return (42, true) // Shift + \
        case ":": return (41, true) // Shift + ;
        case "\"": return (39, true)// Shift + '
        case "<": return (43, true) // Shift + ,
        case ">": return (47, true) // Shift + .
        case "?": return (44, true) // Shift + /
        case "~": return (50, true) // Shift + `
            
        // Unshifted Symbols
        case "-": return (27, false)
        case "=": return (24, false)
        case "[": return (33, false)
        case "]": return (30, false)
        case "\\": return (42, false)
        case ";": return (41, false)
        case "'": return (39, false)
        case ",": return (43, false)
        case ".": return (47, false)
        case "/": return (44, false)
        case "`": return (50, false)
        case " ": return (49, false)
            
        default: return nil
        }
    }
    
    private func keyCodeForLower(_ char: Character) -> CGKeyCode {
        switch char {
        case "a": return 0
        case "b": return 11
        case "c": return 8
        case "d": return 2
        case "e": return 14
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "i": return 34
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "m": return 46
        case "n": return 45
        case "o": return 31
        case "p": return 35
        case "q": return 12
        case "r": return 15
        case "s": return 1
        case "t": return 17
        case "u": return 32
        case "v": return 9
        case "w": return 13
        case "x": return 7
        case "y": return 16
        case "z": return 6
        default: return 0
        }
    }
    
    private func keyCodeForDigit(_ char: Character) -> CGKeyCode {
        switch char {
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        case "0": return 29
        default: return 29
        }
    }
    
    // Custom Enum for macOS Feedback
    enum FeedbackType {
        case success
        case generic
    }
    
    private func triggerFeedback(type: FeedbackType) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch type {
        case .success: pattern = .levelChange
        case .generic: pattern = .generic
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
