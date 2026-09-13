import SwiftUI

struct TaskCenterView: View {
    @EnvironmentObject var store: DataStore

    private let sections: [(TaskStatus, String)] = [
        (.active, "执行中"),
        (.todo, "待完成"),
        (.completed, "已完成"),
        (.overdue, "超时"),
        (.skipped, "已跳过")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        pointsHeader
                        ForEach(sections, id: \.0) { status, title in
                            section(status, title)
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("任务中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { store.checkOverdue() }
    }

    private var pointsHeader: some View {
        HStack {
            Image(systemName: "star.fill").foregroundColor(Theme.accentCyan)
            Text("当前积分  \(store.data.points)")
                .font(.headline.bold())
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }

    @ViewBuilder
    private func section(_ status: TaskStatus, _ title: String) -> some View {
        let items = store.instances(with: status)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline).foregroundColor(Theme.textPrimary)
                    Text("\(items.count)")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                ForEach(items) { inst in
                    TaskRowView(instance: inst)
                }
            }
            .padding(.top, 8)
        }
    }
}

struct TaskRowView: View {
    @EnvironmentObject var store: DataStore
    let instance: TaskInstance

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(instance.title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(instance.rarity.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Theme.rarityColor(instance.rarity))
                    .clipShape(Capsule())
            }
            if !instance.description.isEmpty {
                Text(instance.description)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            HStack(spacing: 12) {
                Label("+\(instance.rewardPoints)", systemImage: "star.fill")
                    .font(.caption).foregroundColor(Theme.accentCyan)
                if instance.status == .active || instance.status == .overdue {
                    Label("\(instance.timeLimitMinutes)分", systemImage: "clock")
                        .font(.caption).foregroundColor(Theme.textSecondary)
                }
                Spacer()
                actionButtons
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
    }

    private var borderColor: Color {
        switch instance.status {
        case .active: return Theme.accentCyan.opacity(0.5)
        case .overdue: return Color.red.opacity(0.5)
        case .completed: return Color.green.opacity(0.4)
        default: return Color.white.opacity(0.1)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch instance.status {
        case .active, .overdue:
            Button("提交") { store.submit(instance.id) }
                .font(.subheadline.bold()).foregroundColor(.black)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Theme.accentCyan).clipShape(Capsule())
            Button(action: { store.skip(instance.id) }) {
                Text("跳过 -\(instance.skipCost)").font(.subheadline).foregroundColor(.red)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.12)))
            .opacity(store.data.points >= instance.skipCost ? 1 : 0.4)
        case .todo:
            Button("执行") { store.execute(instance.id) }
                .font(.subheadline.bold()).foregroundColor(.black)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Theme.accent).clipShape(Capsule())
        default:
            EmptyView()
        }
    }
}

#Preview {
    TaskCenterView().environmentObject(DataStore.shared)
}
