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
                Text("SETTINGS")
                    .font(.flappy(size: 40))
                    .foregroundColor(.white)
                
                Divider().background(Color.white)
                
                // 0. App Mode (High Level)
                VStack(alignment: .leading) {
                    Text("APP MODE")
                        .font(.flappy(size: 24))
                        .foregroundColor(.gray)
                    
                    Picker("APP MODE", selection: $gameEngine.appMode) {
                        Text("FLAPPY GAME").tag(AppMode.game)
                        Text("KEY SIMULATOR").tag(AppMode.keySimulator)
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                // 1. Game Difficulty
                VStack(alignment: .leading) {
                    Text("GAME DIFFICULTY")
                        .font(.flappy(size: 24))
                        .foregroundColor(.gray)
                    
                    Picker("DIFFICULTY", selection: $gameEngine.gameMode) {
                        Text("SIMPLE").tag(GameMode.simple)
                        Text("NORMAL").tag(GameMode.normal)
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                // 2. Input Methods
                VStack(alignment: .leading) {
                    Text("INPUT CONFIGURATION")
                        .font(.flappy(size: 24))
                        .foregroundColor(.gray)
                    
                    Toggle("ENABLE SPACE KEY JUMP", isOn: $gameEngine.isSpaceJumpEnabled)
                        .toggleStyle(.switch)
                        .tint(.green)
                        .font(.flappy(size: 20))
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Text("LID TRIGGER MODE")
                        .font(.flappy(size: 24))
                        .foregroundColor(.gray)
                    
                    Picker("TRIGGER MODE", selection: $lidMonitor.triggerMode) {
                        Text("OPEN/CLOSE").tag(TriggerMode.openOrClose)
                        Text("OPEN ONLY").tag(TriggerMode.openOnly)
                        Text("CLOSE ONLY").tag(TriggerMode.closeOnly)
                        Text("FLAP").tag(TriggerMode.flap)
                    }
                    .pickerStyle(.segmented)
                    
                    Group {
                        switch lidMonitor.triggerMode {
                        case .openOrClose:
                            Text("JUMPS WHEN LID MOVES FASTER THAN THRESHOLD IN ANY DIRECTION.")
                        case .openOnly:
                            Text("JUMPS ONLY WHEN YOU OPEN THE LID FASTER THAN THRESHOLD.")
                        case .closeOnly:
                            Text("JUMPS ONLY WHEN YOU CLOSE THE LID FASTER THAN THRESHOLD.")
                        case .flap:
                            Text("JUMPS WHEN YOU QUICKLY OPEN AND CLOSE THE LID (OR VICE VERSA) WITHIN 0.5S.")
                        }
                    }
                    .font(.flappy(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 5)
                    .multilineTextAlignment(.leading)
                    .frame(height: 40) // Fixed height to prevent jitter
                }
                
                Divider().background(Color.gray.opacity(0.5))
                
                // 3. Sensitivity (Threshold)
                VStack(alignment: .leading) {
                    HStack {
                        Text("SENSITIVITY THRESHOLD (X)")
                            .font(.flappy(size: 24))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f°", lidMonitor.jumpThreshold))
                            .font(.flappy(size: 24))
                            .foregroundColor(.yellow)
                    }
                    
                    Slider(value: $lidMonitor.jumpThreshold, in: 1.0...20.0, step: 0.5) {
                        Text("THRESHOLD")
                    } minimumValueLabel: {
                        Text("1°").foregroundColor(.gray)
                    } maximumValueLabel: {
                        Text("20°").foregroundColor(.gray)
                    }
                    .tint(.yellow)
                }
                
                // 4. Removed Live Calibration Meter (moved to HUD)
                
                Spacer()
                
                Button("RESET TO RECOMMENDED DEFAULTS") {
                    withAnimation {
                        // Game Defaults
                        gameEngine.gameMode = .normal
                        gameEngine.isSpaceJumpEnabled = true
                        
                        // Sensor Defaults
                        lidMonitor.triggerMode = .openOnly
                        lidMonitor.jumpThreshold = 4.0
                    }
                }
                .foregroundColor(.red)
                .buttonStyle(.plain)
                .font(.flappy(size: 20))
                .padding(.bottom, 10)
                
                Button("CLOSE") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .font(.flappy(size: 20))
                .keyboardShortcut(.cancelAction) // Esc closes it?
            }
            .padding(40)
            .background(Color(nsColor: .windowBackgroundColor).cornerRadius(20))
            .frame(width: 500, height: 650)
            .shadow(radius: 20)
        }
    }
}
