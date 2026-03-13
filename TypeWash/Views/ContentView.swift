import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case editor = "Editor"
    case history = "History"

    var icon: String {
        switch self {
        case .editor:  return "doc.text.magnifyingglass"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .editor

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .editor:
            EditorView()
        case .history:
            HistoryListView()
        }
    }
}
