// File: ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ActionClassifierViewModel()

    var body: some View {
        ZStack {
            // MARK: – Camera preview + skeleton overlay
            GeometryReader { geo in
                if let img = vm.frameImage {
                    Image(decorative: img, scale: 1.0)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .overlay(
                            // draw wireframe over the camera
                            Canvas { context, size in
                                guard let poses = vm.detectedPoses else { return }
                                context.withCGContext { cg in
                                    // scale normalized landmarks into full view
                                    let scaleX = size.width
                                    let scaleY = size.height
                                    let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                                    for pose in poses {
                                        pose.drawWireframeToContext(cg,
                                                                    applying: transform)
                                    }
                                }
                            }
                            .allowsHitTesting(false)
                        )
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()

            // MARK: – Prediction labels + controls
            VStack {
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
                HStack {
                    Button {
                        vm.toggleCamera()
                    } label: {
                        Label("Camera", systemImage: "camera.rotate")
                    }
                    Spacer()
                    Button("Summary") {
                        vm.showSummary = true
                        vm.pauseSession()
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
            }
        }
        .onAppear {
            vm.startSession()
        }
        .sheet(isPresented: $vm.showSummary) {
            SummaryView(actionFrameCounts: vm.actionFrameCounts) {
                vm.showSummary = false
                vm.resumeSession()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
