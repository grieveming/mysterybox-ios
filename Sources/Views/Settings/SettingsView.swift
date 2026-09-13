import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient().ignoresSafeArea()
                List {
                    Section("内容管理") {
                        NavigationLink { CategoryListView() } label: {
                            Label("分类管理", systemImage: "folder.fill.badge.gear")
                        }
                        NavigationLink { TaskListView() } label: {
                            Label("任务库管理", systemImage: "list.bullet.clipboard")
                        }
                        NavigationLink { CardBrowseView() } label: {
                            Label("卡片查看", systemImage: "rectangle.stack")
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.04))

                    Section("数据管理") {
                        NavigationLink { DataManagementView() } label: {
                            Label("导出 / 导入 / 重置", systemImage: "externaldrive.fill")
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("设置")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
    }
}

// MARK: - 分类管理列表
struct CategoryListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var editing: Category?

    var body: some View {
        List {
            ForEach(store.data.categories) { cat in
                HStack {
                    Text(cat.symbol).font(.title3)
                    Text(cat.name).foregroundColor(Theme.textPrimary)
                    Spacer()
                    if cat.isEnabled {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    } else {
                        Image(systemName: "circle").foregroundColor(Theme.textSecondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { editing = cat }
            }
            .onDelete { idx in
                idx.forEach { store.deleteCategory(store.data.categories[$0].id) }
            }
        }
        .navigationTitle("分类管理")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { cat in
            CategoryEditorView(category: cat) { store.updateCategory($0) }
        }
        .sheet(isPresented: $showAdd) {
            CategoryEditorView(category: nil) { newCat in
                store.data.categories.append(newCat)
                store.save()
            }
        }
    }
}

// MARK: - 分类编辑
struct CategoryEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var category: Category
    let onSave: (Category) -> Void

    init(category: Category?, onSave: @escaping (Category) -> Void) {
        self._category = State(initialValue: category ?? Category(name: "", symbol: "✦"))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $category.name)
                TextField("符号", text: $category.symbol)
                    .disableAutocorrection(true)
                Toggle("启用", isOn: $category.isEnabled)
            }
            .navigationTitle(category.name.isEmpty ? "新建分类" : "编辑分类")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard !category.name.isEmpty else { return }
                        onSave(category)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 任务库列表
struct TaskListView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var editing: TaskTemplate?

    var body: some View {
        List {
            ForEach(store.data.categories) { cat in
                Section(cat.name) {
                    ForEach(store.data.tasks.filter { $0.categoryId == cat.id }) { task in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(task.title).foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text("+\(task.rewardPoints)")
                                    .font(.caption).foregroundColor(Theme.accentCyan)
                            }
                            Text(task.difficulty.label)
                                .font(.caption2).foregroundColor(Theme.textSecondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { editing = task }
                    }
                }
            }
        }
        .navigationTitle("任务库")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { task in
            TaskEditorView(task: task) { store.updateTask($0) }
        }
        .sheet(isPresented: $showAdd) {
            TaskEditorView(task: nil) { newTask in
                store.addTask(newTask)
            }
        }
    }
}

// MARK: - 任务编辑
struct TaskEditorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: DataStore
    @State var task: TaskTemplate
    let onSave: (TaskTemplate) -> Void

    init(task: TaskTemplate?, onSave: @escaping (TaskTemplate) -> Void) {
        self._task = State(initialValue: task ?? TaskTemplate(title: "", categoryId: UUID(), rewardPoints: 10, timeoutPenalty: 3, skipMultiplier: 3, timeLimitMinutes: 60, difficulty: .normal))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基础") {
                    TextField("标题", text: $task.title)
                    TextField("说明", text: $task.description)
                    Picker("分类", selection: $task.categoryId) {
                        ForEach(store.data.categories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                    Picker("难度", selection: $task.difficulty) {
                        ForEach(Difficulty.allCases) { d in
                            Text(d.label).tag(d)
                        }
                    }
                }
                Section("参数") {
                    Stepper("奖励积分 \(task.rewardPoints)", value: $task.rewardPoints, in: 0...999)
                    Stepper("超时扣分 \(task.timeoutPenalty)", value: $task.timeoutPenalty, in: 0...999)
                    Stepper("跳过倍率 \(task.skipMultiplier)x", value: $task.skipMultiplier, in: 1...20)
                    Stepper("时间限制 \(task.timeLimitMinutes) 分", value: $task.timeLimitMinutes, in: 1...1440)
                }
                Section {
                    Toggle("启用", isOn: $task.isEnabled)
                }
            }
            .onAppear {
                if !store.data.categories.contains(where: { $0.id == task.categoryId }) {
                    task.categoryId = store.data.categories.first?.id ?? task.categoryId
                }
            }
            .navigationTitle(task.title.isEmpty ? "新建任务" : "编辑任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard !task.title.isEmpty else { return }
                        onSave(task)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 卡片浏览
struct CardBrowseView: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        List {
            ForEach(store.data.characters) { card in
                HStack {
                    if let img = UIImage(named: card.imageName) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 44, height: 60).clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "person.fill").foregroundColor(Theme.rarityColor(card.rarity))
                    }
                    VStack(alignment: .leading) {
                        Text(card.name).foregroundColor(Theme.textPrimary)
                        Text("\(card.rarity.rawValue) · \(card.style)")
                            .font(.caption).foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    if store.collectedSet().contains(card.id) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.rarityColor(card.rarity))
                    } else {
                        Text("未收集").font(.caption).foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
        .navigationTitle("卡片查看")
        .preferredColorScheme(.dark)
    }
}

// MARK: - 数据管理
struct DataManagementView: View {
    @EnvironmentObject var store: DataStore
    @State private var message = ""
    @State private var showResetConfirm = false
    @State private var showClearConfirm = false
    @State private var showImportPicker = false

    var body: some View {
        List {
            Section("导出") {
                Button { exportFile() } label: { Label("导出数据为 JSON", systemImage: "square.and.arrow.up") }
            }
            Section("导入") {
                Button { showImportPicker = true } label: { Label("从 JSON 导入", systemImage: "square.and.arrow.down") }
            }
            Section("恢复") {
                Button { showResetConfirm = true } label: { Label("恢复默认任务与设置", systemImage: "arrow.clockwise") }
            }
            Section("危险") {
                Button { showClearConfirm = true } label: {
                    Label("清空所有本地数据", systemImage: "trash.fill").foregroundColor(.red)
                }
            }
            if !message.isEmpty {
                Section { Text(message).font(.caption).foregroundColor(Theme.textSecondary) }
            }
        }
        .navigationTitle("数据管理")
        .preferredColorScheme(.dark)
        .alert("恢复默认", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive) { store.resetToDefault(); message = "已恢复默认内容" }
        } message: { Text("将重置任务库、分类与收藏，但保留当前积分。") }
        .alert("清空数据", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) { store.clearAll(); message = "已清空全部数据" }
        } message: { Text("所有积分、任务、卡片与设置都会被删除，且不可恢复。") }
        .sheet(isPresented: $showImportPicker) {
            DocumentImporter { url in
                do {
                    let data = try Data(contentsOf: url)
                    try store.importJSON(data)
                    message = "导入成功"
                } catch {
                    message = "导入失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func exportFile() {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("mysterybox_export.json")
        do {
            try store.exportJSON().write(to: tmp)
            message = "已生成导出文件，可用访达共享"
            // 简化：直接提示路径；正式版可接 ShareLink
        } catch {
            message = "导出失败：\(error.localizedDescription)"
        }
    }
}

// 轻量文档导入（iOS 14+ UIDocumentPickerViewController 包装略，这里用 share 兼容）
struct DocumentImporter: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPick(url) }
        }
    }
}

#Preview {
    SettingsView().environmentObject(DataStore.shared)
}
