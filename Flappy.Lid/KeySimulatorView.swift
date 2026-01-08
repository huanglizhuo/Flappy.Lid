import SwiftUI
import ApplicationServices

struct KeySimulatorView: View {
    @ObservedObject var gameEngine: GameViewModel  // Added for Settings
    @ObservedObject var keySimulator = KeySimulator.shared
    @ObservedObject var lidMonitor: LidAngleMonitor
    
    @State private var isListeningForKey = false
    @State private var showSettings = false // Added for Settings Sheet
    
    var body: some View {
        ZStack { // Wrap in ZStack for HUD overlay
            // Background is transparent or handled by ContentView
            
            VStack(spacing: 16) {
                // Top Header
                ZStack {
                    // Centered Title
                    Text("KEY SIMULATOR")
                        .font(.flappy(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    // Buttons
                    HStack {
                        // Close Button
                        Button(action: {
                            withAnimation {
                                gameEngine.appMode = .selecting
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                                .padding()
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Settings Button
//                        Button(action: { showSettings = true }) {
//                            Image(systemName: "gearshape.fill")
//                                .font(.system(size: 30))
//                                .foregroundColor(.white)
//                                .shadow(radius: 5)
//                                .padding()
//                        }
//                        .buttonStyle(.plain)
                    }
                }
                singleKeyView
            }
            .padding(.top, 20)
            .sheet(isPresented: $showSettings) {
                SettingsView(isPresented: $showSettings, gameEngine: gameEngine, lidMonitor: lidMonitor)
            }
        } // End ZStack
    }


    // MARK: - Single Key View
    private var singleKeyView: some View {
        VStack(spacing: 10) {
            // Visual Indicator
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 160)
                
                if let lastTrig = keySimulator.lastTriggerTime,
                   Date().timeIntervalSince(lastTrig) < 0.2 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 120, height: 120)
                        .transition(.scale)
                }
                
                VStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(KeySimulator.shared.keyCodeToName(keySimulator.targetKeyCode))
                        .font(.flappy(size: 30))
                        .foregroundColor(.yellow)
                        .padding(.top, 10)
                }
            }
            .padding(.vertical, 20)
            
            // Current Trigger Info
            Text("TRIGGER: \(lidMonitor.triggerMode.rawValue.uppercased())")
                .font(.flappy(size: 20))
                .foregroundColor(.white.opacity(0.8))
            
            // Permissions Warning
            if !keySimulator.checkPermissions() {
                VStack {
                    Text("Accessibility Permission Required")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Grant permission in System Settings to control other apps.")
                        .font(.caption)
                        .foregroundColor(.white)
                    Button("Open Settings") {
                        // Prompt again which opens settings
                        _ = keySimulator.checkPermissions()
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
            }
            
            // Key Binding Config
            Button(action: {
                isListeningForKey = true
            }) {
                Text(isListeningForKey ? "PRESS A KEY..." : "CHANGE KEY BINDING")
                    .padding()
                    .background(isListeningForKey ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.flappy(size: 18))
            }
            .buttonStyle(.plain)
            .background(KeyReaderView(active: $isListeningForKey) { newKeyCode in
                keySimulator.targetKeyCode = newKeyCode
                isListeningForKey = false
            })
            
            // Minimize Button
            Button(action: {
                StatusBarManager.shared.minimizeToMenuBar()
            }) {
                HStack {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                    Text("MINIMIZE TO MENU BAR")
                }
                .font(.flappy(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Use Settings to configure Sensitivity and Trigger Mode.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.all, 10)
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
