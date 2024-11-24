//
//  ContentView.swift
//  Porkybank
//

import SwiftUI
import LiveViewNative

struct ContentView: View {
    var body: some View {
        LiveView(.automatic(URL(string: "http://localhost:4000/ios")!))
    }
}
