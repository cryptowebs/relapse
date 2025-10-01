import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var store: HabitStore
    
    var cravingSeries: [CravingPoint] {
        store.state.checkIns.sorted{ $0.date < $1.date }.map { .init(date: dayOnly($0.date), value: $0.craving) }
    }
    var relapseSeries: [DailyCount] {
        let grouped = Dictionary(grouping: store.state.relapseLog) { dayOnly($0.date) }
        return grouped.keys.sorted().map { .init(date: $0, count: grouped[$0]?.count ?? 0) }
    }
    var successSeries: [DailyCount] {
        // approximate using cumulative successfulUrges distributed evenly across unique days of check-ins
        let days = Array(Set(store.state.checkIns.map{ dayOnly($0.date) })).sorted()
        guard !days.isEmpty else { return [] }
        let total = store.state.successfulUrges
        let per = max(0, total / max(1, days.count))
        return days.map { .init(date: $0, count: per) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                GroupBox("Craving over time") {
                    Chart(cravingSeries) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Craving", p.value))
                        PointMark(x: .value("Date", p.date), y: .value("Craving", p.value))
                    }
                    .frame(height: 220)
                }
                GroupBox("Relapses per day") {
                    Chart(relapseSeries) { p in
                        BarMark(x: .value("Date", p.date), y: .value("Relapses", p.count))
                    }
                    .frame(height: 180)
                }
                GroupBox("Successful urges (rough daily)") {
                    Chart(successSeries) { p in
                        BarMark(x: .value("Date", p.date), y: .value("Successes", p.count))
                    }
                    .frame(height: 180)
                }
            }
            .padding()
        }
        .background(AppTheme.bgGradient.ignoresSafeArea())
        .navigationTitle("Trends")
    }
    
    private func dayOnly(_ d: Date) -> Date {
        Calendar.current.startOfDay(for: d)
    }
    struct CravingPoint: Identifiable { let id = UUID(); let date: Date; let value: Int }
    struct DailyCount: Identifiable { let id = UUID(); let date: Date; let count: Int }
}
