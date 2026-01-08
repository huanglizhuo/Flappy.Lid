import SwiftUI
import ApplicationServices

struct KeySimulatorView: View {
    @ObservedObject var gameEngine: GameViewModel  // Added for Settings
    @ObservedObject var keySimulator = KeySimulator.shared
    @ObservedObject var lidMonitor: LidAngleMonitor
    
    @State private var isListeningForKey = false
    @State private var showSettings = false // Added for Settings Sheet
    
    var body: some View {
        GeometryReader { geometry in
            let minDim = min(geometry.size.width, geometry.size.height)
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                VStack(spacing: 0) {
                    // 1. Header
                    ZStack {
                        // Centered Title
                        Text("KEY SIMULATOR")
                            .font(.flappy(size: minDim * 0.08)) // Responsive Font
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                        
                        // Buttons
                        HStack {
                            Button(action: {
                                withAnimation {
                                    gameEngine.appMode = .selecting
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: minDim * 0.06))
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            // Settings Button (Enabled)
//                            Button(action: { showSettings = true }) {
//                                Image(systemName: "gearshape.fill")
//                                    .font(.system(size: minDim * 0.06))
//                                    .foregroundColor(.white)
//                                    .shadow(radius: 5)
//                            }
//                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .frame(height: geometry.size.height * 0.15)
                    
                    Spacer()
                    
                    // 2. Main Visualizer
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: minDim * 0.4, height: minDim * 0.4)
                            
                            if let lastTrig = keySimulator.lastTriggerTime,
                               Date().timeIntervalSince(lastTrig) < 0.2 {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: minDim * 0.3, height: minDim * 0.3)
                                    .transition(.scale)
                            }
                            
                            VStack {
                                Image(systemName: "keyboard")
                                    .font(.system(size: minDim * 0.15))
                                    .foregroundColor(.white)
                                
                                Text(KeySimulator.shared.keyCodeToName(keySimulator.targetKeyCode))
                                    .font(.flappy(size: minDim * 0.06))
                                    .foregroundColor(.yellow)
                                    .padding(.top, 5)
                            }
                        }
                        
                        // Trigger Info
                        Text("TRIGGER: \(lidMonitor.triggerMode.rawValue.uppercased())")
                            .font(.flappy(size: minDim * 0.04))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Key Binding Config
                        Button(action: {
                            isListeningForKey = true
                        }) {
                            Text(isListeningForKey ? "PRESS A KEY..." : "CHANGE KEY BINDING")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(isListeningForKey ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.flappy(size: minDim * 0.035))
                        }
                        .buttonStyle(.plain)
                        .background(KeyReaderView(active: $isListeningForKey) { newKeyCode in
                            keySimulator.targetKeyCode = newKeyCode
                            isListeningForKey = false
                        })
                    }
                    
                    Spacer()
                    
                    // 3. Minimize Button & Warning
                    VStack(spacing: 10) {
                        if !keySimulator.checkPermissions() {
                            Text("Accessibility Permission Required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            StatusBarManager.shared.minimizeToMenuBar()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                Text("MINIMIZE TO MENU BAR")
                            }
                            .font(.flappy(size: minDim * 0.03))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 10)
                    
                    // 4. Footer Instructions
                    Text("Use Settings to configure Sensitivity and Trigger Mode.")
                        .font(.system(size: minDim * 0.025))
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(isPresented: $showSettings, gameEngine: gameEngine, lidMonitor: lidMonitor)
            }
        }
    }
}

// MARK: - Lid Password View


// Invisible view to capture key input
struct KeyReaderView: NSViewRepresentable {
    @Binding var active: Bool
    var onKey: (CGKeyCode) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyInputNSView()
        view.onKey = onKey
        view.activeBinding = $active
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? KeyInputNSView else { return }
        view.activeBinding = $active
        if active {
            DispatchQueue.main.async {
                view.window?.makeFirstResponder(view)
            }
        }
    }
    
    class KeyInputNSView: NSView {
        var onKey: ((CGKeyCode) -> Void)?
        var activeBinding: Binding<Bool>?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            guard let active = activeBinding?.wrappedValue, active else {
                super.keyDown(with: event)
                return
            }
            onKey?(event.keyCode)
        }
    }
}

#Preview {
    KeySimulatorView(
        gameEngine: GameViewModel(),
        lidMonitor: LidAngleMonitor()
    )
    .background(Color(red: 0.1, green: 0.1, blue: 0.2))
}
