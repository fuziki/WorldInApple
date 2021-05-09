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
    private var f0Estimator: DioF0Estimator
    private var spectralEnvelopeEstimator: SpectralEnvelopeEstimator
    private var aperiodicityEstimator: AperiodicityEstimator
    private var parameterModificator: ParameterModificator
    private var synthesizer: WorldInAppleSynthesizer3
    
    private var onUpdateSettingHandlers: [(_ fs: Int, _ frame_period: Double, _ x_length: Int) -> Void] = []
    public func onUpdateSetting(handler: @escaping (_ fs: Int, _ frame_period: Double, _ x_length: Int) -> Void) {
        onUpdateSettingHandlers.append(handler)
    }
    
    public init(fs: Int, frame_period: Double, x_length: Int) {
        self.fs = fs
        self.frame_period = frame_period
        self.x_length = x_length
        parameters = WorldInAppleParameters(fs: fs, frame_period: frame_period, x_length: x_length)
        f0Estimator = DioF0Estimator(parameters: parameters)
        spectralEnvelopeEstimator = SpectralEnvelopeEstimator(parameters: parameters)
        aperiodicityEstimator = AperiodicityEstimator(parameters: parameters)
        parameterModificator = ParameterModificator(parameters: parameters)
        synthesizer = WorldInAppleSynthesizer3(parameters: parameters)
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
        f0Estimator = DioF0Estimator(parameters: parameters)
        spectralEnvelopeEstimator = SpectralEnvelopeEstimator(parameters: parameters)
        aperiodicityEstimator = AperiodicityEstimator(parameters: parameters)
        parameterModificator = ParameterModificator(parameters: parameters)
        synthesizer = WorldInAppleSynthesizer3(parameters: parameters)
        for handler in onUpdateSettingHandlers {
            handler(fs, frame_period, x_length)
        }
    }
    
    deinit {
        onUpdateSettingHandlers.removeAll()
    }
    
    public func set(pitch: Double? = nil, formant: Double? = nil) {
        parameterModificator.set(pitch: pitch, formant: formant)
    }
    
    public func conv(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let x = (buffer.audioBufferList.pointee.mBuffers.mData?.assumingMemoryBound(to: Double.self))!
        let x_length = Int32(buffer.frameLength)

        updateSetting(x_length: Int(x_length))
        
        f0Estimator.estimateF0(x: x, x_length: x_length)

        spectralEnvelopeEstimator.estimateSpectral(x: x, x_length: x_length)

        aperiodicityEstimator.estimatAperiodicity(x: x, x_length: x_length)

        parameterModificator.modificate()

        let res = synthesizer.synthesis(buffer: buffer)

        return res
    }
}
