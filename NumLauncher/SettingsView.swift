//
//  SettingsView.swift
//  NumLauncher
//
//  Created by Ethan John Lagera on 7/7/26.
//

import SwiftUI
import SwiftData

enum Modifier {
    case command
    case option
    case control
    
    var title: String {
        switch self {
            case .command:
            return "Command"
        case .option:
            return "Option"
        case .control:
            return "Control"
        }
    }
    
    var imageSymbol: String {
        switch self {
        case .command:
            return "command"
        case .option:
            return "option"
        case .control:
            return "control"
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Image(systemName: "number.sign")
                            .resizable()
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .foregroundStyle(.red)
                            )
                            .frame(width: 96, height: 96)
                        
                        Text("NumLauncher")
                            .font(.largeTitle)
                        
                        Text("Configure the quick shortcuts and the rest of the app here.")
                    }
                }
                
                Section(header: Text("Quick Shorcuts")) {
                    ForEach(1...10, id: \.self) { num in
                        let textNum = num == 10 ? 0 : num
                        shortcutConfig(modifier: .command, index: textNum)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("NumLauncher Settings")
        }
    }
    
    private func shortcutConfig(modifier: Modifier, index: Int) -> some View {
        HStack {
            Image(systemName: modifier.imageSymbol)
            Image(systemName: "plus")
            Text("\(index)")
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 12)
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .frame(maxWidth: 200, minHeight: 32)
        }
        .font(.title3)
        .fontWeight(.bold)
    }
}

#Preview {
    SettingsView()
        .frame(maxWidth: 360, maxHeight: 900)
}
