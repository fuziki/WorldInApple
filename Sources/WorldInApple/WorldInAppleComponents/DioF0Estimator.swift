//
//  F0EstimationDio.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/09.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import WorldLib

public class DioF0Estimator: WorldInAppleComponents {
    private var parameters: WorldInAppleParameters

    private var _f0: UnsafeMutablePointer<Double>
    private var dioOption: DioOption = DioOption()

    required init(parameters: WorldInAppleParameters) {
        self.parameters = parameters
        self._f0 = UnsafeMutablePointer<Double>.allocate(capacity: parameters.f0_length)
        InitializeDioOption(&dioOption)
    }

    public func estimateF0(x: UnsafeMutablePointer<Double>, x_length: Int32) {
        Dio(x, Int32(x_length), Int32(parameters.fs), &dioOption, parameters.time_axis, _f0)
        StoneMask(x, Int32(x_length), Int32(parameters.fs), parameters.time_axis,
                  _f0, Int32(parameters.f0_length), parameters.f0)
        // output: time_axis, f0
    }
}
