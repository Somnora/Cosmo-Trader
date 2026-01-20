import Foundation
import AVFoundation
import SwiftUI

// MARK: - Terminal Audio Service
// ==============================
// Manages subtle, terminal-style ambient audio.
// Bloomberg terminal floor ambiance, not video game.
//
// FEATURE: Terminal Audio (OFF by default)
// - Faint ticker tape rhythm in background
// - Soft chime when price updates
// - Gentle tone when switching tabs
//
// WHY IT WORKS: Immersion. Premium feel. Differentiator.

@MainActor
@Observable
final class TerminalAudioService {

    // MARK: - Singleton

    static let shared = TerminalAudioService()

    // MARK: - Storage Keys

    private enum StorageKeys {
        static let audioEnabled = "terminalAudio_enabled"
        static let ambientVolume = "terminalAudio_ambientVolume"
        static let effectsVolume = "terminalAudio_effectsVolume"
    }

    // MARK: - State

    /// Whether audio is available on this device (setup succeeded)
    private(set) var isAudioAvailable: Bool = false

    /// Whether terminal audio is enabled (OFF by default)
    var isEnabled: Bool = false {
        didSet {
            // Guard against enabling when audio isn't available
            guard isAudioAvailable else {
                if isEnabled {
                    // Revert the toggle - audio not available
                    isEnabled = false
                }
                return
            }

            UserDefaults.standard.set(isEnabled, forKey: StorageKeys.audioEnabled)
            if isEnabled {
                startAmbientLoop()
            } else {
                stopAllAudio()
            }
        }
    }

    /// Ambient background volume (0.0 - 1.0)
    var ambientVolume: Float = 0.15 {
        didSet {
            UserDefaults.standard.set(ambientVolume, forKey: StorageKeys.ambientVolume)
            ambientPlayer?.volume = ambientVolume
        }
    }

    /// Sound effects volume (0.0 - 1.0)
    var effectsVolume: Float = 0.3 {
        didSet {
            UserDefaults.standard.set(effectsVolume, forKey: StorageKeys.effectsVolume)
        }
    }

    /// Is ambient audio currently playing
    private(set) var isAmbientPlaying: Bool = false

    // MARK: - Audio Players

    /// Background ambient loop player
    private var ambientPlayer: AVAudioPlayer?

    /// Sound effect players (pooled for overlapping sounds)
    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]

    /// Synthesizer for generated tones
    private var toneGenerator: ToneGenerator?

    // MARK: - Throttling

    /// Last time each sound was played (for throttling)
    private var lastPlayTime: [SoundEffect: Date] = [:]

    /// Minimum interval between same sound (prevents spam)
    private let throttleInterval: TimeInterval = 0.1

    // MARK: - Initialization

    private init() {
        loadSettings()
        setupAudioSession()
        prepareSounds()
    }

    // MARK: - Setup

    private func loadSettings() {
        let defaults = UserDefaults.standard

        // Audio is OFF by default
        isEnabled = defaults.bool(forKey: StorageKeys.audioEnabled)

        // Load volumes with defaults
        if defaults.object(forKey: StorageKeys.ambientVolume) != nil {
            ambientVolume = defaults.float(forKey: StorageKeys.ambientVolume)
        }
        if defaults.object(forKey: StorageKeys.effectsVolume) != nil {
            effectsVolume = defaults.float(forKey: StorageKeys.effectsVolume)
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use ambient category so it mixes with other audio and respects silent switch
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            isAudioAvailable = true
        } catch {
            #if DEBUG
            print("⚠️ Terminal Audio: Failed to setup audio session: \(error)")
            #endif
            isAudioAvailable = false
        }
    }

    private func prepareSounds() {
        toneGenerator = ToneGenerator()

        // Verify audio engine started successfully
        if let generator = toneGenerator, !generator.isRunning {
            isAudioAvailable = false
        }
    }

    // MARK: - Public Methods

    /// Play a sound effect
    func play(_ effect: SoundEffect) {
        guard isAudioAvailable, isEnabled else { return }
        guard shouldPlay(effect) else { return }

        lastPlayTime[effect] = Date()

        Task {
            await playEffect(effect)
        }
    }

    /// Play price update chime (varies based on direction)
    func playPriceUpdate(isPositive: Bool) {
        guard isEnabled else { return }
        play(isPositive ? .priceUp : .priceDown)
    }

    /// Play tab switch sound
    func playTabSwitch() {
        play(.tabSwitch)
    }

    /// Play swipe sound (for Discover)
    func playSwipe(direction: SwipeDirection) {
        guard isEnabled else { return }
        switch direction {
        case .left:
            play(.swipeLeft)
        case .right:
            play(.swipeRight)
        case .up:
            play(.swipeUp)
        }
    }

    /// Play ritual completion sound
    func playRitualComplete() {
        play(.ritualComplete)
    }

    /// Play notification/alert sound
    func playAlert() {
        play(.cosmicAlert)
    }

    // MARK: - Ambient Control

    /// Start the ambient background loop
    func startAmbientLoop() {
        guard isAudioAvailable, isEnabled, !isAmbientPlaying else { return }

        // Generate ambient ticker tape sound
        toneGenerator?.startAmbientLoop(volume: ambientVolume)
        isAmbientPlaying = true
    }

    /// Stop all audio
    func stopAllAudio() {
        ambientPlayer?.stop()
        toneGenerator?.stopAll()
        isAmbientPlaying = false
    }

    /// Pause ambient (for app background)
    func pauseAmbient() {
        toneGenerator?.pauseAmbient()
        isAmbientPlaying = false
    }

    /// Resume ambient (for app foreground)
    func resumeAmbient() {
        guard isAudioAvailable, isEnabled else { return }
        toneGenerator?.resumeAmbient()
        isAmbientPlaying = true
    }

    // MARK: - Private Methods

    private func shouldPlay(_ effect: SoundEffect) -> Bool {
        guard let lastTime = lastPlayTime[effect] else { return true }
        return Date().timeIntervalSince(lastTime) >= throttleInterval
    }

    private func playEffect(_ effect: SoundEffect) async {
        toneGenerator?.playEffect(effect, volume: effectsVolume)
    }
}

