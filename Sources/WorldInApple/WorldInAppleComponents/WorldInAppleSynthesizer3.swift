//
//  WaveformSynthesis3.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/09.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import AVFoundation
import WorldLib

public class WorldInAppleSynthesizer3: WorldInAppleComponents {
    private var parameters: WorldInAppleParameters
    
    private let buffer_size = 64

    private var worldSynthesizer: WorldSynthesizer = WorldSynthesizer()
    
    required public init(parameters: WorldInAppleParameters) {
        self.parameters = parameters
        
        InitializeSynthesizer(Int32(parameters.fs), parameters.frame_period, Int32(parameters.fft_size), Int32(buffer_size), 100, &worldSynthesizer)
    }
    
    public func synthesis(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        var offset = 0
        var index = 0
        
        for i in 0..<parameters.f0_length {
            let res = AddParameters(parameters.f0.advanced(by: i), 1, parameters.spectrogram.advanced(by: i), parameters.aperiodicity.advanced(by: i), &worldSynthesizer)
            if res == 0 {
                print("fatal error: failed to add paramaters")
                return nil
            }
            
            while (Synthesis2(&worldSynthesizer) != 0) {
                index = offset * buffer_size
                let dst = buffer
                    .audioBufferList
                    .pointee
                    .mBuffers
                    .mData?
                    .assumingMemoryBound(to: Double.self)
                    .advanced(by: Int(index))
                
                memcpy(dst, worldSynthesizer.buffer, buffer_size * MemoryLayout<Double>.size)
                offset += 1
            }
            
            if (IsLocked(&worldSynthesizer) == 1) {
                print("Locked!")
                return nil
            }
        }
        return buffer
    }
}
