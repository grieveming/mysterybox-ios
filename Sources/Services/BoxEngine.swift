import Foundation

/// 随机与抽取引擎（业务与动画解耦，参见需求 §35）
enum BoxEngine {
    /// 从当前分类内容库抽取 9 个不重复任务模板
    static func pickTemplates(from tasks: [TaskTemplate], categoryId: UUID, count: Int = 9) -> [TaskTemplate] {
        let pool = tasks.filter { $0.isEnabled && $0.categoryId == categoryId }
        guard !pool.isEmpty else { return [] }

        var result: [TaskTemplate] = []
        var remaining = pool
        while result.count < count && !remaining.isEmpty {
            let idx = Int.random(in: 0..<remaining.count)
            result.append(remaining.remove(at: idx))
        }
        // 若内容库不足 9 条，用已有内容补足（保证 9 格）
        var i = 0
        while result.count < count {
            result.append(pool[i % pool.count])
            i += 1
        }
        return result
    }

    /// 依据权重抽取稀有度
    static func rollRarity() -> Rarity {
        let r = Double.random(in: 0..<1)
        var cum = 0.0
        for rar in Rarity.allCases {
            cum += rar.weight
            if r < cum { return rar }
        }
        return .n
    }

    /// 随机抽取一个角色（任务与角色独立随机，见需求 §14）
    static func pickCharacter(from characters: [CharacterCard]) -> CharacterCard? {
        guard !characters.isEmpty else { return nil }
        return characters.randomElement()
    }
}
