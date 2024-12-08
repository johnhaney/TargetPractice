//
//  ContentView.swift
//  TargetPractice
//
//  Created by John Haney on 10/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Start the immersive space to reveal the target in front of you.")
            Text("(It might be behind this window)")
                .padding(.bottom)
            Text("👉 Point and bend your thumb to fire at the target 👈")

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
