//
//  ContentView.swift
//  Shared
//
//  Created by fuziki on 2021/05/08.
//

import SwiftUI
import WorldInApple

class ContentViewModel {
    init() {
        let world = WorldInApple(fs: 0, frame_period: 0, x_length: 0)
    }
}

struct ContentView: View {
    let vm = ContentViewModel()
    
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
