import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        TabView {
            BlindBoxView()
                .tabItem { Label("盲盒", systemImage: "shippingbox.fill") }
                .tag(0)

            TaskCenterView()
                .tabItem { Label("任务", systemImage: "list.bullet.rectangle") }
                .tag(1)

            CollectionView()
                .tabItem { Label("卡片", systemImage: "rectangle.stack.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .accentColor(Theme.accent)
        .onAppear { store.checkOverdue() }
    }
}
