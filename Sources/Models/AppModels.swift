import Foundation

// MARK: - 基础枚举

/// 角色卡稀有度
enum Rarity: String, Codable, CaseIterable, Identifiable {
    case n = "N"
    case r = "R"
    case sr = "SR"
    case ssr = "SSR"

    var id: String { rawValue }

    /// 抽取权重（V1 初始参数，可调）
    var weight: Double {
        switch self {
        case .n: 0.60
        case .r: 0.25
        case .sr: 0.12
        case .ssr: 0.03
        }
    }

    /// 重复卡转化积分
    var duplicatePoints: Int {
        switch self {
        case .n: 2
        case .r: 5
        case .sr: 10
        case .ssr: 20
        }
    }

    /// 全息边框主色（十六进制）
    var accentHex: String {
        switch self {
        case .n: "#8A8F98"
        case .r: "#3FA7FF"
        case .sr: "#B06BFF"
        case .ssr: "#FFC24B"
        }
    }
}

/// 任务难度
enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case normal = "normal"
    case hard = "hard"
    case extreme = "extreme"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: "简单"
        case .normal: "普通"
        case .hard: "较难"
        case .extreme: "高难"
        }
    }

    /// 默认奖励积分（可被任务单独覆盖）
    var defaultReward: Int {
        switch self {
        case .easy: 5
        case .normal: 10
        case .hard: 15
        case .extreme: 20
        }
    }
}

/// 任务实例状态机
enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "pending"      // 待抽取（盲盒内）
    case drawn = "drawn"          // 已抽取，未操作
    case active = "active"        // 执行中
    case todo = "todo"            // 待完成（挂起）
    case completed = "completed"  // 已完成
    case overdue = "overdue"      // 超时
    case skipped = "skipped"      // 已跳过

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pending: "待抽取"
        case .drawn: "已抽取"
        case .active: "执行中"
        case .todo: "待完成"
        case .completed: "已完成"
        case .overdue: "超时"
        case .skipped: "已跳过"
        }
    }
}

// MARK: - 数据模型

/// 分类（任务 / 惩罚 / 自定义）
struct Category: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var symbol: String
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, symbol: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.isEnabled = isEnabled
    }
}

/// 任务模板（内容库中的一条）
struct TaskTemplate: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var categoryId: UUID
    var rewardPoints: Int
    var timeoutPenalty: Int
    var skipMultiplier: Int
    var timeLimitMinutes: Int
    var difficulty: Difficulty
    var isEnabled: Bool

    init(id: UUID = UUID(),
         title: String,
         description: String = "",
         categoryId: UUID,
         rewardPoints: Int,
         timeoutPenalty: Int,
         skipMultiplier: Int = 3,
         timeLimitMinutes: Int = 60,
         difficulty: Difficulty,
         isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.categoryId = categoryId
        self.rewardPoints = rewardPoints
        self.timeoutPenalty = timeoutPenalty
        self.skipMultiplier = skipMultiplier
        self.timeLimitMinutes = timeLimitMinutes
        self.difficulty = difficulty
        self.isEnabled = isEnabled
    }
}

/// 角色卡定义
struct CharacterCard: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var rarity: Rarity
    /// 资源文件名（不含扩展名），对应 Resources/Characters 下文件
    var imageName: String
    /// 风格标签，可选
    var style: String

    init(id: UUID = UUID(), name: String, rarity: Rarity, imageName: String, style: String = "") {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.imageName = imageName
        self.style = style
    }
}

/// 盲盒格（本轮 1~9）
struct BoxItem: Codable, Identifiable {
    var slot: Int
    var opened: Bool
    var templateId: UUID?
    var instanceId: UUID?

    var id: Int { slot }
}

/// 任务实例（一条被抽出的任务 + 角色 + 状态）
struct TaskInstance: Identifiable, Codable, Hashable {
    var id: UUID
    var templateId: UUID
    var characterId: UUID
    var categoryId: UUID
    var title: String
    var description: String
    var rewardPoints: Int
    var timeoutPenalty: Int
    var skipCost: Int
    var timeLimitMinutes: Int
    var difficulty: Difficulty
    var rarity: Rarity
    var status: TaskStatus
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var dueAt: Date?

    init(id: UUID = UUID(),
         templateId: UUID,
         characterId: UUID,
         categoryId: UUID,
         title: String,
         description: String,
         rewardPoints: Int,
         timeoutPenalty: Int,
         skipCost: Int,
         timeLimitMinutes: Int,
         difficulty: Difficulty,
         rarity: Rarity,
         status: TaskStatus = .drawn) {
        self.id = id
        self.templateId = templateId
        self.characterId = characterId
        self.categoryId = categoryId
        self.title = title
        self.description = description
        self.rewardPoints = rewardPoints
        self.timeoutPenalty = timeoutPenalty
        self.skipCost = skipCost
        self.timeLimitMinutes = timeLimitMinutes
        self.difficulty = difficulty
        self.rarity = rarity
        self.status = status
        self.createdAt = Date()
    }
}

/// 收集记录
struct CollectedEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var characterId: UUID
    var date: Date
}

/// 应用完整数据
struct AppData: Codable {
    var points: Int
    var categories: [Category]
    var tasks: [TaskTemplate]
    var characters: [CharacterCard]
    var collected: [CollectedEntry]
    var instances: [TaskInstance]
    var currentRound: [BoxItem]
    var currentCategoryId: UUID

    /// 当前轮是否已全部开启（用于判断是否需要重制提示）
    var allOpened: Bool {
        currentRound.allSatisfy { $0.opened }
    }
}
