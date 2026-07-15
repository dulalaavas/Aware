import SwiftUI
import SwiftData
import Charts

struct MoodHistoryView: View {
    @Query(sort: \MoodEntry.createdAt) private var moods: [MoodEntry]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if moods.isEmpty {
                    ContentUnavailableView(
                        "No moods yet",
                        systemImage: "face.smiling",
                        description: Text("Log how you feel from the home screen and your history will show up here.")
                    )
                    .padding(.top, 60)
                } else {
                    trendCard
                    breakdownCard
                    summaryCard
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Mood history")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recent: [MoodEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return moods.filter { $0.createdAt >= cutoff }
    }

    // MARK: Trend line

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last 30 days")
                .font(.headline)
                .foregroundStyle(Color.appInk)
            if recent.isEmpty {
                Text("No moods logged in the last 30 days.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
            } else {
                Chart(recent) { entry in
                    LineMark(
                        x: .value("Day", entry.createdAt, unit: .day),
                        y: .value("Mood", entry.mood.score)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.appAccent)
                    PointMark(
                        x: .value("Day", entry.createdAt, unit: .day),
                        y: .value("Mood", entry.mood.score)
                    )
                    .foregroundStyle(Color.appAccent)
                }
                .chartYScale(domain: 0.5...5.5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let score = value.as(Int.self),
                               let mood = Mood.allCases.first(where: { $0.score == score }) {
                                Text(mood.emoji)
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
        }
        .card()
    }

    // MARK: Breakdown bars

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All time")
                .font(.headline)
                .foregroundStyle(Color.appInk)
            Chart(Mood.allCases) { mood in
                BarMark(
                    x: .value("Days", count(of: mood)),
                    y: .value("Mood", "\(mood.emoji) \(mood.label)")
                )
                .foregroundStyle(Color.appAccent.opacity(0.35 + 0.13 * Double(mood.score)))
                .annotation(position: .trailing) {
                    Text("\(count(of: mood))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.appMuted)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 200)
        }
        .card()
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            if let commonest = Mood.allCases.max(by: { count(of: $0) < count(of: $1) }) {
                VStack(spacing: 4) {
                    Text(commonest.emoji)
                        .font(.title)
                    Text("Most often \(commonest.label.lowercased())")
                        .font(.caption2)
                        .foregroundStyle(Color.appMuted)
                }
                .frame(maxWidth: .infinity)
            }
            VStack(spacing: 4) {
                Text("\(moods.count)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.appAccent)
                Text("Moods logged")
                    .font(.caption2)
                    .foregroundStyle(Color.appMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .card()
    }

    private func count(of mood: Mood) -> Int {
        moods.filter { $0.mood == mood }.count
    }
}
