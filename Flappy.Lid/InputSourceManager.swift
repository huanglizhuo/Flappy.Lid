import Foundation
import Carbon

class InputSourceManager {
    static let shared = InputSourceManager()
    
    private var previousSource: TISInputSource?
    
    func saveCurrentSource() {
        if Thread.isMainThread {
            if let current = TISCopyCurrentKeyboardInputSource() {
                previousSource = current.takeRetainedValue()
            }
        } else {
            DispatchQueue.main.sync {
                if let current = TISCopyCurrentKeyboardInputSource() {
                    previousSource = current.takeRetainedValue()
                }
            }
        }
    }
    
    func restorePreviousSource() {
        let action = {
            guard let previous = self.previousSource else { return }
            TISSelectInputSource(previous)
            self.previousSource = nil
            print("[InputSourceManager] Restored previous input source")
        }
        
        if Thread.isMainThread { action() } else { DispatchQueue.main.sync(execute: action) }
    }
    
    func switchToAsciiCapableSource() -> Bool {
        saveCurrentSource()
        
        // Run input source switching on Main Thread
        let action: () -> Bool = {
            // 2. Find a "US" or "ABC" or "British" source
            // Explicitly cast nil to CFDictionary? to be safe
            guard let sourceListPtr = TISCreateInputSourceList(nil, false) else {
                print("Failed to create input source list")
                return false
            }
            guard let sources = sourceListPtr.takeRetainedValue() as? [TISInputSource] else {
                print("Failed to cast input sources")
                return false
            }
            
            // Priority: "com.apple.keylayout.US", "com.apple.keylayout.ABC"
            let targetIDs = ["com.apple.keylayout.US", "com.apple.keylayout.ABC", "com.apple.keylayout.British"]
            
            for id in targetIDs {
                if let source = sources.first(where: { source in
                    guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return false }
                    let sourceID = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
                    return sourceID == id
                }) {
                    let err = TISSelectInputSource(source)
                    if err == noErr {
                        print("[InputSourceManager] Switched to \(id)")
                        return true
                    }
                }
            }
            
            // Fallback
            if let fallback = sources.first(where: { source in
                guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return false }
                let sourceID = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
                return sourceID.contains("keylayout") && (sourceID.contains("US") || sourceID.contains("English"))
            }) {
                 let err = TISSelectInputSource(fallback)
                 return err == noErr
            }
            
            print("[InputSourceManager] Could not find ASCII capable source")
            return false
        }
        
        if Thread.isMainThread { return action() }
        else { return DispatchQueue.main.sync(execute: action) }
    }
}
