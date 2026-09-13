import SwiftUI
import UIKit

/// 开盒结果：角色卡（背面->正面翻转）+ 任务信息 + 操作
struct ResultCardView: View {
    let instance: TaskInstance
    let character: CharacterCard
    @Binding var cardFlipped: Bool
    let onAction: (Action) -> Void

    enum Action { case execute, suspend }

    var body: some View {
        VStack(spacing: 18) {
            // 角色卡
            ZStack {
                cardFace(false) // 背面
                    .opacity(cardFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(cardFlipped ? 180 : 0), axis: (0, 1, 0))
                cardFace(true)  // 正面
                    .opacity(cardFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(cardFlipped ? 0 : -180), axis: (0, 1, 0))
            }
            .frame(width: 200, height: 280)
            .shadow(color: Theme.rarityColor(character.rarity).opacity(0.5), radius: 20, y: 6)

            // 任务信息
            VStack(spacing: 10) {
                HStack {
                    rarityBadge
                    Text(character.name)
                        .font(.headline.bold())
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }

                Text(instance.title)
                    .font(.title3.bold())
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !instance.description.isEmpty {
                    Text(instance.description)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Label("+\(instance.rewardPoints)", systemImage: "star.fill")
                        .foregroundColor(Theme.accentCyan)
                    Spacer()
                    Label(instance.difficulty.label, systemImage: "flame.fill")
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Label("\(instance.timeLimitMinutes)分", systemImage: "clock")
                        .foregroundColor(Theme.textSecondary)
                }
                .font(.footnote)
                .padding(.top, 4)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))

            // 操作按钮
            HStack(spacing: 14) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onAction(.suspend)
                } label: {
                    Text("挂起")
                        .font(.headline)
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                }

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAction(.execute)
                } label: {
                    Text("执行")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Theme.accent, Theme.accentCyan],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private var rarityBadge: some View {
        Text(character.rarity.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(.black)
            .background(Theme.rarityColor(character.rarity))
            .clipShape(Capsule())
    }

    /// 卡牌面：front 为角色正面，back 为神秘背面
    @ViewBuilder
    private func cardFace(_ front: Bool) -> some View {
        if front {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color(hex: "#1A1140"), Color(hex: "#0E1430")],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.rarityColor(character.rarity), lineWidth: 2))
                VStack(spacing: 8) {
                    if let img = UIImage(named: character.imageName) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 168, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit().frame(height: 120)
                            .foregroundColor(Theme.rarityColor(character.rarity))
                    }
                    Text(character.name)
                        .font(.headline.bold())
                        .foregroundColor(Theme.textPrimary)
                    Text(character.rarity.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(Theme.rarityColor(character.rarity))
                }
                .padding(8)
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color(hex: "#241A4D"), Color(hex: "#10183A")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.accent.opacity(0.6), lineWidth: 2))
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(LinearGradient(colors: [Theme.accentCyan, Theme.accent],
                                                   startPoint: .top, endPoint: .bottom))
            }
        }
    }
}
