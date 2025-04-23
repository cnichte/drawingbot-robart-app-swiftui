//
//  ProjectFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

//  MARK: - ProjectFormView.swift (bleibt bestehen, leicht angepasst)
import SwiftUI

struct ProjectFormView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var plotJobStore: GenericStore<PlotJobData>

    @Binding var data: ProjectData
    @State private var showJobPicker = false

    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $data.name)
                        .onChange(of: data.name) { save() }

                    TextEditor(text: $data.description)
                        .frame(minHeight: 100)
                        .onChange(of: data.description) { save() }
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
                                assignedJobs: data.jobs,
                                onSelect: { job in
                                    data.jobs.append(job)
                                    save()
                                    showJobPicker = false
                                },
                                onCancel: {
                                    showJobPicker = false
                                }
                            )
                        }

                        if data.jobs.isEmpty {
                            Text("Keine zugewiesen")
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(data.jobs) { job in
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

                                    if job.id != data.jobs.last?.id {
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
        data.jobs.removeAll { $0.id == job.id }
        save()
    }

    private func save() {
        Task {
            await projectStore.save(item: data, fileName: data.id.uuidString)
        }
    }
}
