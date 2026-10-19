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
                Text(isExpired ? "Time's up" : Self.format(remaining))
                    .font(.displaySemiBold(22, relativeTo: .title3))
                    .monospacedDigit()
                    .foregroundStyle(isExpired ? Color.imposterInk : Color.cardStock)
                    .contentTransition(.numericText(countsDown: true))
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.feltRaised)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(isExpired ? Color.imposterInk : Color.crewInk)
                                .frame(width: proxy.size.width * fraction(remaining))
                        }
                }
                .frame(height: 8)
                .animation(.linear(duration: 1), value: remaining)
            }
        }
        .onAppear {
            deadline = .now.addingTimeInterval(TimeInterval(seconds))
        }
        .task {
            try? await Task.sleep(for: .seconds(seconds))
            isExpired = true
        }
        .sensoryFeedback(.warning, trigger: isExpired) { _, expired in expired }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isExpired ? "Time's up" : "Timer running, \(seconds) seconds")
    }

    private func remainingSeconds(at date: Date) -> Int {
        guard let deadline else { return seconds }
        return max(0, Int(deadline.timeIntervalSince(date).rounded(.up)))
    }

    private func fraction(_ remaining: Int) -> CGFloat {
        seconds > 0 ? CGFloat(remaining) / CGFloat(seconds) : 0
    }

    static func format(_ seconds: Int) -> String {
        seconds >= 60 ? String(format: "%d:%02d", seconds / 60, seconds % 60) : "\(seconds)s"
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