// MARK: - Sound Effects

enum SoundEffect: String, CaseIterable {
    case priceUp = "price_up"
    case priceDown = "price_down"
    case tabSwitch = "tab_switch"
    case swipeLeft = "swipe_left"
    case swipeRight = "swipe_right"
    case swipeUp = "swipe_up"
    case ritualComplete = "ritual_complete"
    case cosmicAlert = "cosmic_alert"
    case tickerTick = "ticker_tick"
    case refresh = "refresh"

    /// Frequency for synthesized tone (Hz)
    var frequency: Float {
        switch self {
        case .priceUp: return 880       // A5 - bright, ascending feel
        case .priceDown: return 440     // A4 - lower, descending feel
        case .tabSwitch: return 660     // E5 - neutral, clean
        case .swipeLeft: return 392     // G4 - passing by
        case .swipeRight: return 523    // C5 - affirmative
        case .swipeUp: return 698       // F5 - lifting
        case .ritualComplete: return 784 // G5 - celebratory
        case .cosmicAlert: return 587   // D5 - attention
        case .tickerTick: return 1760   // A6 - very subtle tick
        case .refresh: return 493       // B4 - refreshing
        }
    }

    /// Duration in seconds
    var duration: Float {
        switch self {
        case .priceUp, .priceDown: return 0.08
        case .tabSwitch: return 0.05
        case .swipeLeft, .swipeRight: return 0.06
        case .swipeUp: return 0.1
        case .ritualComplete: return 0.2
        case .cosmicAlert: return 0.15
        case .tickerTick: return 0.02
        case .refresh: return 0.1
        }
    }

    /// Attack time (fade in)
    var attack: Float {
        switch self {
        case .tickerTick: return 0.001
        case .ritualComplete: return 0.02
        default: return 0.005
        }
    }

    /// Release time (fade out)
    var release: Float {
        switch self {
        case .tickerTick: return 0.01
        case .ritualComplete: return 0.15
        case .cosmicAlert: return 0.1
        default: return 0.03
        }
    }
}

enum SwipeDirection {
    case left, right, up
}

// MARK: - Tone Generator

/// Synthesizes subtle terminal-style tones using AVAudioEngine
final class ToneGenerator {

    private let audioEngine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private(set) var isRunning = false

    // Ambient oscillators
    private var ambientNodes: [AVAudioSourceNode] = []
    private var ambientVolume: Float = 0.15
    private var isAmbientActive = false

