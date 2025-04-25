//
//   SettingsPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SettingsPanel.swift
import SwiftUI

struct SettingsPanel: View {
    @Binding var goToStep: Int
    @Binding var currentJob: PlotJobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var showSourcePreview: Bool

    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormat>

    var store: GenericStore<PlotJobData>
    var showBottomBar: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                JobSectionView(currentJob: $currentJob)
                SvgSectionView(
                    currentJob: $currentJob,
                    svgFileName: $svgFileName,
                    showingFileImporter: $showingFileImporter,
                    showSourcePreview: $showSourcePreview,
                    store: store
                )
                SignatureSectionView()
                PaperSectionView(currentJob: $currentJob)
                    .environmentObject(paperFormatsStore)
                PenSectionView()
                MachineSectionView(currentJob: $currentJob)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, showBottomBar ? 60 : 0)
        }
        .safeAreaInset(edge: .bottom) {
            if showBottomBar {
                bottomNavigationBar
            }
        }
    }

    private var bottomNavigationBar: some View {
        HStack {
            Button("Zurück") {
                goToStep = 1
            }
            Spacer()
            Button("Weiter") {
                goToStep = 3
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
