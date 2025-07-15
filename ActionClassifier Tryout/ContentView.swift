import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ActionClassifierViewModel()

    var body: some View {
        ZStack {
            // Camera feed + pose overlay
            if let img = vm.frameImage {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                // Top‑left labels…
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.predictionLabel)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)

                        Text(vm.confidenceLabel)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 16)

                Spacer()

                // Bottom controls
                HStack {
                    // **Fixed** call here (no `$`) to your VM method:
                    Button {
                        vm.toggleCameraSelection()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button("Summary") {
                        vm.showSummary = true
                        vm.videoCapture.isEnabled = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
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
