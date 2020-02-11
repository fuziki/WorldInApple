//
//  AVAudioPCMBuffer+Extension.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/08.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioPCMBuffer {
    static func +(l: AVAudioPCMBuffer, r: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        if l.format != r.format {
            return nil
        }
        
        let frameCapacity = l.frameLength + r.frameLength
        
        let ret = AVAudioPCMBuffer(pcmFormat: l.format, frameCapacity: frameCapacity)!
        ret.frameLength = ret.frameCapacity
        
        let src_l: UnsafeRawPointer = UnsafeRawPointer((l.audioBufferList.pointee.mBuffers.mData)!)
        let src_r: UnsafeRawPointer = UnsafeRawPointer((r.audioBufferList.pointee.mBuffers.mData)!)

        let len_l = Int(l.audioBufferList.pointee.mBuffers.mDataByteSize)
        let len_r = Int(r.audioBufferList.pointee.mBuffers.mDataByteSize)

        let dst_l: UnsafeMutableRawPointer = (ret.audioBufferList.pointee.mBuffers.mData)!
        let dst_r: UnsafeMutableRawPointer = (ret.audioBufferList.pointee.mBuffers.mData?.advanced(by: len_l))!
        memcpy(dst_l, src_l, len_l)
        memcpy(dst_r, src_r, len_r)
        
        return ret
    }
}
