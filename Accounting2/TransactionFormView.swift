import SwiftUI

struct TransactionFormView: View {
    @ObservedObject var viewModel: AccountingViewModel
    @State private var amount: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: String = APIConstants.expenseCategories[0]
    @State private var description: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSettings = false
    @State private var isSubmitting = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case amount
        case description
    }
    
    var categories: [String] {
        selectedType == .expense ? APIConstants.expenseCategories : APIConstants.incomeCategories
    }
    
    var isValidAmount: Bool {
        guard let amountDouble = Double(amount) else { return false }
        return amountDouble > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 类型选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("类型")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Picker("类型", selection: $selectedType) {
                        Text("支出").tag(TransactionType.expense)
                        Text("收入").tag(TransactionType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedType) { newValue in
                        print("📊 类型选择: \(newValue)")
                        selectedCategory = categories[0]
                    }
                }
                .padding(.horizontal)
                
                // 金额输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("金额")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("¥")
                            .font(.title)
                            .foregroundColor(.gray)
                        
                        TextField("0.00", text: $amount)
                            .font(.title)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .multilineTextAlignment(.leading)
                            .onChange(of: amount) { newValue in
                                print("💰 金额输入: \(newValue)")
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // 分类选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("分类")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                CategoryButton(
                                    title: category,
                                    isSelected: category == selectedCategory,
                                    action: {
                                        selectedCategory = category
                                        print("🏷️ 分类选择: \(category)")
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // 描述输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("描述（可选）")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    TextField("添加描述", text: $description)
                        .focused($focusedField, equals: .description)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onChange(of: description) { newValue in
                            print("📝 描述输入: \(newValue)")
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 提交按钮
                Button(action: submitTransaction) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidAmount ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isValidAmount)
                .padding()
            }
        }
        .navigationTitle("记账")
        .navigationBarItems(trailing:
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
            }
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView(isPresented: $showingSettings)
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {
                if alertMessage == "添加成功" {
                    print("✅ 记录添加成功，清空表单")
                    clearForm()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focusedField = nil
                }
            }
        }
    }
    
    private func clearForm() {
        withAnimation {
            amount = ""
            description = ""
            selectedType = .expense
            selectedCategory = APIConstants.expenseCategories[0]
            focusedField = .amount // 自动聚焦到金额输入框
        }
    }
    
    private func submitTransaction() {
        // 防止重复提交
        guard !isSubmitting else { return }
        
        print("🔄 提交交易记录")
        print("📊 当前表单数据:")
        print("- 金额: \(amount)")
        print("- 类型: \(selectedType)")
        print("- 分类: \(selectedCategory)")
        print("- 描述: \(description)")
        
        guard let amountDouble = Double(amount) else {
            print("❌ 金额格式无效")
            alertMessage = "请输入有效金额"
            showingAlert = true
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        // 开始提交
        isSubmitting = true
        
        Task {
            do {
                let transaction = Transaction.new(
                    amount: amountDouble,
                    type: selectedType,
                    category: selectedCategory,
                    description: description.isEmpty ? nil : description,
                    date: dateString
                )
                print("📤 准备发送交易记录: \(transaction)")
                
                let response = try await AccountingAPI.shared.addTransaction(transaction)
                print("✅ 交易记录添加成功: \(response)")
                
                // 立即清空金额和描述
                await MainActor.run {
                    amount = ""
                    description = ""
                    focusedField = .amount // 自动聚焦到金额输入框
                }
                
                // 刷新统计数据
                viewModel.refreshStatistics()
                
                // 显示成功提示
                alertMessage = "添加成功"
                showingAlert = true
            } catch {
                print("❌ 添加交易记录失败: \(error)")
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            
            // 重置提交状态
            isSubmitting = false
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    } 
}
