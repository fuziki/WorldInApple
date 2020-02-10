//
//  ParameterModification.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/09.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import Accelerate

public class ParameterModification: WorldInAppleComponents {
    private var parameters: WorldInAppleParameters

    private var freq_axis1: UnsafeMutablePointer<Double>
    private var freq_axis2: UnsafeMutablePointer<Double>
    private var spectrum1: UnsafeMutablePointer<Double>
    private var spectrum2: UnsafeMutablePointer<Double>
    
    private var pitch: Double = 1
    private var formant: Double = 1
    
    required public init(parameters: WorldInAppleParameters) {
        self.parameters = parameters
        
        let size =  parameters.fft_size / 2 + 1
        freq_axis1 = UnsafeMutablePointer<Double>.allocate(capacity: Int(size))
        freq_axis2 = UnsafeMutablePointer<Double>.allocate(capacity: Int(size))
        spectrum1 = UnsafeMutablePointer<Double>.allocate(capacity: Int(size))
        spectrum2 = UnsafeMutablePointer<Double>.allocate(capacity: Int(size))
        for i in 0..<size {
            let t = Double(i) / Double(parameters.fft_size) * Double(parameters.fs)
            freq_axis2.advanced(by: Int(i)).pointee = t
        }
        self.set(pitch: 1, formant: 1)
    }
    
    public func set(pitch: Double?, formant: Double?) {
        if let p = pitch {
            self.pitch = p
        }
        
        if let f = formant {
            self.formant = f
            let size = Int32(parameters.fft_size / 2 + 1)
            cblas_dcopy(size, freq_axis2, 1, freq_axis1, 1)
            cblas_dscal(size, f, freq_axis1, 1)
        }
    }
    
    public func modificate() {
        cblas_dscal(Int32(parameters.f0_length), pitch, parameters.f0, 1) //f0 * pitch
        
        for i in 0..<parameters.f0_length {
            var size = Int32(parameters.fft_size / 2 + 1)
            vvlog(spectrum1, parameters.spectrogram.advanced(by: i).pointee!, &(size))
            interp1(freq_axis1, spectrum1, Int32(parameters.fft_size / 2 + 1), freq_axis2, Int32(parameters.fft_size / 2 + 1), spectrum2)
            vvexp(parameters.spectrogram.advanced(by: i).pointee!, spectrum2, &(size))
            if formant >= 0.9999 {
                continue
            }
            let start_j: Int = Int(Double(parameters.fft_size) / 2.0 * formant)
            let alt = parameters.spectrogram.advanced(by: i).pointee!.advanced(by: Int(start_j - 1)).pointee
            for j in start_j..<Int(parameters.fft_size / 2 + 1) {
                parameters.spectrogram.advanced(by: i).pointee!.advanced(by: Int(j)).pointee = alt
            }
        }
    }
    
}
