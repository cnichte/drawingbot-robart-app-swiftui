//
//  JobSettingsPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

// JobSettingsPanel.swift - Linker Bereich.
import SwiftUI

struct JobSettingsPanel: View {
    @Binding var currentJob: PlotJobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var selectedMachine: MachineData?
    
    @EnvironmentObject var plotJobStore: GenericStore<PlotJobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormat>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                JobSectionView(currentJob: $currentJob)
                    .padding(.horizontal, 0)

                SVGSectionView(
                    currentJob: $currentJob,
                    svgFileName: $svgFileName,
                    showingFileImporter: $showingFileImporter,
                )
                .padding(.horizontal, 0)

                PaperSectionView(currentJob: $currentJob, onUpdate: saveCurrentJob)
                    .padding(.horizontal, 0)

                SignatureSectionView(currentJob: $currentJob)
                    .padding(.horizontal, 0)
                
                MachineSectionView(currentJob: $currentJob, selectedMachine: $selectedMachine)
                    .padding(.horizontal, 0)
                
                PenSectionView(currentJob: $currentJob, selectedMachine: $selectedMachine)
                    .padding(.horizontal, 0)
                
                ActionsSectionView(currentJob: $currentJob)
                    .padding(.horizontal, 0)
                
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private func saveCurrentJob() {
        Task {
            await plotJobStore.save(item: currentJob, fileName: currentJob.id.uuidString)
        }
    }
}
