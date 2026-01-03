<div align="center">
  <img src="non-app-file/icon.png" width="128" height="128" alt="Flippy Lid Icon">
  <h1>Flippy Lid</h1>
  <p>
    <strong>The first game you play with your hardware!</strong><br>
    Built with SwiftUI + Hidden macOS Sensors
  </p>
</div>

---

### 🎮 Demo

<div align="center">
  <video src="non-app-file/demo_video.mp4" controls width="100%"></video>
  <br>
  <em>(If the video doesn't play, <a href="non-app-file/demo_video.mp4">click here to watch it</a>)</em>
</div>

### 🧐 What is this?

Flippy Lid is a simple Flappy Bird clone with a twist: **You control the bird by flapping your MacBook's lid!**

Open and close your laptop lid to make the bird jump. It uses the hidden hinge angle sensors found in MacBooks to detect your "flaps".

### 💡 Inspiration

This project stands on the shoulders of giants (and hinge sensors):

*   **Lid Angle Detection**: [LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) by Sam Henri Gold. This project pioneered the dark art of reading macOS hinge sensor references.
*   **The Idea**: Directed by [this tweet](https://x.com/rebane2001/status/2007198231479103611) from @rebane2001, who first dreamed of using the lid angle as a jump trigger.

### ⚠️ Limitations & Compatibility

**Use at your own risk!** Flapping your laptop lid aggressively is a great workout for your hinge, but maybe not what Jony Ive intended.

*   **Mac Only**: This app requires a MacBook with a lid. iMac and Mac Mini users, you're out of luck (unless you flap your monitor manually, which won't work, but would be funny).
*   **Sensor Lottery**: This app relies on specific, private system sensors found in `AppleCLCD` or similar IO services.
    *   It is **hard-coded** to look for specific sensor IDs.
    *   **M1/M2/M3 Compatibility**: Like the original *LidAngleSensor* project, support for Apple Silicon (M1/M2/M3) is hit-or-miss. It may not work on M1 MacBook Airs or Pros due to sensor ID changes.
*   **Private APIs**: We use private IOKit connections. A future macOS update could silence the sensors forever.

### 🚀 How to Play

1.  Clone this repo.
2.  Open `Flappy.Lid.xcodeproj` in Xcode.
3.  Build & Run.
4.  **Start Flapping!** 🦅