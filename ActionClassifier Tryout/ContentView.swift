// File: ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ActionClassifierViewModel()

    var body: some View {
        ZStack {
            // Camera preview + pose overlay
            if let img = vm.frameImage {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                // Top‑left prediction + confidence
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.predictionLabel)
                            .font(.headline)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        Text(vm.confidenceLabel)
                            .font(.subheadline)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                    }
                    Spacer()
                }
                Spacer()
                // Bottom controls
                HStack {
                    Button {
                        vm.toggleCamera()
                    } label: {
                        Label("Camera", systemImage: "camera.rotate")
                    }
                    Spacer()
                    Button("Summary") {
                        vm.showSummary = true
                        vm.videoCapture.isEnabled = false
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
            }
        }
        .onAppear { vm.startSession() }
        .sheet(isPresented: $vm.showSummary) {
            SummaryView(actionFrameCounts: vm.actionFrameCounts) {
                vm.dismissSummary()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
