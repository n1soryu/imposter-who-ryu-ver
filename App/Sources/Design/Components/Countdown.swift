import SwiftUI

/// A seconds countdown with a draining bar. It starts when it appears; give it a new identity to restart it.
struct Countdown: View {
    var seconds: Int

    @State private var deadline: Date?
    @State private var isExpired = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = remainingSeconds(at: context.date)

            VStack(alignment: .leading, spacing: 8) {
                Text(isExpired ? "Time's up" : Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond)))
                    .font(.displaySemiBold(22, relativeTo: .title3))
                    .monospacedDigit()
                    .foregroundStyle(isExpired ? Color.imposterInk : Color.cardStock)
                    .contentTransition(.numericText(countsDown: true))

                Rectangle()
                    .fill(isExpired ? Color.imposterInk : Color.crewInk)
                    .scaleEffect(x: fraction(remaining), anchor: .leading)
                    .frame(height: 8)
                    .background(Color.feltRaised)
                    .clipShape(.capsule)
                    .animation(.linear(duration: 1), value: remaining)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Timer")
            .accessibilityValue(isExpired ? "Time's up" : "\(remaining) seconds left")
        }
        .onAppear {
            deadline = .now.addingTimeInterval(TimeInterval(seconds))
        }
        .task {
            try? await Task.sleep(for: .seconds(seconds))
            isExpired = true
        }
        .sensoryFeedback(.warning, trigger: isExpired) { _, expired in expired }
    }

    private func remainingSeconds(at date: Date) -> Int {
        guard let deadline else { return seconds }
        return max(0, min(seconds, Int(deadline.timeIntervalSince(date).rounded(.up))))
    }

    private func fraction(_ remaining: Int) -> Double {
        seconds > 0 ? Double(remaining) / Double(seconds) : 0
    }
}

#Preview {
    VStack(spacing: 32) {
        Countdown(seconds: 5)
        Countdown(seconds: 90)
    }
    .padding()
    .background(Color.felt)
}
