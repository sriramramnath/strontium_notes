//
//  ContentView.swift
//  Strontium Notes
//
//  Created by Sriram Ramnath on 29/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VSCodeStyleView(appViewModel: appViewModel)
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            appViewModel.createNewNote()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            appViewModel.selectedSidebarItem = .search
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCommandPalette)) { _ in
            appViewModel.showCommandPalette = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            appViewModel.showRightSidebar.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .setLightMode)) { _ in
            themeManager.setTheme(.light)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setDarkMode)) { _ in
            themeManager.setTheme(.dark)
        }
        .onReceive(NotificationCenter.default.publisher(for: .setSystemTheme)) { _ in
            themeManager.setTheme(nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .splitHorizontal)) { _ in
            appViewModel.splitPaneHorizontally()
        }
        .onReceive(NotificationCenter.default.publisher(for: .splitVertical)) { _ in
            appViewModel.splitPaneVertically()
        }
        .sheet(item: $appViewModel.presentedSheet) { sheet in
            switch sheet {
            case .vaultPicker:
                ObsidianVaultPickerView(appViewModel: appViewModel)
            case .createVault:
                ObsidianCreateVaultView(appViewModel: appViewModel)
            case .preferences:
                ObsidianPreferencesView(appViewModel: appViewModel)
            case .about:
                ObsidianAboutView()
            case .renameNote:
                EmptyView() // Handled in VSCodeStyleView
            case .createFolder:
                EmptyView() // Handled in VSCodeStyleView
            case .upgrade:
                EmptyView() // Handled in VSCodeStyleView
            }
        }

        .errorAlert(error: $appViewModel.currentError, isPresented: $appViewModel.showError)
    }
}

#Preview {
    ContentView()
}