    // Timing for ambient ticker
    private var tickerPhase: Double = 0
    private let tickerRate: Double = 2.5 // Ticks per second (subtle)

    init() {
        mainMixer = audioEngine.mainMixerNode
        setupEngine()
    }

    private func setupEngine() {
        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            #if DEBUG
            print("⚠️ Terminal Audio: Failed to start audio engine: \(error)")
            #endif
            isRunning = false
        }
    }

    /// Try to restart the audio engine if it stopped
    func ensureRunning() -> Bool {
        guard !isRunning else { return true }

        do {
            try audioEngine.start()
            isRunning = true
            return true
        } catch {
            #if DEBUG
            print("⚠️ Terminal Audio: Failed to restart audio engine: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Sound Effects

    func playEffect(_ effect: SoundEffect, volume: Float) {
        guard ensureRunning() else { return }

        let sampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        var phase: Double = 0
        let frequency = Double(effect.frequency)
        let duration = Double(effect.duration)
        let attack = Double(effect.attack)
        let release = Double(effect.release)

        var sampleCount: Int = 0
        let totalSamples = Int(duration * sampleRate)
        let attackSamples = Int(attack * sampleRate)
        let releaseSamples = Int(release * sampleRate)
        let sustainSamples = totalSamples - attackSamples - releaseSamples

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                if sampleCount >= totalSamples {
                    // Silence after sound completes
                    for buffer in bufferList {
                        let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                        buf?[frame] = 0
                    }
                } else {
                    // Calculate envelope
                    var envelope: Float = 0
                    if sampleCount < attackSamples {
                        envelope = Float(sampleCount) / Float(attackSamples)
                    } else if sampleCount < attackSamples + sustainSamples {
                        envelope = 1.0
                    } else {
                        let releaseProgress = Float(sampleCount - attackSamples - sustainSamples) / Float(releaseSamples)
                        envelope = 1.0 - releaseProgress
                    }

                    // Generate sine wave with envelope
                    let sample = Float(sin(phase * 2 * .pi)) * envelope * volume * 0.3

                    for buffer in bufferList {
                        let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                        buf?[frame] = sample
                    }

                    phase += frequency / sampleRate
                    sampleCount += 1
                }
            }

            return noErr
        }

        let format = audioEngine.outputNode.outputFormat(forBus: 0)
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: format)

        // Remove node after sound completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
            self?.audioEngine.detach(sourceNode)
        }
    }

    // MARK: - Ambient Loop

    func startAmbientLoop(volume: Float) {
        // Ensure engine is running, try to restart if needed
        guard ensureRunning(), !isAmbientActive else { return }

        ambientVolume = volume
        isAmbientActive = true

        let sampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate

        // Create subtle ambient texture - very low frequency hum + occasional ticks
        let ambientNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self, self.isAmbientActive else {
                // Silence when paused
                let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in bufferList {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    for frame in 0..<Int(frameCount) {
                        buf?[frame] = 0
                    }
                }
                return noErr
            }

            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)

            for frame in 0..<Int(frameCount) {
                // Very subtle low frequency hum (60Hz - like electrical ambiance)
                let humFreq = 60.0
                let hum = Float(sin(self.tickerPhase * humFreq * 2 * .pi)) * 0.02

                // Occasional subtle tick (simulating ticker tape)
                let tickPhase = self.tickerPhase * self.tickerRate
                let tickEnvelope = max(0, Float(1 - (tickPhase.truncatingRemainder(dividingBy: 1) * 20)))
                let tick = tickEnvelope > 0.9 ? Float.random(in: -0.03...0.03) : 0

                let sample = (hum + tick) * self.ambientVolume

                for buffer in bufferList {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }

                self.tickerPhase += 1.0 / sampleRate
            }

            return noErr
        }

        let format = audioEngine.outputNode.outputFormat(forBus: 0)
        audioEngine.attach(ambientNode)
        audioEngine.connect(ambientNode, to: mainMixer, format: format)
        ambientNodes.append(ambientNode)
    }

    func pauseAmbient() {
        isAmbientActive = false
    }

    func resumeAmbient() {
        isAmbientActive = true
    }

    func stopAll() {
        isAmbientActive = false
        for node in ambientNodes {
            audioEngine.detach(node)
        }
        ambientNodes.removeAll()
    }

    deinit {
        audioEngine.stop()
    }
}
