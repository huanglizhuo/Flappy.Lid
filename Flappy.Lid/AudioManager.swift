import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    // Cache sounds to avoid latency
    func preloadSounds() {
        let sounds = ["flap", "point", "flappy-bird-hit-sound", "die", "swoosh"]
        for sound in sounds {
            // Try main bundle first
            if let url = Bundle.main.url(forResource: sound, withExtension: "mp3") {
                loadPlayer(sound: sound, url: url)
            } else if let url = Bundle.main.url(forResource: sound, withExtension: "mp3", subdirectory: "SoundTrack") {
                // Try SoundTrack subdirectory
                loadPlayer(sound: sound, url: url)
            } else {
                print("[AudioManager] Could not find file for \(sound)")
            }
        }
    }
    
    private func loadPlayer(sound: String, url: URL) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[sound] = player
            print("[AudioManager] Loaded \(sound)")
        } catch {
            print("[AudioManager] Failed to load \(sound): \(error)")
        }
    }
    
    func playJump() {
        playSound("flap")
    }
    
    func playHit() {
        playSound("flappy-bird-hit-sound")
    }
    
    func playDie() {
        playSound("die")
    }
    
    func playScore() {
        playSound("point")
    }
    
    func playSwoosh() {
        playSound("swoosh")
    }
    
    private func playSound(_ name: String) {
        // Stop and replay if already playing to allow rapid fire (like jump)
        if let player = players[name] {
            if player.isPlaying {
                player.currentTime = 0
            } else {
                player.play()
            }
        }
    }
}
