//
//   SettingsPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SettingsPanel.swift
import SwiftUI

struct SettingsPanel: View {
    @Binding var currentJob: PlotJobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var showSourcePreview: Bool

    @EnvironmentObject var store: GenericStore<PlotJobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormat>

    var showBottomBar: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                JobSectionView(currentJob: $currentJob)
                SVGSectionView(currentJob: $currentJob, svgFileName: $svgFileName, showingFileImporter: $showingFileImporter, showSourcePreview: $showSourcePreview)
                SignatureSectionView()
                PaperSectionView(currentJob: $currentJob, onUpdate: updateJob)
                PenSectionView()
                MachineSectionView(currentJob: $currentJob)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, showBottomBar ? 60 : 0)
        }
        .safeAreaInset(edge: .bottom) {
            if showBottomBar {
                bottomBarPlaceholder
            }
        }
    }

    @ViewBuilder
    private var bottomBarPlaceholder: some View {
        HStack {
            Spacer()
            Text("Optionale Bottom Bar")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func updateJob() {
        Task {
            await store.save(item: currentJob, fileName: currentJob.id.uuidString)
        }
    }
}
