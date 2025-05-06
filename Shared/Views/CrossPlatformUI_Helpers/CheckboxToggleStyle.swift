//
//  CheckboxToggleStyle.swift
//  Robart
//
//  Created by Carsten Nichte on 05.05.25.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    withAnimation(.spring()) {
                        configuration.isOn.toggle()
                    }
                }
            configuration.label
        }
    }
}

struct CheckboxToggleStyle_ExampleView: View {
    @State private var isChecked = false

    var body: some View {
        VStack {
            Toggle("Option", isOn: $isChecked)
                .toggleStyle(CheckboxToggleStyle())
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxToggleStyle_ExampleView()
    }
}
