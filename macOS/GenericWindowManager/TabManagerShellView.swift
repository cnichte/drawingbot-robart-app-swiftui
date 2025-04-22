//
//  TabManagerShellView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//
#if os(macOS)
import SwiftUI

struct TabManagerShellView: View {
    let configs: [TabbedViewConfig]
    @State private var selectedTabIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if configs.count > 1 {
                Picker("Tabs", selection: $selectedTabIndex) {
                    ForEach(0..<configs.count, id: \.self) { index in
                        Text(configs[index].title).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }

            Divider()

            configs[selectedTabIndex].view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
#endif
