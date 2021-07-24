//
//  ContentView.swift
//  Shared
//
//  Created by fuziki on 2021/05/08.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var vm = ContentViewModel()

    var body: some View {
        VStack {
            Text("Hello, world!")
            Text("Suggested to use earphones!")

            Spacer()

            Text("pitch: \(vm.pitch)")
            Slider(value: $vm.pitch,
                   in: 0.5...2,
                   minimumValueLabel: Text("0.5"),
                   maximumValueLabel: Text("2")) {
                EmptyView()
            }

            Spacer()

            Text("formant: \(vm.formant)")
            Slider(value: $vm.formant,
                   in: 0.5...2,
                   minimumValueLabel: Text("0.5"),
                   maximumValueLabel: Text("2")) {
                EmptyView()
            }
        }
        .frame(width: 200)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
