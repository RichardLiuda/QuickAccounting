import Foundation

enum AccountingError: LocalizedError {
    case networkError(String)
    case validationError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .validationError(let message):
            return "验证错误: \(message)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        }
    }
}

struct APIConstants {
    static let baseURL = "http://localhost:8000"
    
    // 预定义分类
    static let expenseCategories = ["餐饮", "交通", "购物", "娱乐", "其他"]
    static let incomeCategories = ["工资", "生活费", "其他收入"]
}

class AccountingAPI {
    static let shared = AccountingAPI()
    
    private var baseURL: String {
        Settings.shared.serverURL
    }
    
    // MARK: - 获取分类
    func fetchCategories() async throws -> CategoriesResponse {
        print("📡 开始获取分类")
        guard let url = URL(string: "\(baseURL)/categories/") else {
            print("❌ URL无效: \(baseURL)/categories/")
            throw AccountingError.networkError("无效的URL")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("📡 Response Headers: \(String(describing: (response as? HTTPURLResponse)?.allHeaderFields))")
            print("📡 Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    print("✅ 获取分类成功")
                    return try JSONDecoder().decode(CategoriesResponse.self, from: data)
                case 422:
                    let validationError = try JSONDecoder().decode(ValidationError.self, from: data)
                    let errorMessage = validationError.detail.map { $0.msg }.joined(separator: ", ")
                    print("❌ 验证错误: \(errorMessage)")
                    throw AccountingError.validationError(errorMessage)
                default:
                    let errorResponse = try? JSONDecoder().decode(APIError.self, from: data)
                    let errorMessage = errorResponse?.detail ?? "未知错误"
                    print("❌ 服务器错误: \(errorMessage)")
                    throw AccountingError.serverError(errorMessage)
                }
            }
            
            throw AccountingError.networkError("无效的响应")
        } catch {
            print("❌ 获取分类失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 添加交易记录
    func addTransaction(_ transaction: Transaction) async throws -> APIResponse {
        print("📡 开始添加交易记录: \(transaction)")
        guard let url = URL(string: "\(baseURL)/transaction/") else {
            print("❌ URL无效: \(baseURL)/transaction/")
            throw AccountingError.networkError("无效的URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(transaction)
            request.httpBody = jsonData
            print("📤 Request URL: \(request.url?.absoluteString ?? "")")
            print("📤 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
            print("📤 Request Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            print("📡 Response Headers: \(String(describing: (response as? HTTPURLResponse)?.allHeaderFields))")
            print("📡 Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200, 201:
                    print("✅ 添加交易记录成功")
                    let response = try JSONDecoder().decode(APIResponse.self, from: data)
                    print("✅ 服务器响应: \(response.message)")
                    return response
                case 422:
                    let validationError = try JSONDecoder().decode(ValidationError.self, from: data)
                    let errorMessage = validationError.detail.map { $0.msg }.joined(separator: ", ")
                    print("❌ 验证错误: \(errorMessage)")
                    throw AccountingError.validationError(errorMessage)
                default:
                    if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                        print("❌ 服务器错误: \(errorResponse.detail)")
                        throw AccountingError.serverError(errorResponse.detail)
                    } else {
                        print("❌ 未知错误")
                        throw AccountingError.serverError("未知错误")
                    }
                }
            }
            
            throw AccountingError.networkError("无效的响应")
        } catch let decodingError as DecodingError {
            print("❌ 解码错误: \(decodingError)")
            throw AccountingError.serverError("响应格式错误")
        } catch {
            print("❌ 添加交易记录失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 删除交易记录
    func deleteTransaction(id: String) async throws -> APIResponse {
        print("📡 开始删除交易记录: \(id)")
        guard let url = URL(string: "\(baseURL)/transaction/\(id)") else {
            print("❌ URL无效: \(baseURL)/transaction/\(id)")
            throw AccountingError.networkError("无效的URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("📡 Response Headers: \(String(describing: (response as? HTTPURLResponse)?.allHeaderFields))")
            print("📡 Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200, 201:
                    print("✅ 删除交易记录成功")
                    let response = try JSONDecoder().decode(APIResponse.self, from: data)
                    print("✅ 服务器响应: \(response.message)")
                    return response
                case 422:
                    let validationError = try JSONDecoder().decode(ValidationError.self, from: data)
                    let errorMessage = validationError.detail.map { $0.msg }.joined(separator: ", ")
                    print("❌ 验证错误: \(errorMessage)")
                    throw AccountingError.validationError(errorMessage)
                default:
                    if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                        print("❌ 服务器错误: \(errorResponse.detail)")
                        throw AccountingError.serverError(errorResponse.detail)
                    } else {
                        print("❌ 未知错误")
                        throw AccountingError.serverError("未知错误")
                    }
                }
            }
            
            throw AccountingError.networkError("无效的响应")
        } catch let decodingError as DecodingError {
            print("❌ 解码错误: \(decodingError)")
            throw AccountingError.serverError("响应格式错误")
        } catch {
            print("❌ 删除交易记录失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 获取统计数据
    func getStatistics(periodType: String, period: String) async throws -> Statistics {
        print("📡 开始获取统计数据: periodType=\(periodType), period=\(period)")
        guard let url = URL(string: "\(baseURL)/statistics/\(periodType)/\(period)") else {
            print("❌ URL无效: \(baseURL)/statistics/\(periodType)/\(period)")
            throw AccountingError.networkError("无效的URL")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print("📡 Response Headers: \(String(describing: (response as? HTTPURLResponse)?.allHeaderFields))")
            print("📡 Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    print("✅ 获取统计数据成功")
                    return try JSONDecoder().decode(Statistics.self, from: data)
                case 422:
                    let validationError = try JSONDecoder().decode(ValidationError.self, from: data)
                    let errorMessage = validationError.detail.map { $0.msg }.joined(separator: ", ")
                    print("❌ 验证错误: \(errorMessage)")
                    throw AccountingError.validationError(errorMessage)
                default:
                    let errorResponse = try? JSONDecoder().decode(APIError.self, from: data)
                    let errorMessage = errorResponse?.detail ?? "未知错误"
                    print("❌ 服务器错误: \(errorMessage)")
                    throw AccountingError.serverError(errorMessage)
                }
            }
            
            throw AccountingError.networkError("无效的响应")
        } catch {
            print("❌ 获取统计数据失败: \(error)")
            throw error
        }
    }
} 