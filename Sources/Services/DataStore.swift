import Foundation
import SwiftUI

/// 本地数据持久化 + 业务操作
@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var data: AppData

    private let fileName = "mysterybox_data.json"
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    init() {
        if let loaded = Self.load(from: Self.defaultURL()) {
            self.data = loaded
        } else {
            self.data = DefaultData.initial()
            regenerateRoundIfNeeded()
            save()
        }
    }

    // MARK: - 持久化

    private static func defaultURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("mysterybox_data.json")
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let d = try encoder.encode(data)
            try d.write(to: fileURL, options: .atomic)
        } catch {
            print("[DataStore] save failed: \(error)")
        }
    }

    private static func load(from url: URL) -> AppData? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let d = try Data(contentsOf: url)
            return try JSONDecoder().decode(AppData.self, from: d)
        } catch {
            print("[DataStore] load failed: \(error)")
            return nil
        }
    }

    // MARK: - 数据管理

    /// 恢复默认（保留当前积分? 这里按需求「恢复初始任务和初始设置」）
    func resetToDefault() {
        let keepPoints = data.points
        data = DefaultData.initial()
        // 需求 §31 恢复默认：保留已有积分体验更友好，注释可改
        data.points = keepPoints
        regenerateRoundIfNeeded()
        save()
    }

    /// 清空所有本地数据
    func clearAll() {
        data = DefaultData.initial()
        regenerateRoundIfNeeded()
        save()
    }

    /// 导出 JSON
    func exportJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(data)) ?? Data()
    }

    /// 导入 JSON
    func importJSON(_ json: Data) throws {
        let decoded = try JSONDecoder().decode(AppData.self, from: json)
        data = decoded
        regenerateRoundIfNeeded()
        save()
    }

    // MARK: - 盲盒

    /// 当前分类
    var currentCategory: Category? {
        data.categories.first { $0.id == data.currentCategoryId }
    }

    func setCategory(_ id: UUID) {
        guard data.currentCategoryId != id else { return }
        data.currentCategoryId = id
        regenerateRound()
    }

    /// 重制盲盒：清空状态，重新抽 9 个不重复内容
    func regenerateRound() {
        let picks = BoxEngine.pickTemplates(from: data.tasks, categoryId: data.currentCategoryId)
        data.currentRound = picks.enumerated().map { index, tmpl in
            BoxItem(slot: index + 1, opened: false, templateId: tmpl.id, instanceId: nil)
        }
        save()
    }

    /// 若当前轮为空则生成
    func regenerateRoundIfNeeded() {
        if data.currentRound.isEmpty { regenerateRound() }
    }

    /// 开盒：确定任务与角色、保存状态，返回实例用于播放动画
    @discardableResult
    func openBox(slot: Int) -> TaskInstance? {
        guard let idx = data.currentRound.firstIndex(where: { $0.slot == slot }),
              !data.currentRound[idx].opened,
              let templateId = data.currentRound[idx].templateId,
              let template = data.tasks.first(where: { $0.id == templateId }) else {
            return nil
        }

        let rarity = BoxEngine.rollRarity()
        let character = BoxEngine.pickCharacter(from: data.characters) ?? data.characters.first!

        let skipCost = max(template.rewardPoints * template.skipMultiplier, template.rewardPoints)
        let instance = TaskInstance(
            templateId: template.id,
            characterId: character.id,
            categoryId: template.categoryId,
            title: template.title,
            description: template.description,
            rewardPoints: template.rewardPoints,
            timeoutPenalty: template.timeoutPenalty,
            skipCost: skipCost,
            timeLimitMinutes: template.timeLimitMinutes,
            difficulty: template.difficulty,
            rarity: rarity,
            status: .drawn
        )

        // 重复卡转化积分（需求 §16）
        let alreadyOwned = data.collected.contains { $0.characterId == character.id }
        data.collected.append(CollectedEntry(characterId: character.id, date: Date()))
        if alreadyOwned {
            data.points += rarity.duplicatePoints
        }

        data.instances.append(instance)
        data.currentRound[idx].opened = true
        data.currentRound[idx].instanceId = instance.id
        save()
        return instance
    }

    // MARK: - 任务状态流转（需求 §19~§26）

    func execute(_ instanceId: UUID) {
        guard let idx = data.instances.firstIndex(where: { $0.id == instanceId }) else { return }
        data.instances[idx].status = .active
        data.instances[idx].startedAt = Date()
        data.instances[idx].dueAt = Date().addingTimeInterval(TimeInterval(data.instances[idx].timeLimitMinutes * 60))
        save()
    }

    func suspend(_ instanceId: UUID) {
        guard let idx = data.instances.firstIndex(where: { $0.id == instanceId }) else { return }
        data.instances[idx].status = .todo
        data.instances[idx].startedAt = nil
        data.instances[idx].dueAt = nil
        save()
    }

    func submit(_ instanceId: UUID) {
        guard let idx = data.instances.firstIndex(where: { $0.id == instanceId }) else { return }
        data.instances[idx].status = .completed
        data.instances[idx].completedAt = Date()
        data.instances[idx].dueAt = nil
        data.points += data.instances[idx].rewardPoints
        save()
    }

    /// 用积分跳过任务（需求 §26，初始 3× 奖励）
    func skip(_ instanceId: UUID) {
        guard let idx = data.instances.firstIndex(where: { $0.id == instanceId }) else { return }
        let cost = data.instances[idx].skipCost
        guard data.points >= cost else { return }
        data.points -= cost
        data.instances[idx].status = .skipped
        data.instances[idx].dueAt = nil
        save()
    }

    /// 超时检测（进入页面时调用）
    func checkOverdue() {
        let now = Date()
        var changed = false
        for idx in data.instances.indices {
            let i = data.instances[idx]
            if i.status == .active, let due = i.dueAt, due < now {
                data.instances[idx].status = .overdue
                data.points = max(0, data.points - i.timeoutPenalty)
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - 分类管理

    func addCategory(name: String, symbol: String) {
        data.categories.append(Category(name: name, symbol: symbol.isEmpty ? "✦" : symbol))
        save()
    }

    func updateCategory(_ category: Category) {
        if let idx = data.categories.firstIndex(where: { $0.id == category.id }) {
            data.categories[idx] = category
            save()
        }
    }

    func deleteCategory(_ id: UUID) {
        // 至少保留一个分类
        guard data.categories.count > 1 else { return }
        data.categories.removeAll { $0.id == id }
        data.tasks.removeAll { $0.categoryId == id }
        if data.currentCategoryId == id {
            data.currentCategoryId = data.categories.first!.id
            regenerateRound()
        }
        save()
    }

    // MARK: - 任务库管理

    func addTask(_ task: TaskTemplate) {
        data.tasks.append(task)
        save()
    }

    func updateTask(_ task: TaskTemplate) {
        if let idx = data.tasks.firstIndex(where: { $0.id == task.id }) {
            data.tasks[idx] = task
            save()
        }
    }

    func deleteTask(_ id: UUID) {
        data.tasks.removeAll { $0.id == id }
        save()
    }

    // MARK: - 查询辅助

    func instances(with status: TaskStatus) -> [TaskInstance] {
        data.instances.filter { $0.status == status }
    }

    func collectedSet() -> Set<UUID> {
        Set(data.collected.map { $0.characterId })
    }

    func countForCharacter(_ id: UUID) -> Int {
        data.collected.filter { $0.characterId == id }.count
    }
}
