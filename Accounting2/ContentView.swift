import SwiftUI

// 添加 ViewModel 来管理状态
class AccountingViewModel: ObservableObject {
    @Published var shouldRefreshStatistics = false
    
    func refreshStatistics() {
        shouldRefreshStatistics = true
        // 重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldRefreshStatistics = false
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AccountingViewModel()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 记账标签
            NavigationView {
                TransactionFormView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("记账")
            }
            .tag(0)
            
            // 统计标签
            StatisticsView(shouldRefresh: $viewModel.shouldRefreshStatistics)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
