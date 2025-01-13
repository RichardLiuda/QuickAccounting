import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @StateObject private var settings = Settings.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("服务器设置")) {
                    TextField("服务器地址", text: $settings.serverHost)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("端口", text: $settings.serverPort)
                        .keyboardType(.numberPad)
                }
                
                Section(footer: Text("当前服务器地址：\(settings.serverURL)")) {
                    EmptyView()
                }
            }
            .navigationTitle("设置")
            .navigationBarItems(trailing:
                Button("完成") {
                    isPresented = false
                }
            )
        }
    }
} 