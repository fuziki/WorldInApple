//
//  WorldInAppleParameters.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/09.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation

public class WorldInAppleParameters {
    private(set) var fs: Int
    private(set) var frame_period: Double
    
    private var prev_x_length: Int

    private(set) var f0_length: Int
    private(set) var fft_size: Int

    private(set) var f0: UnsafeMutablePointer<Double>
    private(set) var time_axis: UnsafeMutablePointer<Double>
    
    private(set) var spectrogram: UnsafeMutablePointer<UnsafeMutablePointer<Double>?>
    private(set) var aperiodicity: UnsafeMutablePointer<UnsafeMutablePointer<Double>?>

    public init(fs: Int, frame_period: Double, x_length: Int) {
        self.fs = fs
        self.frame_period = frame_period
        self.prev_x_length = x_length
        
        f0_length = Int(GetSamplesForDIO(Int32(fs), Int32(x_length), frame_period))
        var cheapOption = CheapTrickOption()
        InitializeCheapTrickOption(Int32(fs), &cheapOption)
        cheapOption.f0_floor = 71
        
        fft_size = Int(GetFFTSizeForCheapTrick(Int32(fs), &cheapOption))
        
        f0 = UnsafeMutablePointer<Double>.allocate(capacity: Int(f0_length))
        time_axis = UnsafeMutablePointer<Double>.allocate(capacity: Int(f0_length))

        spectrogram = UnsafeMutablePointer<UnsafeMutablePointer<Double>?>.allocate(capacity: Int(f0_length))
        for i in 0..<f0_length {
            spectrogram.advanced(by: Int(i)).pointee = UnsafeMutablePointer<Double>.allocate(capacity: Int(fft_size / 2 + 1))
        }

        aperiodicity = UnsafeMutablePointer<UnsafeMutablePointer<Double>?>.allocate(capacity: Int(f0_length))
        for i in 0..<f0_length {
            aperiodicity.advanced(by: Int(i)).pointee = UnsafeMutablePointer<Double>.allocate(capacity: Int(fft_size / 2 + 1))
        }
    }
}
