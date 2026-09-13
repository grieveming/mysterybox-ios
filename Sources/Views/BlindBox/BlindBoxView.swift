import SwiftUI
import UIKit

struct BlindBoxView: View {
    @EnvironmentObject var store: DataStore
    @State private var openingSlot: Int?
    @State private var openingInstance: TaskInstance?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        categoryToggle
                        grid
                        resetButton
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $openingInstance) { instance in
            OpeningAnimationView(instance: instance, slot: openingSlot ?? 0) {
                openingInstance = nil
                openingSlot = nil
            }
        }
    }

    // MARK: 顶部
    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("盲盒任务")
                    .font(.title.bold())
                    .foregroundColor(Theme.textPrimary)
                Text("MYSTERY TASK SYSTEM")
                    .font(.caption)
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.accentCyan)
                Text("\(store.data.points)")
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Theme.accentCyan.opacity(0.5), lineWidth: 1))
        }
    }

    // MARK: 分类切换
    private var categoryToggle: some View {
        HStack(spacing: 0) {
            ForEach(store.data.categories.filter { $0.isEnabled }) { cat in
                Button {
                    store.setCategory(cat.id)
                } label: {
                    HStack(spacing: 6) {
                        Text(cat.symbol)
                        Text(cat.name)
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(store.data.currentCategoryId == cat.id ? Color.black : Theme.textSecondary)
                    .background(
                        store.data.currentCategoryId == cat.id
                            ? LinearGradient(colors: [Theme.accent, Theme.accentCyan], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                    )
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: 九宫格
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.data.currentRound) { box in
                BoxCellView(box: box, symbol: store.currentCategory?.symbol ?? "✦")
                    .onTapGesture {
                        guard !box.opened else { return }
                        if let inst = store.openBox(slot: box.slot) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            openingSlot = box.slot
                            openingInstance = inst
                        }
                    }
            }
        }
    }

    // MARK: 重制盲盒
    private var resetButton: some View {
        VStack(spacing: 6) {
            Button {
                store.regenerateRound()
            } label: {
                Text("✦ 重制盲盒 ✦")
                    .font(.headline.bold())
                    .foregroundColor(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Theme.accent, Theme.accentCyan],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Text("重新生成 9 个盲盒 · 每轮内容不重复")
                .font(.caption2)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - 单个盲盒格
struct BoxCellView: View {
    let box: BoxItem
    let symbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(box.opened
                      ? LinearGradient(colors: [Color(hex: "#15131F"), Color(hex: "#0E0C16")], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(hex: "#241A4D"), Color(hex: "#10183A")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(box.opened ? Color.white.opacity(0.08) : Theme.accent.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: box.opened ? .clear : Theme.accent.opacity(0.4), radius: 10, y: 4)

            // 中央神秘符号（已开启则隐藏能量）
            if !box.opened {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.accentCyan, Theme.accent],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .opacity(0.9)
            } else {
                // 开盖空盒
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundColor(Color.white.opacity(0.25))
            }

            // 编号 1~9（低调 HUD 风格）
            Text("\(box.slot)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(box.opened ? Color.white.opacity(0.25) : Color.white.opacity(0.5))
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 104)
        .opacity(box.opened ? 0.75 : 1)
        .scaleEffect(box.opened ? 0.96 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: box.opened)
    }
}

#Preview {
    BlindBoxView()
        .environmentObject(DataStore.shared)
}
