//
//  ProjectFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

// MARK: - ProjectFormView
import SwiftUI

struct ProjectFormView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var plotJobStore: GenericStore<PlotJobData>
    
    @Binding var project: ProjectData
    @State private var showJobPicker = false
    
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $project.name)
                        .onChange(of: project.name) { save() }

                    TextEditor(text: $project.description)
                        .frame(minHeight: 100)
                        .onChange(of: project.description) { save() }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2))
                        )
                }
            }
            Section {
                HStack(alignment: .top) {
                    Text("Jobs")
                        .frame(minWidth: 80, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        
                        
                        Button {
                            showJobPicker = true
                        } label: {
                            Label("Job zuweisen", systemImage: "plus")
                        }
                        .buttonStyleLinkIfAvailable()
                        .sheet(isPresented: $showJobPicker) {
                            JobPickerSheet(
                                allJobs: plotJobStore.items,
                                assignedJobs: project.jobs,
                                onSelect: { job in
                                    project.jobs.append(job)
                                    save()
                                    showJobPicker = false
                                },
                                onCancel: {
                                    showJobPicker = false
                                }
                            )
                        }
                        .buttonStyleLinkIfAvailable()
                        
                        
                        
                        

                        if project.jobs.isEmpty {
                            Text("Keine zugewiesen")
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(project.jobs) { job in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(job.name)
                                                .bold()
                                            if !job.description.isEmpty {
                                                Text(job.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            removeJob(job)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding()

                                    if job.id != project.jobs.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(ColorHelper.backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Projekt bearbeiten")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Zurück", action: onBack)
            }
            #endif
        }
    }

    private func removeJob(_ job: PlotJobData) {
        project.jobs.removeAll { $0.id == job.id }
        save()
    }
    
    private func save() {
        Task {
            await projectStore.save(item: project, fileName: project.id.uuidString)
        }
    }
}
