import SwiftUI
import UIKit

/// 开盒动画覆盖层（需求 §12 十阶段，总时长约 3~5 秒）
struct OpeningAnimationView: View {
    let instance: TaskInstance
    let slot: Int
    let onClose: () -> Void

    @EnvironmentObject var store: DataStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var phase = 0
    @State private var showResult = false
    @State private var cardFlipped = false
    @State private var flash = false

    private var character: CharacterCard? {
        store.data.characters.first { $0.id == instance.characterId }
    }

    init(instance: TaskInstance, slot: Int, onClose: @escaping () -> Void) {
        self.instance = instance
        self.slot = slot
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            // 背景变暗 + 充能光晕
            Color.black.opacity(phase >= 1 ? 0.85 : 0.4)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: phase)

            if !showResult {
                VStack {
                    // 阶段 1~5：聚焦 -> 充能 -> 解锁 -> 开盖 -> 能量爆发
                    ZStack {
                        // 能量环
                        if phase >= 3 {
                            Circle()
                                .stroke(Theme.accentCyan.opacity(0.6), lineWidth: 2)
                                .frame(width: 260, height: 260)
                                .scaleEffect(phase >= 5 ? 1.6 : 1.0)
                                .opacity(phase >= 5 ? 0 : 0.8)
                                .animation(.easeOut(duration: 0.8), value: phase)
                        }

                        // 盒体
                        boxBody
                            .scaleEffect(phase >= 1 ? 1.4 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: phase)

                        // 中央核心充能
                        if phase >= 2 {
                            Circle()
                                .fill(
                                    RadialGradient(colors: [Theme.accentCyan, Theme.accent],
                                                   center: .center, startRadius: 4, endRadius: 60)
                                )
                                .frame(width: phase >= 4 ? 120 : 50, height: phase >= 4 ? 120 : 50)
                                .blur(radius: 8)
                                .opacity(phase >= 5 ? 0 : 1)
                                .animation(.easeOut(duration: 0.5), value: phase)
                        }
                    }

                    // MYSTERY REVEAL
                    if phase >= 4 {
                        Text("MYSTERY REVEAL")
                            .font(.title3.bold().italic())
                            .tracking(4)
                            .foregroundStyle(
                                LinearGradient(colors: [Theme.accentCyan, Theme.accent],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .opacity(phase >= 5 ? 0 : 1)
                            .animation(.easeInOut(duration: 0.6), value: phase)
                    }
                }
            }

            // 阶段 8~10：角色卡升起 + 翻转 + 任务结果
            if showResult, let character = character {
                ResultCardView(
                    instance: instance,
                    character: character,
                    cardFlipped: $cardFlipped
                ) { action in
                    handle(action)
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            // 全屏闪光
            if flash {
                Color.white.opacity(0.85)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.3), value: flash)
            }
        }
        .onAppear(perform: runSequence)
    }

    private var boxBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color(hex: "#241A4D"), Color(hex: "#10183A")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 140, height: 140)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.accent.opacity(0.7), lineWidth: 2))
            // 盒盖（phase>=3 翻开）
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Theme.accent, Theme.accentCyan], startPoint: .top, endPoint: .bottom))
                .frame(width: 140, height: 70)
                .offset(y: -35)
                .rotation3DEffect(.degrees(phase >= 3 ? -110 : 0), axis: (1, 0, 0), anchor: .bottom)
                .opacity(phase >= 3 ? (phase >= 5 ? 0 : 1) : 1)
                .animation(.easeOut(duration: 0.5), value: phase)
            Text("\(slot)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .offset(y: 35)
        }
    }

    private func runSequence() {
        if reduceMotion {
            withAnimation { showResult = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { cardFlipped = true }
            return
        }
        Task {
            for step in 1...6 {
                try? await Task.sleep(nanoseconds: step == 3 ? 350_000_000 : 500_000_000)
                await MainActor.run { phase = step }
                if step == 3 {
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    await MainActor.run { flash = true }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run { flash = false }
                }
            }
            // 阶段 8：角色卡升起
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showResult = true } }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run { withAnimation(.easeInOut(duration: 0.6)) { cardFlipped = true } }
        }
    }

    private func handle(_ action: ResultCardView.Action) {
        switch action {
        case .execute:
            store.execute(instance.id)
            onClose()
        case .suspend:
            store.suspend(instance.id)
            onClose()
        }
    }
}

#Preview {
    OpeningAnimationView(instance: DataStore.shared.data.instances.first ?? TaskInstance(templateId: UUID(), characterId: UUID(), categoryId: UUID(), title: "测试任务", description: "", rewardPoints: 10, timeoutPenalty: 3, skipCost: 30, timeLimitMinutes: 60, difficulty: .normal),
                        slot: 5, onClose: {})
        .environmentObject(DataStore.shared)
}
