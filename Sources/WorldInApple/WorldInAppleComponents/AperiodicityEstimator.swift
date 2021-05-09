//
//  AperiodicityEstimation.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/09.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import WorldLib

public class AperiodicityEstimator: WorldInAppleComponents {
    private var parameters: WorldInAppleParameters

    private var d4cOption = D4COption()

    required public init(parameters: WorldInAppleParameters) {
        self.parameters = parameters

        InitializeD4COption(&d4cOption)
        d4cOption.threshold = 0.85
    }
    
    public func estimatAperiodicity(x: UnsafeMutablePointer<Double>, x_length: Int32) {
        D4C(x, x_length, Int32(parameters.fs), parameters.time_axis, parameters.f0, Int32(parameters.f0_length), Int32(parameters.fft_size), &d4cOption, parameters.aperiodicity)
        //output: parameters
    }
    
}
