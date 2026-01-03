import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var gameEngine: GameViewModel
    @ObservedObject var lidMonitor: LidAngleMonitor
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 25) {
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                Divider().background(Color.white)
                
                // 1. Game Difficulty
                VStack(alignment: .leading) {
                    Text("Game Difficulty")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Picker("Difficulty", selection: $gameEngine.gameMode) {
                        Text("Simple (Wide Gap)").tag(GameMode.simple)
                        Text("Normal (Standard)").tag(GameMode.normal)
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                // 2. Input Methods
                VStack(alignment: .leading) {
                    Text("Input Configuration")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Toggle("Enable Space Key Jump", isOn: $gameEngine.isSpaceJumpEnabled)
                        .toggleStyle(.switch)
                        .tint(.green)
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Text("Lid Trigger Mode")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Picker("Trigger Mode", selection: $lidMonitor.triggerMode) {
                        Text("Instant (> X)").tag(TriggerMode.instant)
                        Text("Flap (Up & Down)").tag(TriggerMode.flap)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(lidMonitor.triggerMode == .instant ? 
                         "Jumps immediately when lid moves faster than threshold." :
                         "Jumps when you quickly open AND close the lid (or vice versa) within 0.5s.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 5)
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                // 3. Sensitivity (Threshold)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Sensitivity Threshold (X)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f°", lidMonitor.jumpThreshold))
                            .font(.title3)
                            .bold()
                            .foregroundColor(.yellow)
                    }
                    
                    Slider(value: $lidMonitor.jumpThreshold, in: 1.0...20.0, step: 0.5) {
                        Text("Threshold")
                    } minimumValueLabel: {
                        Text("1°").foregroundColor(.gray)
                    } maximumValueLabel: {
                        Text("20°").foregroundColor(.gray)
                    }
                    .tint(.yellow)
                }
                
                // 4. Removed Live Calibration Meter (moved to HUD)
                
                Spacer()
                
                Button("Reset to Recommended Defaults") {
                    withAnimation {
                        // Game Defaults
                        gameEngine.gameMode = .normal
                        gameEngine.isSpaceJumpEnabled = true
                        
                        // Sensor Defaults
                        lidMonitor.triggerMode = .flap
                        lidMonitor.jumpThreshold = 4.0
                    }
                }
                .foregroundColor(.red)
                .buttonStyle(.plain)
                .padding(.bottom, 10)
                
                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.cancelAction) // Esc closes it?
            }
            .padding(40)
            .background(Color(nsColor: .windowBackgroundColor).cornerRadius(20))
            .frame(width: 500, height: 650)
            .shadow(radius: 20)
        }
    }
}
