//
//  TabbedViewConfig.swift
//  Robart
//
//  Created by Carsten Nichte on 21.04.25.
//

// TabbedViewConfig.swift
#if os(macOS)
import SwiftUI

struct TabbedViewConfig {
    let title: String
    let view: AnyView
    let environmentObjects: [AnyViewModifier]

    init<V: View>(
        title: String,
        view: V,
        environmentObjects: [AnyViewModifier] = []
    ) {
        var modifiedView: AnyView = AnyView(view)
        for modifier in environmentObjects {
            modifiedView = AnyView(modifier.apply(to: modifiedView))
        }
        self.title = title
        self.view = modifiedView
        self.environmentObjects = environmentObjects
    }
}
#endif
