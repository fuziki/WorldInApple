//
//  ContentViewModel.swift
//  Examples
//
//  Created by fuziki on 2021/05/09.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI
import WorldInApple

class ContentViewModel: ObservableObject {
    
    private let world = WorldInApple(fs: 48000, frame_period: 5, x_length: 38400)
    
    private var iikanji: IikanjiEngine!
    private let fs = 48000

    private var oldBuff: AVAudioPCMBuffer? = nil
    
    @Published public var pitch: CGFloat = 1
    @Published public var formant: CGFloat = 1

    private var cancellables: Set<AnyCancellable> = []
    init() {
        $pitch
            .map { Double($0) }
            .sink { [weak self] (pitch: Double) in
                self?.world.set(pitch: pitch)
            }
            .store(in: &cancellables)
        
        $formant
            .map { Double($0) }
            .sink { [weak self] (formant: Double) in
                self?.world.set(formant: formant)
            }
            .store(in: &cancellables)
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory( .playAndRecord, mode: .default, options: [.allowBluetoothA2DP, .allowBluetooth])
        try! AVAudioSession.sharedInstance().setPreferredSampleRate(Double(fs))
        try! session.setActive(true)
        #endif
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                startEngine()
            
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.startEngine()
                        }
                    }
                }
            
            case .denied, .restricted:
                return
        @unknown default:
            return
        }
    }
    
    private func startEngine() {
        iikanji = IikanjiEngine()
        iikanji.convTapAudio(handler: { [weak self] (buffer: AVAudioPCMBuffer) in
//            self?.onAudio(buffer: buffer)
            
            guard let old = self?.oldBuff else {
                self?.oldBuff = buffer
                return
            }
            self?.onAudio(buffer: (old + buffer)!)
            self?.oldBuff = nil
        })
        
        iikanji.start()
    }
    
    let lockQueue = DispatchQueue(label: "factory.fuziki.lockQueue")
    private func onAudio(buffer: AVAudioPCMBuffer) {
        lockQueue.async { [weak self] in
            guard let ret = self?.world.conv(buffer: buffer) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.iikanji.scheduleBuffer(buffer: ret)
            }
        }
    }
}
