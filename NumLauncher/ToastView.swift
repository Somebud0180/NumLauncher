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
                .font(.subheadline)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.5)
            
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .symbolRenderingMode(.hierarchical)
                .padding(4)
        }
        .padding(8)
        .padding(.leading, 4)
        .frame(maxWidth: 192, maxHeight: 44)
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
