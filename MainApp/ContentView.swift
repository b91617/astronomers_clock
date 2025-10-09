//
//  ContentView.swift
//  Astronomer's Clock
//
//  Created by Justin Cheng on 2025/10/9.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "hammer.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Here should be a date/JD/MJD converter but now still under developing.")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
