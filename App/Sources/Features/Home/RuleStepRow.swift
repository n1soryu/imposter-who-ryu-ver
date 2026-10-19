import SwiftUI

struct RuleStepRow: View {
    var number: Int
    var step: RuleStep

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text("\(number)")
                .font(.display(28, relativeTo: .title2))
                .foregroundStyle(Color.crewInk)
                .frame(minWidth: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.displaySemiBold(22, relativeTo: .title3))
                    .foregroundStyle(Color.cardStock)
                Text(step.detail)
                    .foregroundStyle(Color.haze)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
