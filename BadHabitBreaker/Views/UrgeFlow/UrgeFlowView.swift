import SwiftUI

enum UrgeStep: Int, CaseIterable {
    case delay, breathe, doTask, log
}

struct UrgeFlowView: View {
    @EnvironmentObject var store: HabitStore
    @State private var step: UrgeStep = .delay
    @State private var completed = Set<UrgeStep>()
    
    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $step) {
                DelayTimerView(onDone: { next(.breathe) })
                    .tag(UrgeStep.delay)
                BreathingView(onDone: { next(.doTask) })
                    .tag(UrgeStep.breathe)
                CopingTaskView(onDone: { next(.log) })
                    .tag(UrgeStep.doTask)
                LogOutcomeView(onSuccess: {
                    store.logSuccess()
                    dismiss()
                }, onRelapse: { trigger, notes in
                    store.logRelapse(trigger: trigger, notes: notes)
                    dismiss()
                })
                .tag(UrgeStep.log)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .padding()
        .presentationDragIndicator(.visible)
    }
    
    private func next(_ s: UrgeStep) {
        completed.insert(step)
        withAnimation { step = s }
    }
    private func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
