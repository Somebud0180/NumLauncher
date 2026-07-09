//
//  ToastView.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/9/26.
//

import SwiftUI

struct ToastView: View {
    @Binding var appName: String
    @Binding var appIcon: Image
    
    var body: some View {
        HStack {
            appIcon
                .resizable()
                .scaledToFit()
            
            Text("Launching \(appName)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Image(systemName: "progress.indicator")
                .resizable()
                .scaledToFit()
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                .padding(8)
        }
        .padding(16)
        .padding(.leading, 8)
        .frame(maxWidth: 288, maxHeight: 72)
        .background(
            Capsule(style: .continuous)
                .glassEffect()
        )
    }
}

#Preview {
    @Previewable @State var appName = "App"
    @Previewable @State var appIcon = Image(systemName: "app.grid")
    ToastView(appName: $appName, appIcon: $appIcon)
}
