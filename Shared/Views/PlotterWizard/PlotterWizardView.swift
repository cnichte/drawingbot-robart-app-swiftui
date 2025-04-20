//
//  PlotterWizardView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

// PlotterWizardView.swift
import SwiftUI

import SwiftUI

public struct PlotterWizardView: View {
    @Binding var goToStep: Int
    @Binding var selectedJob: PlotJobData  // selectedJob als Binding

    @EnvironmentObject var store: GenericStore<PlotJobData>

    public var body: some View {
        VStack {
            // Navigiere zu den jeweiligen Steps
            if goToStep == 1 {
                JobListView(goToStep: $goToStep, selectedJob: $selectedJob) // Übergibt selectedJob an JobListView
            } else if goToStep == 2 {
                JobPreviewView(goToStep: $goToStep, currentJob: $selectedJob) // Übergibt selectedJob an JobPreviewView
            } else if goToStep == 3 {
                JobSummaryView(goToStep: $goToStep, currentJob: $selectedJob) // Übergibt selectedJob an JobSummaryView
            }
        }
    }
}
