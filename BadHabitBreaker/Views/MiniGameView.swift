import SwiftUI

struct MiniGameView: View {
    @EnvironmentObject var store: HabitStore
    @State private var isRunning = false
    @State private var dinoY: CGFloat = 0       // 0 = ground
    @State private var velocity: CGFloat = 0
    @State private var obstacleX: CGFloat = 320  // start off-screen to the right
    @State private var score: Int = 0
    @State private var tick = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    let gravity: CGFloat = -0.6
    let jumpImpulse: CGFloat = 10
    let groundY: CGFloat = 0
    let obstacleWidth: CGFloat = 24
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Score: \(score)").font(.headline)
                Spacer()
                Text("Best: \(store.state.gameHighScore)").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            ZStack {
                Rectangle().fill(.thinMaterial).cornerRadius(16)
                // Ground line
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: 2)
                    .offset(y: 50)
                
                // Dino
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .offset(y: 50 - dinoY)
                
                // Obstacle
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: obstacleWidth, height: 20)
                    .offset(x: obstacleX, y: 50)
            }
            .frame(height: 140)
            .padding()
            .contentShape(Rectangle())
            .onTapGesture { jump() }
            .onReceive(tick) { _ in step() }
            
            HStack(spacing: 12) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                    if isRunning { resetRun(keepBest: true) }
                }
                .buttonStyle(.borderedProminent)
                Button("Jump") { jump() }.buttonStyle(.bordered)
            }
        }
        .padding()
        .background(AppTheme.bgGradient.ignoresSafeArea())
        .navigationTitle("Play")
    }
    
    private func jump() {
        guard isRunning else { return }
        if dinoY <= 0.01 { velocity = jumpImpulse }
    }
    private func resetRun(keepBest: Bool) {
        dinoY = 0; velocity = 0; obstacleX = 320; score = keepBest ? score : 0
    }
    private func step() {
        guard isRunning else { return }
        // physics
        velocity += gravity
        dinoY = max(groundY, dinoY + velocity)
        if dinoY == groundY { velocity = max(0, velocity) }
        // move obstacle left
        obstacleX -= 3.5
        if obstacleX < -180 {
            obstacleX = 320
            score += 1
            store.submitGameScore(score)
        }
        // collision
        let dinoLeft: CGFloat = -12
        let dinoRight: CGFloat = 12
        let obsLeft = obstacleX - obstacleWidth/2
        let obsRight = obstacleX + obstacleWidth/2
        let horizontalOverlap = !(dinoRight < obsLeft || dinoLeft > obsRight)
        let hitGroundLevel = dinoY < 18 // when low enough, we "touch" obstacle
        if horizontalOverlap && hitGroundLevel {
            isRunning = false
            Haptics.warning()
        }
    }
}
