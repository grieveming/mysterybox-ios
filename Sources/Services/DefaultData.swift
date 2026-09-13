import Foundation

/// 默认数据：初始分类、任务库、角色库
enum DefaultData {
    /// 初始分类
    static func categories() -> [Category] {
        [
            Category(name: "任务", symbol: "✦", isEnabled: true),
            Category(name: "惩罚", symbol: "☠", isEnabled: true)
        ]
    }

    /// 初始任务库（按分类区分内容库）
    static func tasks(task: UUID, punish: UUID) -> [TaskTemplate] {
        let t = [
            ("整理桌面", "花 10 分钟把桌面和工位收拾干净", 5, 2, 30),
            ("阅读 15 分钟", "读一段书或文章，远离屏幕", 5, 2, 30),
            ("散步 10 分钟", "出门走一走，呼吸新鲜空气", 5, 2, 30),
            ("喝水 3 杯", "规律补水，照顾身体", 5, 2, 60),
            ("学习新知识", "了解一个陌生领域的小知识点", 10, 3, 45),
            ("做一组拉伸", "舒展肩颈与腰背", 10, 3, 20),
            ("写明日计划", "列出明天最重要的 3 件事", 10, 3, 30),
            ("整理手机相册", "删掉 20 张没用的截图", 10, 3, 40),
            ("背 10 个单词", "积累一点点语言资产", 15, 5, 30),
            ("运动 20 分钟", "跑步、跳绳或器械均可", 15, 5, 60),
            ("完成一件拖延的事", "挑一件一直拖的事立刻做掉", 20, 8, 90),
            ("深度工作 25 分钟", "番茄钟专注一件事不中断", 20, 8, 45)
        ].map { (title, desc, reward, penalty, limit) in
            TaskTemplate(title: title, description: desc, categoryId: task,
                         rewardPoints: reward, timeoutPenalty: penalty,
                         skipMultiplier: 3, timeLimitMinutes: limit, difficulty: .normal)
        }

        let p = [
            ("平板支撑 60 秒", "核心训练，坚持住", 5, 2, 3),
            ("深蹲 30 个", "腿部力量与耐力", 5, 2, 10),
            ("不刷短视频 1 小时", "忍住，把时间还给生活", 10, 4, 60),
            ("早起打卡", "明天 7:30 前起床", 10, 5, 60),
            ("戒糖一天", "今天不喝奶茶不吃甜点", 15, 6, 120),
            ("冷水洗脸", "清醒一下", 5, 2, 5),
            ("冥想 5 分钟", "安静坐一会儿，关注呼吸", 10, 3, 10),
            ("禁熬夜", "今晚 23:00 前睡觉", 20, 10, 180),
            ("无外卖日", "今天自己做饭或在食堂吃", 15, 6, 240),
            ("断网 30 分钟", "关掉网络，专注当下", 10, 4, 30)
        ].map { (title, desc, reward, penalty, limit) in
            TaskTemplate(title: title, description: desc, categoryId: punish,
                         rewardPoints: reward, timeoutPenalty: penalty,
                         skipMultiplier: 3, timeLimitMinutes: limit,
                         difficulty: reward >= 15 ? .hard : .normal)
        }

        return t + p
    }

    /// 初始角色卡（12 张，对应参考素材 char_001~char_012）
    static func characters() -> [CharacterCard] {
        let defs: [(String, Rarity, String, String)] = [
            ("晨曦", .n, "char_001", "活力少女"),
            ("律动", .r, "char_002", "运动系"),
            ("学妹", .n, "char_003", "学生感"),
            ("顾问", .sr, "char_004", "职场女性"),
            ("远野", .r, "char_005", "户外系"),
            ("芯", .ssr, "char_006", "科技系"),
            ("知遥", .n, "char_007", "温柔系"),
            ("薇拉", .r, "char_008", "冷酷女王"),
            ("夜", .sr, "char_009", "暗黑系"),
            ("莉莉丝", .ssr, "char_010", "恶魔系"),
            ("谜", .r, "char_011", "神秘系"),
            ("赛博女王", .ssr, "char_012", "Cyber Queen")
        ]
        return defs.map { CharacterCard(name: $0.0, rarity: $0.1, imageName: $0.2, style: $0.3) }
    }

    static func initial() -> AppData {
        let cats = categories()
        let task = cats[0].id
        let punish = cats[1].id
        return AppData(
            points: 100,
            categories: cats,
            tasks: tasks(task: task, punish: punish),
            characters: characters(),
            collected: [],
            instances: [],
            currentRound: [],
            currentCategoryId: task
        )
    }
}
