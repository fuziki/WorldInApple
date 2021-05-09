//
//  SpectralEnvelopeEstimation.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/09.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import WorldLib

public class SpectralEnvelopeEstimator: WorldInAppleComponents {
    private var parameters: WorldInAppleParameters
    
    private var cheapOption = CheapTrickOption()
    
    required init(parameters: WorldInAppleParameters) {
        self.parameters = parameters

        InitializeCheapTrickOption(Int32(parameters.fs), &cheapOption)
        cheapOption.f0_floor = 71
    }
    
    public func estimateSpectral(x: UnsafeMutablePointer<Double>, x_length: Int32) {
        CheapTrick(x, Int32(x_length),
                   Int32(parameters.fs), parameters.time_axis,
                   parameters.f0, Int32(parameters.f0_length),
                   &cheapOption,
                   parameters.spectrogram)
        //output: spectrogram
    }    
}
