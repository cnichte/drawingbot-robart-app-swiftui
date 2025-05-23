//
//  JobPropertiesPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

// JobPropertiesPanel.swift - Linker Bereich.
import SwiftUI

struct JobPropertiesPanel: View {
    @EnvironmentObject var model: SVGInspectorModel

    @EnvironmentObject var plotJobStore: GenericStore<JobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>
    
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                JobSectionView()
                    .padding(.horizontal, 0)
                
                MachineSectionView()
                    .padding(.horizontal, 0)
                
                MachinePenSectionView()
                    .padding(.horizontal, 0)
                
                SVGSectionView(svgFileName: $svgFileName,
                               showingFileImporter: $showingFileImporter)
                .padding(.horizontal, 0)
                
                PaperSectionView(onUpdate: saveCurrentJob)
                    .padding(.horizontal, 0)
                
                SignatureSectionView()
                    .padding(.horizontal, 0)
                
                ActionsSectionView()
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
            await model.save(using: plotJobStore)
        }
    }
}
