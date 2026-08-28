import AVFoundation

final class GameSoundPlayer {
    private let engine = AVAudioEngine()
    private let hitPlayer = AVAudioPlayerNode()
    private let attractPlayer = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isReady = false

    init() {
        engine.attach(hitPlayer)
        engine.attach(attractPlayer)
        engine.connect(hitPlayer, to: engine.mainMixerNode, format: format)
        engine.connect(attractPlayer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.35
    }

    func playHit() {
        prepareIfNeeded()
        guard isReady else { return }

        scheduleTone(
            on: hitPlayer,
            duration: 0.10,
            startFrequency: Double.random(in: 760...940),
            endFrequency: Double.random(in: 520...650),
            amplitude: 0.42,
            decay: 30
        )
    }

    func playAttract(for kind: TargetKind) {
        prepareIfNeeded()
        guard isReady else { return }

        let baseFrequency: Double
        switch kind {
        case .mouse: baseFrequency = 430
        case .fish: baseFrequency = 350
        case .butterfly: baseFrequency = 520
        case .beetle: baseFrequency = 290
        case .yarnBall: baseFrequency = 390
        case .feather: baseFrequency = 470
        }

        scheduleTone(
            on: attractPlayer,
            duration: 0.24,
            startFrequency: baseFrequency * 0.88,
            endFrequency: baseFrequency * 1.16,
            amplitude: 0.20,
            decay: 5
        )
    }

    func stop() {
        hitPlayer.stop()
        attractPlayer.stop()
        engine.stop()
        isReady = false
    }

    private func prepareIfNeeded() {
        guard !isReady else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        engine.prepare()
        do {
            try engine.start()
            isReady = true
        } catch {
            isReady = false
        }
    }

    private func scheduleTone(
        on player: AVAudioPlayerNode,
        duration: Double,
        startFrequency: Double,
        endFrequency: Double,
        amplitude: Double,
        decay: Double
    ) {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = frameCount
        var phase = 0.0

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(max(1, Int(frameCount) - 1))
            let frequency = startFrequency + (endFrequency - startFrequency) * progress
            phase += 2 * .pi * frequency / format.sampleRate

            let fadeIn = min(1, progress * 12)
            let envelope = fadeIn * exp(-progress * decay)
            let warble = 1 + 0.08 * sin(2 * .pi * 9 * progress)
            samples[frame] = Float(sin(phase) * envelope * amplitude * warble)
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }
}
