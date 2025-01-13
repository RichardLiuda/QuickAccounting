import SwiftUI

struct StatisticsView: View {
    @State private var statistics: Statistics?
    @State private var periodType = "month"
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Binding var shouldRefresh: Bool
    @State private var animateCards = false
    @Namespace private var animation
    @State private var showingSettings = false
    
    var period: String {
        let formatter = DateFormatter()
        
        switch periodType {
        case "year":
            formatter.dateFormat = "yyyy"
        case "month":
            formatter.dateFormat = "yyyy-MM"
        default:
            formatter.dateFormat = "yyyy-MM-dd"
        }
        
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    // 时间选择器
                    Picker("统计周期", selection: $periodType.animation()) {
                        Text("年").tag("year")
                        Text("月").tag("month")
                        Text("日").tag("day")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if periodType == "day" {
                        DatePicker("选择日期",
                                 selection: $selectedDate,
                                 displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        DatePicker("选择日期",
                                 selection: $selectedDate,
                                 displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .disabled(true)
                            .opacity(0)
                            .frame(height: 0)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .transition(.scale.combined(with: .opacity))
                    } else if let stats = statistics {
                        // 统计卡片
                        HStack(spacing: 12) {
                            StatCard(
                                title: "收入",
                                amount: stats.total_income,
                                color: .green,
                                icon: "arrow.down.circle.fill"
                            )
                            .matchedGeometryEffect(id: "income", in: animation)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            
                            StatCard(
                                title: "支出",
                                amount: stats.total_expense,
                                color: .red,
                                icon: "arrow.up.circle.fill"
                            )
                            .matchedGeometryEffect(id: "expense", in: animation)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            
                            StatCard(
                                title: "结余",
                                amount: stats.net,
                                color: stats.net >= 0 ? .blue : .red,
                                icon: "equal.circle.fill"
                            )
                            .matchedGeometryEffect(id: "net", in: animation)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        }
                        .padding(.horizontal)
                        
                        // 交易记录列表
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(stats.transactions.indices, id: \.self) { index in
                                    let transaction = stats.transactions[index]
                                    TransactionRow(transaction: transaction)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                print("🗑️ 准备删除交易记录: \(transaction.id ?? "")")
                                                deleteTransaction(id: transaction.id ?? "")
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                        .opacity(animateCards ? 1 : 0)
                                        .offset(y: animateCards ? 0 : 50)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateCards)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .opacity(isLoading ? 0.3 : 1.0)
                
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                }
            }
            .navigationTitle("统计")
            .navigationBarItems(trailing: 
                HStack(spacing: 16) {
                    Button(action: {
                        print("🔄 手动刷新统计数据")
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            fetchStatistics()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .onAppear {
            print("📊 统计视图出现")
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                fetchStatistics()
            }
        }
        .onChange(of: period) { newValue in
            print("📅 统计周期改变: \(newValue)")
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                fetchStatistics()
            }
        }
        .onChange(of: shouldRefresh) { newValue in
            if newValue {
                print("🔄 收到外部刷新请求")
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    fetchStatistics()
                }
            }
        }
    }
    
    private func fetchStatistics() {
        print("🔄 开始获取统计数据")
        print("- 周期类型: \(periodType)")
        print("- 时间: \(period)")
        
        animateCards = false
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let stats = try await AccountingAPI.shared.getStatistics(
                    periodType: periodType,
                    period: period
                )
                
                statistics = Statistics(
                    total_income: stats.total_income,
                    total_expense: stats.total_expense,
                    net: stats.net,
                    transactions: stats.transactions.sorted { ($0.date ?? "") > ($1.date ?? "") }
                )
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateCards = true
                }
                
                print("✅ 统计数据获取成功")
                if let stats = statistics {
                    print("📊 统计结果:")
                    print("- 总收入: \(stats.total_income)")
                    print("- 总支出: \(stats.total_expense)")
                    print("- 结余: \(stats.net)")
                    print("- 交易记录数: \(stats.transactions.count)")
                }
            } catch {
                print("❌ 获取统计数据失败: \(error)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func deleteTransaction(id: String) {
        print("🗑️ 开始删除交易记录: \(id)")
        Task {
            do {
                let response = try await AccountingAPI.shared.deleteTransaction(id: id)
                print("✅ 删除成功: \(response)")
                await fetchStatistics()
            } catch {
                print("❌ 删除失败: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("¥\(amount, specifier: "%.2f")")
                .font(.headline)
                .bold()
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(10)
        .shadow(color: Color(uiColor: .systemGray4).opacity(0.3), radius: 3, x: 0, y: 1)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(transaction.type == "income" ? 
                          Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1) : 
                          Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.type == "income" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundColor(transaction.type == "income" ? .green : .red)
            }
            
            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let date = transaction.date {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧金额
            Text("¥\(transaction.amount, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(uiColor: .systemGray4).opacity(colorScheme == .dark ? 0.5 : 0.2), 
                radius: colorScheme == .dark ? 4 : 2,
                x: 0, 
                y: colorScheme == .dark ? 2 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: transaction)
    }
}

// 加载动画视图
struct LoadingView: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // 背景模糊效果
            Color(uiColor: .systemBackground)
                .opacity(0.8)
                .blur(radius: 3)
            
            // 加载动画
            VStack(spacing: 15) {
                ZStack {
                    // 外圈旋转动画
                    Circle()
                        .stroke(
                            Color.accentColor.opacity(0.3),
                            lineWidth: 3
                        )
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round
                            )
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 0.8)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                Text("加载中")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(0.8)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(
                                color: Color(uiColor: .systemGray4).opacity(colorScheme == .dark ? 0.3 : 0.2),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
} 