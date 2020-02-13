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
        
        let nodes: [AVAudioNode] = [
            player,
            reverb,
            delay,
            eq,
            tapMixer2,
            
            monoMixer,
            tapMixer,
            muteMixer,
        ]
        for node in nodes {
            engine.attach(node)
        }
        
//        reverb.loadFactoryPreset(.mediumRoom)
//        reverb.wetDryMix = 10
        
        
//        delay.delayTime = 0.3
//        delay.feedback = 5
//        delay.lowPassCutoff = 10
//        delay.wetDryMix = 20
        
//        engine.connect(player, to: reverb, format: interFormat)

//        engine.connect(player, to:tapMixer2, format: interFormat)
//        engine.connect(tapMixer2, to: engine.mainMixerNode, format: interFormat)

        engine.connect(engine.inputNode, to: monoMixer, format: engine.inputNode.outputFormat(forBus: 0))
//        engine.connect(monoMixer, to: eq, format: interFormat)
        engine.connect(monoMixer, to: tapMixer, format: interFormat)
        engine.connect(tapMixer, to: muteMixer, format: interFormat)
        engine.connect(muteMixer, to: engine.mainMixerNode, format: interFormat)

        
        engine.connect(player, to: eq, format: interFormat)
        engine.connect(eq, to: tapMixer2, format: interFormat)
        engine.connect(tapMixer2, to: engine.mainMixerNode, format: interFormat)

//        engine.connect(engine.inputNode, to: monoMixer, format: engine.inputNode.outputFormat(forBus: 0))
//        engine.connect(monoMixer, to: tapMixer, format: interFormat)
//        engine.connect(tapMixer, to: muteMixer, format: interFormat)
//        engine.connect(muteMixer, to: engine.mainMixerNode, format: interFormat)
        muteMixer.volume = 0
        
        tapMixer.installTap(onBus: 0, bufferSize: 19200, format: interFormat, block: { [weak self] (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
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
        
        player.scheduleBuffer(conv, completionHandler: nil)
    }
    
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
