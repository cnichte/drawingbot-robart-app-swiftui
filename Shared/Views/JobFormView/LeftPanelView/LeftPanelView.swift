//
//  LeftPanelView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.05.25.
//

// LeftPanelView.swift
import SwiftUI

struct LeftPanelView: View {
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
                
                SignatureSectionView().padding(.horizontal, 0)
                
                ActionsSectionView()
                    .padding(.horizontal, 0)
                
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gray.opacity(0.05))
        .frame(maxWidth: 300)
        .padding(.vertical, 10)
    }
    
    private func saveCurrentJob() {
        // appLog(.info, "onUpdate called with paperFormatID: \(model.jobBox.paperDataID?.uuidString ?? "nil")")
        // Task { await model.save(using: plotJobStore)}
    }
    
}


