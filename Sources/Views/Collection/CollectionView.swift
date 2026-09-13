import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var store: DataStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        progressHeader
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.data.characters) { card in
                                CardCellView(card: card,
                                             collected: store.collectedSet().contains(card.id),
                                             count: store.countForCharacter(card.id))
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("卡片收藏")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var progressHeader: some View {
        let total = store.data.characters.count
        let owned = store.collectedSet().count
        return HStack {
            Text("收集进度")
                .font(.subheadline).foregroundColor(Theme.textSecondary)
            Spacer()
            Text("\(owned) / \(total)")
                .font(.headline.bold()).foregroundColor(Theme.textPrimary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }
}

struct CardCellView: View {
    let card: CharacterCard
    let collected: Bool
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(collected
                          ? LinearGradient(colors: [Color(hex: "#1A1140"), Color(hex: "#0E1430")], startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [Color(hex: "#15131F"), Color(hex: "#0E0C16")], startPoint: .top, endPoint: .bottom))
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(collected ? Theme.rarityColor(card.rarity) : Color.white.opacity(0.08), lineWidth: 1.5))

                if collected {
                    if let img = UIImage(named: card.imageName) {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 100, height: 132)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit().frame(height: 80)
                            .foregroundColor(Theme.rarityColor(card.rarity))
                    }
                } else {
                    Image(systemName: "questionmark")
                        .font(.largeTitle)
                        .foregroundColor(Color.white.opacity(0.2))
                }

                // 稀有度角标
                Text(card.rarity.rawValue)
                    .font(.caption2.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Theme.rarityColor(card.rarity))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)

                // 重复数量
                if collected && count > 1 {
                    Text("x\(count)")
                        .font(.caption2.bold())
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(6)
                }
            }

            Text(collected ? card.name : "未收集")
                .font(.caption)
                .foregroundColor(collected ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    CollectionView().environmentObject(DataStore.shared)
}
