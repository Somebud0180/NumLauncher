//
//  ToastView.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/9/26.
//

import SwiftUI

struct ToastView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var model: ToastModel
    @State private var isVisible = false
    @State private var symbolVisible = false
    
    var body: some View {
        HStack {
            model.appIcon
                .resizable()
                .scaledToFit()
            
            Text(model.success != false ? "Launching \(model.appName)" : "App not found")
                .font(.subheadline)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.5)
            
            Spacer()
            
            if let success = model.success {
                Image(systemName: success ? "checkmark.circle" : "xmark.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(success ? Color.primary.gradient : Color.red.gradient)
                        .symbolRenderingMode(.hierarchical)
                        .symbolAppearAnimation(isActive: !symbolVisible)
                        .padding(4)
                        .onAppear {
                            symbolVisible = true
                        }
                        .onDisappear {
                            symbolVisible = false
                        }
            }
        }
        .padding(8)
        .padding(.leading, 4)
        .frame(maxWidth: 192, maxHeight: 44)
        .background(
            Capsule(style: .continuous)
                .foregroundStyle(.ultraThinMaterial)
        )
        .scaleEffect(isVisible ? 1.0 : 0.98)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.9, blendDuration: 0.1), value: isVisible)
        .onChange(of: model.appName) {
            isVisible = !model.appName.isEmpty
        }
        .onAppear {
            isVisible = !model.appName.isEmpty
        }
        .preferredColorScheme(settings.preferredColorScheme.colorScheme)
    }
}

struct SymbolAnimationModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.symbolEffect(.drawOn, isActive: isActive)
        } else {
            content.symbolEffect(.appear, isActive: isActive)
        }
    }
}

extension View {
    func symbolAppearAnimation(isActive: Bool) -> some View {
        modifier(SymbolAnimationModifier(isActive: isActive))
    }
}

#Preview {
    let model = ToastModel()
    ToastView(model: model)
}
