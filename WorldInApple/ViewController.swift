//
//  ViewController.swift
//  WorldInApple
//
//  Created by fuziki on 2020/02/08.
//  Copyright © 2020 factory.fuziki. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Charts

class ViewController: UIViewController {
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet weak var sliderStack: UIStackView!
    private var sliders: [UISlider] = []
    
    @IBOutlet weak var pitchLabel: UILabel!
    @IBAction func onPitchValueChanged(_ sender: UISlider) {
        pitchLabel.text = String(format: "%.5f", sender.value)
        worldInApple.set(pitch: Double(sender.value))
    }
    
    
    @IBOutlet weak var formantLabel: UILabel!
    @IBAction func onFormantValueChanged(_ sender: UISlider) {
        formantLabel.text = String(format: "%.5f", sender.value)
        worldInApple.set(formant: Double(sender.value))
    }
    
    private var iikanji: IikanjiEngine!
    let fs = 48000

    let worldInApple = WorldInApple(fs: 48000, frame_period: 5, x_length: 38400)
    
    private var oldBuff: AVAudioPCMBuffer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory( .playAndRecord, mode: .default, options: [.allowBluetoothA2DP, .allowBluetooth])
        try! AVAudioSession.sharedInstance().setPreferredSampleRate(Double(fs))
        try! session.setActive(true)
        
        chartView.chartDescription?.text = ""
        chartView.legend.enabled = false
        chartView.leftAxis.axisMaximum =  2.2
        chartView.leftAxis.axisMinimum = 0
        chartView.leftAxis.labelCount = 5
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.rightAxis.drawAxisLineEnabled = true
        chartView.xAxis.drawAxisLineEnabled = true
        chartView.rightAxis.drawLabelsEnabled = false
        chartView.rightAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawLabelsEnabled = false
        chartView.drawBordersEnabled = true
        
        
        for _ in 0..<10 {
            let slider = UISlider()
            slider.minimumValue = -48
            slider.maximumValue = 24
            slider.addTarget(self, action: #selector(self.onUpdateEQ(_:)), for: .valueChanged)
            slider.frame.size.width = sliderStack.frame.size.width
            sliderStack.addArrangedSubview(slider)
            sliders.append(slider)
        }

        
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
        
        iikanji.scheduleAudio(handler: { [weak self] (arr: [Float]) in
            DispatchQueue.main.async { [weak self] in
                func makeDataSet(_ floatArr: [Float]) -> LineChartDataSet {
                    var entry = [ChartDataEntry]()
                    for (i, d) in floatArr.enumerated() {
                        entry.append(ChartDataEntry(x: Double(i), y: Double(d)))
                    }
                    let dataSet = LineChartDataSet(entries: entry, label: "data")
                    dataSet.drawCirclesEnabled = false
                    return dataSet
                }
                self?.chartView.data = LineChartData(dataSet: makeDataSet(arr))
            }
        })
        
        iikanji.start()
    }
    
    let lockQueue = DispatchQueue(label: "factory.fuziki.lockQueue")
    private func onAudio(buffer: AVAudioPCMBuffer) {
        lockQueue.async { [weak self] in
            guard let ret = self?.worldInApple.conv(buffer: buffer) else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                self?.iikanji.scheduleBuffer(buffer: ret)
            }
        }
    }
    
    @objc func onUpdateEQ(_ sender: UISlider) {
        let value = sliders.map({$0.value})
        iikanji.update(eqValue: value)
    }
    
}
