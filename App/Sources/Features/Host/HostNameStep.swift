import ImposterKit
import SwiftUI

/// Asks for the host's name, then starts listening for phones.
struct HostNameStep: View {
    @Environment(HostStore.self) private var host
    @Environment(RosterStore.self) private var roster
    @Environment(\.wordLibrary) private var library

    @State private var name = ""
    @State private var problem: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Friends join from their own phones, with no app to install. You play on this one.")
                    .font(.title3)
                    .foregroundStyle(Color.haze)

                Text("Your name")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.haze)
                    .padding(.top, 28)
                TextField("Your name", text: $name)
                    .font(.displaySemiBold(26, relativeTo: .title2))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($isFocused)
                    .onSubmit(begin)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.feltRaised, in: .rect(cornerRadius: 18))
                    .padding(.top, 8)

                if let problem {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(Color.imposterInk)
                        .padding(.top, 8)
                }
            }
            .padding(Metrics.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.felt)
        .safeAreaInset(edge: .bottom) {
            Button("Start hosting", action: begin)
                .buttonStyle(.pill)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 12)
                .background(Color.felt)
        }
        .onAppear(perform: prefill)
    }

    private func prefill() {
        if name.isEmpty { name = roster.players.first?.name ?? "" }
    }

    private func begin() {
        do {
            try host.begin(hostName: name, library: library)
        } catch {
            problem = error.message
        }
    }
}
