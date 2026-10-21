import SwiftUI

struct ContentView: View {
    @State private var water = 0  // 總澆水次數
    @State private var bursts: [UUID] = []  // 正在播放的動畫組
    let perStage = 20    // 每個階段要澆 20 次
    let maxWater = 100   // 總共 100 次
    var isDone: Bool { water >= maxWater }    // 是否已經種完
    var stage: Int { water / perStage }       // 目前階段 0~5
    var stageWater: Int { water % perStage }  // 本階段的進度
    var imageName: String { "stage\(stage + 1)" }

    // 成長大小區間
    let sizes: [(from: CGFloat, to: CGFloat)] = [
        (10, 20),     // 種子
        (80, 100),    // 發芽
        (110, 150),   // 幼苗
        (180, 210),   // 小樹
        (240, 280),   // 大樹
        (290, 290)    // 完成
    ]

    // 位置微調對齊
    let offsets: [CGSize] = [
        CGSize(width: 4, height: -4),   // 種子
        CGSize(width: 0, height: 0),    // 發芽
        CGSize(width: -4, height: 0),   // 幼苗
        CGSize(width: -14, height: 0),  // 小樹
        CGSize(width: -5, height: 0),   // 大樹
        CGSize(width: 0, height: 0)     // 完成
    ]

    // 樹高
    var imageHeight: CGFloat {
        let range = sizes[stage]
        let t = CGFloat(stageWater) / CGFloat(perStage) // 0 ~ 1
        return range.from + (range.to - range.from) * t
    }

    // 階段標題
    var title: String {
        ["種子", "發芽", "幼苗", "小樹", "大樹", "完成"][stage]
    }

    // 階段描述
    var hint: String {
        switch stage {
        case 0: return "幫種子澆水吧"
        case 1: return "冒出小芽了！"
        case 2: return "長出嫩葉囉～"
        case 3: return "長出樹幹和樹枝了"
        case 4: return "枝葉越來越茂盛"
        default: return "你成功種出一棵大樹！"
        }
    }

    var skyColors: [Color] {
        isDone ? [.yellow.opacity(0.8), .cyan.opacity(0.9)]
               : [.yellow.opacity(0.25), .cyan.opacity(0.15)]
    }

    // 澆水一次
    func water1Time() {
        let id = UUID()
        bursts.append(id)
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            bursts.removeAll { $0 == id }
        }
        withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
            water += 1
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: skyColors, startPoint: .topTrailing, endPoint: .bottomLeading)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("種樹點擊遊戲")
                    .font(.largeTitle.bold())
                    .offset(y: 30)

                // 重來按鈕
                ZStack {
                    if isDone {
                        Button {
                            withAnimation { water = 0 }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("重新種一棵")
                            }
                            .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .frame(height: 44)
                .offset(y: 30)

                Spacer()

                // 植物
                ZStack(alignment: .bottom) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.yellow)
                        .offset(x: 100, y: -300)

                    if stage == 0 {
                        Capsule()
                            .fill(.brown)
                            .frame(width: 65, height: 10)
                    }

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: imageHeight)
                        .offset(x: offsets[stage].width, y: offsets[stage].height)

                    // 澆水動畫
                    ForEach(bursts, id: \.self) { _ in
                        DropBurst()
                    }
                    .allowsHitTesting(false)
                }
                .frame(height: 400, alignment: .bottom)

                Spacer()

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                    Text(hint)
                        .foregroundStyle(.secondary)
                    Text(isDone ? "共澆水 \(maxWater) 次" : "本階段已澆水 \(stageWater) / \(perStage) 次")
                        .font(.headline)
                }

                // 進度條
                ProgressView(value: Double(isDone ? perStage : stageWater), total: Double(perStage))
                    .tint(.green)
                    .padding(.horizontal, 40)

                // 澆水按鈕
                Button {
                    water1Time()
                } label: {
                    HStack {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "drop.fill")
                        Text(isDone ? "種好了！" : "澆水")
                    }
                    .font(.title2.bold())
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(isDone ? .gray : .blue)
                .disabled(isDone)
            }
            .padding()
        }
    }
}

// 初始動畫數值
struct DropValues {
    var y: CGFloat = -200
    var opacity: Double = 0
}

// 一組水滴：隨機偏移
struct DropBurst: View {
    @State private var xShift = CGFloat.random(in: -35...35)

    var body: some View {
        HStack(spacing: 5) {
            WaterDrop(delay: 0.05)
            WaterDrop(delay: 0.15)
            WaterDrop(delay: 0.25)
        }
        .offset(x: xShift)
    }
}

// 水滴落下動畫
struct WaterDrop: View {
    let delay: Double
    @State private var play = 0   // 動畫 Trigger

    var body: some View {
        Image(systemName: "drop.fill")
            .font(.title)
            .foregroundStyle(.cyan)
            .keyframeAnimator(initialValue: DropValues(), trigger: play) { content, value in
                content
                    .offset(y: value.y)
                    .opacity(value.opacity)
            } keyframes: { _ in
                // 高度變化
                KeyframeTrack(\.y) {
                    MoveKeyframe(-200)
                    LinearKeyframe(-200, duration: delay)
                    CubicKeyframe(0, duration: 0.4)
                }
                // 透明度變化
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(0)
                    LinearKeyframe(0, duration: delay)
                    LinearKeyframe(1, duration: 0.05)
                    LinearKeyframe(1, duration: 0.3)
                    LinearKeyframe(0, duration: 0.1)
                }
            }
            .onAppear { play += 1 }
    }
}

#Preview {
    ContentView()
}
