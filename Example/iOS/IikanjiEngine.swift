//
//  IikanjiEngine.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/08.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

public class IikanjiEngine {
    
    private var engine = AVAudioEngine()

    private var player = AVAudioPlayerNode()
    private var reverb = AVAudioUnitReverb()
    private var eq = AVAudioUnitEQ(numberOfBands: 10)
    private var delay = AVAudioUnitDelay()
    private var tapMixer2 = AVAudioMixerNode()

    private var monoMixer = AVAudioMixerNode()
    private var tapMixer = AVAudioMixerNode()
    private var muteMixer = AVAudioMixerNode()

    private var interFormat: AVAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)!
    private var worldFormat: AVAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat64, sampleRate: 48000, channels: 1, interleaved: false)!
    
    private var convTapAudioHandler: ((_ buffer: AVAudioPCMBuffer) -> Void)? = nil
    public func convTapAudio(handler: @escaping (_ buffer: AVAudioPCMBuffer) -> Void) {
        convTapAudioHandler = handler
    }
    
    private var scheduleAudioHandler: ((_ buffer: [Float]) -> Void)? = nil
    public func scheduleAudio(handler: @escaping (_ buffer: [Float]) -> Void) {
        scheduleAudioHandler = handler
    }
    
    private var inputConverter: Converter
    private var outputConverter: Converter
    
    public init() {
        inputConverter = Converter(from: interFormat, to: worldFormat)
        outputConverter = Converter(from: worldFormat, to: interFormat)

        let freqs: [Float] = [31.25, 62.5, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        eq.bypass = false
        let eqParams = eq.bands
        for i in 0..<eqParams.count {
            let p = eqParams[i]
            print("p: \(p.bandwidth), \(p.frequency), \(p.filterType.rawValue), \(p.bypass)")
            p.bypass = false
            p.frequency = freqs[i]
            p.filterType = .parametric
            p.bandwidth = 1
        }

        try! engine.inputNode.setVoiceProcessingEnabled(true)
//        engine.inputNode.isVoiceProcessingAGCEnabled = true
//        engine.inputNode.isVoiceProcessingBypassed = false
        
        
        var turnOff: UInt32 = 0
        var turnOn: UInt32 = 1 // use this if you want to enable properties
        var err = AudioUnitSetProperty(engine.inputNode.audioUnit!,
                                   kAUVoiceIOProperty_BypassVoiceProcessing,
                                   kAudioUnitScope_Global,
                                   1,
                                   &turnOff,
                                   UInt32(MemoryLayout.size(ofValue: turnOff)))

        if err != noErr {
          print("[ERROR] Unable to disable bypass voice processing")
          return
        }

        err = AudioUnitSetProperty(engine.inputNode.audioUnit!,
                                   kAUVoiceIOProperty_VoiceProcessingEnableAGC,
                                   kAudioUnitScope_Global,
                                   0,
                                   &turnOn,
                                   UInt32(MemoryLayout.size(ofValue: turnOn)))

        if err != noErr {
          print("[ERROR] Unable to disable AGC")
          return
        }
        
        
//        try! engine.outputNode.setVoiceProcessingEnabled(true)

        
        let nodes: [AVAudioNode] = [
            player,
//            reverb,
//            delay,
            eq,
            tapMixer2,
            
//            monoMixer,
//            tapMixer,
//            muteMixer,
        ]
        for node in nodes {
            engine.attach(node)
        }
        
//        engine.inputNode.isVoiceProcessingInputMuted = false
//        engine.inputNode.setManualRenderingInputPCMFormat(<#T##format: AVAudioFormat##AVAudioFormat#>, inputBlock: AVA)
        
//        reverb.loadFactoryPreset(.mediumRoom)
//        reverb.wetDryMix = 10
        
        
//        delay.delayTime = 0.3
//        delay.feedback = 5
//        delay.lowPassCutoff = 10
//        delay.wetDryMix = 20
        
//        engine.connect(player, to: reverb, format: interFormat)

//        engine.connect(player, to:tapMixer2, format: interFormat)
//        engine.connect(tapMixer2, to: engine.mainMixerNode, format: interFormat)

//        engine.connect(engine.inputNode, to: monoMixer, format: engine.inputNode.outputFormat(forBus: 0))
//        engine.connect(monoMixer, to: eq, format: interFormat)
//        engine.connect(monoMixer, to: tapMixer, format: interFormat)
//        engine.connect(tapMixer, to: muteMixer, format: interFormat)
//        engine.connect(muteMixer, to: engine.mainMixerNode, format: interFormat)

        
        engine.connect(player, to: eq, format: interFormat)
        engine.connect(eq, to: tapMixer2, format: interFormat)
        engine.connect(tapMixer2, to: engine.mainMixerNode, format: interFormat)

//        engine.connect(engine.inputNode, to: monoMixer, format: engine.inputNode.outputFormat(forBus: 0))
//        engine.connect(monoMixer, to: tapMixer, format: interFormat)
//        engine.connect(tapMixer, to: muteMixer, format: interFormat)
//        engine.connect(muteMixer, to: engine.mainMixerNode, format: interFormat)
//        muteMixer.volume = 0
        
        engine.inputNode.installTap(onBus: 0, bufferSize: 19200, format: engine.inputNode.inputFormat(forBus: 0), block: { [weak self] (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
            print("on Buff: \(String(describing: self?.timer.timeSec))")
            if buffer.audioBufferList.pointee.mBuffers.mData == nil {
                print("error mData is nil")
            }
            self?.onAudio(buffer: buffer)
        })
        
        tapMixer2.installTap(onBus: 0, bufferSize: 4800, format: interFormat, block: { [weak self] (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
            let arr: [Float] = buffer.audioBufferList.pointee.mBuffers.convertFloatArray()

            var fftResult: DSPSplitComplex = AccelerateUtil.fft(arr)

            var fftResult_amplitude = [Float](repeating: 0, count: Int(arr.count / 2))
            vDSP_zvabs(&fftResult, 1, &fftResult_amplitude, 1, vDSP_Length(arr.count / 2))
            self?.scheduleAudioHandler?(fftResult_amplitude)
        })
        
        engine.prepare()
    }
    
    let timer = BagotTimer()
    
    public func start() {
        try! engine.start()
        player.play()
    }
    
    private func onAudio(buffer: AVAudioPCMBuffer) {
        guard let conv = inputConverter.convert(from: buffer) else {
            return
        }
        convTapAudioHandler?(conv)
    }
    
    public func scheduleBuffer(buffer: AVAudioPCMBuffer) {
        guard let conv = outputConverter.convert(from: buffer) else {
            return
        }
        
        playingBuff.append(conv)
        if playingBuff.count > 10 {
            playingBuff.removeFirst()
        }
        player.scheduleBuffer(conv, completionHandler: {
            print("played buff!")
        })
    }
    
    private var playingBuff: [AVAudioPCMBuffer] = []
    
    public func update(eqValue: [Float]) {
        for i in 0..<min(eqValue.count, eq.bands.count) {
            eq.bands[i].gain = eqValue[i]
        }
    }
}

fileprivate class Converter {
    private var converter: AVAudioConverter
    public init(from: AVAudioFormat, to: AVAudioFormat) {
        converter = AVAudioConverter(from: from, to: to)!
    }

    public func convert(from: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let capacity = from.frameCapacity * UInt32(converter.outputFormat.sampleRate / converter.inputFormat.sampleRate)
        guard let to = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity) else {
            return nil
        }
        var error: NSError?
        converter.convert(to: to,
                          error: &error,
                          withInputFrom: { _, outStatus in
                            outStatus.pointee = AVAudioConverterInputStatus.haveData
                            return from
        })
        return error == nil ? to : nil
    }
}

extension AudioBuffer {
    public func convertFloatArray() -> [Float] {
        if let mdata: UnsafeMutableRawPointer = self.mData {
            let usmp: UnsafeMutablePointer<Float> = mdata.assumingMemoryBound(to: Float.self)
//            let usp = UnsafeBufferPointer(start: usmp, count: Int(self.mDataByteSize) / MemoryLayout<Float>.size)
            let usp = UnsafeBufferPointer(start: usmp, count: 1024)
            return Array(usp)
        } else {
            return [Float]()
        }
    }
}

public class BagotTimer {
    @inlinable var timeSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
}
