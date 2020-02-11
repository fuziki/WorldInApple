//
//  WorldInApple.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/08.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Accelerate

public class WorldInApple {
    
    private var fs: Int
    private var frame_period: Double
    private var x_length: Int
    
    private var parameters: WorldInAppleParameters
    private var f0EstimationDio: F0EstimationDio
    private var spectralEnvelopeEstimation: SpectralEnvelopeEstimation
    private var aperiodicityEstimation: AperiodicityEstimation
    private var parameterModification: ParameterModification
    private var waveformSynthesis3: WaveformSynthesis3
    
    private let timer = BagotTimer()
    
    private var onUpdateSettingHandlers: [(_ fs: Int, _ frame_period: Double, _ x_length: Int) -> Void] = []
    public func onUpdateSetting(handler: @escaping (_ fs: Int, _ frame_period: Double, _ x_length: Int) -> Void) {
        onUpdateSettingHandlers.append(handler)
    }
    
    public init(fs: Int, frame_period: Double, x_length: Int) {
        self.fs = fs
        self.frame_period = frame_period
        self.x_length = x_length
        parameters = WorldInAppleParameters(fs: fs, frame_period: frame_period, x_length: x_length)
        f0EstimationDio = F0EstimationDio(parameters: parameters)
        spectralEnvelopeEstimation = SpectralEnvelopeEstimation(parameters: parameters)
        aperiodicityEstimation = AperiodicityEstimation(parameters: parameters)
        parameterModification = ParameterModification(parameters: parameters)
        waveformSynthesis3 = WaveformSynthesis3(parameters: parameters)
    }
    
    public func updateSetting(fs _fs: Int? = nil,
                              frame_period _frame_period: Double? = nil,
                              x_length _x_length: Int? = nil) {
        let n_fs = _fs ?? self.fs
        let n_frame_period = _frame_period ?? self.frame_period
        let n_x_length = _x_length ?? self.x_length
        if self.fs == n_fs && self.frame_period == n_frame_period && self.x_length == n_x_length {
            return
        }        
        self.fs = n_fs
        self.frame_period = n_frame_period
        self.x_length = n_x_length
        parameters = WorldInAppleParameters(fs: fs, frame_period: frame_period, x_length: x_length)
        f0EstimationDio = F0EstimationDio(parameters: parameters)
        spectralEnvelopeEstimation = SpectralEnvelopeEstimation(parameters: parameters)
        aperiodicityEstimation = AperiodicityEstimation(parameters: parameters)
        parameterModification = ParameterModification(parameters: parameters)
        waveformSynthesis3 = WaveformSynthesis3(parameters: parameters)
        for handler in onUpdateSettingHandlers {
            handler(fs, frame_period, x_length)
        }
    }
    
    deinit {
        onUpdateSettingHandlers.removeAll()
    }
    
    public func set(pitch: Double? = nil, formant: Double? = nil) {
        parameterModification.set(pitch: pitch, formant: formant)
    }
    
    public func conv(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let x = (buffer.audioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Double.self))!
        let x_length = Int32(buffer.frameLength)

        updateSetting(x_length: Int(x_length))
        
        let pre = timer.timeSec

        f0EstimationDio.estimateF0(x: x, x_length: x_length)

        let pre2 = timer.timeSec
        print("elapsed f0: \(pre2 - pre)")

        spectralEnvelopeEstimation.estimateSpectral(x: x, x_length: x_length)

        let pre3 = timer.timeSec
        print("elapsed sp: \(pre3 - pre2)")

        aperiodicityEstimation.estimatAperiodicity(x: x, x_length: x_length)

        let pre4 = timer.timeSec
        print("elapsed ap: \(pre4 - pre3)")

        parameterModification.modificate()

        let pre5 = timer.timeSec
        print("elapsed md: \(pre5 - pre4)")

        let res = waveformSynthesis3.synthesis(buffer: buffer)

        let pre6 = timer.timeSec
        print("elapsed sy: \(pre6 - pre5)")

        print("elapsed al: \(pre6 - pre)\n")
        
        return res
    }
}
