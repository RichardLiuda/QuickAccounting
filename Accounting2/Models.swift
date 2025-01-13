import Foundation

// 交易类型
enum TransactionType: String, Codable {
    case income = "income"
    case expense = "expense"
}

// 交易记录模型
struct Transaction: Codable, Identifiable, Equatable {
    let id: String?
    let amount: Double
    let type: String
    let category: String      // 用于发送请求
    let description: String?  // 用于接收响应
    let date: String?        // 格式: YYYY-MM-DD
    
    // 用于创建新交易的便利初始化器
    static func new(
        amount: Double,
        type: TransactionType,
        category: String,
        description: String? = nil,
        date: String? = nil
    ) -> Transaction {
        // 如果没有提供日期，使用今天的日期
        let dateString: String
        if let providedDate = date {
            dateString = providedDate
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateString = dateFormatter.string(from: Date())
        }
        
        return Transaction(
            id: nil,
            amount: amount,
            type: type.rawValue,
            category: category,
            description: description,
            date: dateString
        )
    }
    
    // 添加标准初始化器
    init(id: String?, amount: Double, type: String, category: String, description: String?, date: String?) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.description = description
        self.date = date
    }
    
    // 自定义编码，确保发送正确的字段
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(amount, forKey: .amount)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(date, forKey: .date)
    }
    
    // 自定义解码，处理后端返回的格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        type = try container.decode(String.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        
        // 从 description 字段获取分类信息
        if let desc = description {
            category = desc
        } else {
            category = ""
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, amount, type, category, description, date
    }
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.amount == rhs.amount &&
               lhs.category == rhs.category &&
               lhs.description == rhs.description &&
               lhs.date == rhs.date
    }
}

// 分类响应模型
struct CategoriesResponse: Codable {
    let expense_categories: [String]
    let income_categories: [String]
}

// 统计数据模型
struct Statistics: Codable {
    let total_income: Double
    let total_expense: Double
    let net: Double
    let transactions: [Transaction]
}

// API响应模型
struct APIResponse: Codable {
    let message: String
}

// API错误模型
struct APIError: Codable {
    let detail: String
}

// 验证错误模型
struct ValidationError: Codable {
    let detail: [ValidationDetail]
}

struct ValidationDetail: Codable {
    let loc: [String]
    let msg: String
    let type: String
}

// 设置模型
class Settings: ObservableObject {
    static let shared = Settings()
    
    @Published var serverHost: String {
        didSet {
            UserDefaults.standard.set(serverHost, forKey: "serverHost")
        }
    }
    
    @Published var serverPort: String {
        didSet {
            UserDefaults.standard.set(serverPort, forKey: "serverPort")
        }
    }
    
    var serverURL: String {
        "http://\(serverHost):\(serverPort)"
    }
    
    private init() {
        // 从 UserDefaults 读取保存的设置，如果没有则使用默认值
        self.serverHost = UserDefaults.standard.string(forKey: "serverHost") ?? "localhost"
        self.serverPort = UserDefaults.standard.string(forKey: "serverPort") ?? "8000"
    }
} 