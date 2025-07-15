// File: SummaryView.swift

import SwiftUI

struct SummaryView: View {
    let actionFrameCounts: [String: Int]
    let onDismiss: () -> Void

    private var sortedActions: [String] {
        actionFrameCounts
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(sortedActions, id: \.self) { action in
                    HStack {
                        Text(action)
                        Spacer()
                        Text(String(format: "%.1fs",
                                    Double(actionFrameCounts[action] ?? 0)
                                        / ExerciseClassifier.frameRate))
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(actionFrameCounts: ["Jumping Jacks": 300], onDismiss: {})
    }
}
