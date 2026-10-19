import SwiftUI

struct StandingRow: View {
    var place: Int
    var name: String
    var points: Int
    var isLeader: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text("\(place)")
                .font(.displaySemiBold(20, relativeTo: .title3))
                .monospacedDigit()
                .frame(minWidth: 24, alignment: .trailing)
                .foregroundStyle(isLeader ? Color.felt : Color.haze)
            Text(name)
                .font(.displaySemiBold(22, relativeTo: .title3))
            Spacer()
            Text("\(points)")
                .font(.display(28, relativeTo: .title2))
                .monospacedDigit()
        }
        .foregroundStyle(isLeader ? Color.felt : Color.cardStock)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(isLeader ? Color.crewInk : Color.feltRaised, in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place \(place), \(name), ^[\(points) point](inflect: true)\(isLeader ? ", leading" : "")")
    }
}
