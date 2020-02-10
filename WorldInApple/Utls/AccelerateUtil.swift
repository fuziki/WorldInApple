//
//  AccelerateUtil.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/08.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Accelerate
import Foundation

class AccelerateUtil {
    static var shareFFTSetup: FFTSetup = vDSP_create_fftsetup(10, Int32(kFFTRadix2))!
    static public func fft(_ data: [Float]) -> DSPSplitComplex {
        var windowed = Self.multiplyWindow(data)
        var data_i = [Float](repeating: 0, count: data.count)
        var ans = DSPSplitComplex(realp: &windowed, imagp: &data_i)
        let indata:UnsafePointer<DSPComplex> = UnsafeRawPointer(windowed).bindMemory(to: DSPComplex.self, capacity: data.count)
        vDSP_ctoz(indata, 2, &ans, 1, vDSP_Length(data.count / 2))
        vDSP_fft_zrip(shareFFTSetup, &ans, 1, vDSP_Length(log2(Double(data.count))), Int32(Accelerate.FFT_FORWARD))
        return ans
    }
    static public func ifft(_ data: [Float]) -> [Float] {
        var data_r = data
        var data_i = [Float](repeating: 0, count: data.count)
        var indata = DSPSplitComplex(realp: &data_r, imagp: &data_i)
        let ans = UnsafeMutablePointer<DSPComplex>.allocate(capacity: data.count)
        vDSP_fft_zrip(shareFFTSetup, &indata, 1, vDSP_Length(log2(Double(data.count * 2))), FFTDirection(FFT_INVERSE))
        vDSP_ztoc(&indata, 1, ans, 2, vDSP_Length(data.count))
        let floatP = UnsafeRawPointer(ans).bindMemory(to: Float.self, capacity: data.count * 2)
        let rst = Array(UnsafeBufferPointer(start:floatP, count: data.count * 2)[0..<data.count])
        return rst
    }
    enum WindowType {
        case hann
        case hamming
        case blackman
    }
    static public func multiplyWindow(_ data: [Float], type: WindowType = .hann) -> [Float] {
        var indata = data
        var windowData = [Float](repeating: 0, count: indata.count)
        switch type {
        case .hann:
            vDSP_hann_window(&windowData, vDSP_Length(indata.count), Int32(0)) //vDSP_blkman_window
        case .hamming:
            vDSP_hamm_window(&windowData, vDSP_Length(indata.count), Int32(0))
        case .blackman:
            vDSP_blkman_window(&windowData, vDSP_Length(indata.count), Int32(0))
        }
        var ans = [Float](repeating: 0, count: indata.count)
        vDSP_vmul(&indata, 1, &windowData, 1, &ans, 1, vDSP_Length(indata.count))
        return ans
    }
}
