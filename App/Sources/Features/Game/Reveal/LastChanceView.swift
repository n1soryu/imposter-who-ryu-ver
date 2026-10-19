import SwiftUI

/// The caught imposter gets one guess at the secret word.
struct LastChanceView: View {
    var imposterName: String
    var guess: (String?) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Caught!")
                .font(.display(64))
                .foregroundStyle(Color.imposterInk)
            Text("\(imposterName) was the imposter. They get one last chance: guess the word to steal the win.")
                .font(.title3)
                .foregroundStyle(Color.cardStock)
                .padding(.top, 8)

            TextField("Their guess", text: $text)
                .font(.displaySemiBold(26, relativeTo: .title2))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit(submit)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.feltRaised, in: .rect(cornerRadius: 18))
                .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Button("Lock in the guess", action: submit)
                    .buttonStyle(.pill)
                    .disabled(trimmed.isEmpty)
                Button("\(imposterName) gives up", action: giveUp)
                    .buttonStyle(.pillSecondary)
            }
        }
        .padding(Metrics.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.felt)
        .onAppear(perform: focusField)
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespaces)
    }

    private func submit() {
        guard trimmed.isEmpty == false else { return }
        guess(trimmed)
    }

    private func giveUp() {
        guess(nil)
    }

    private func focusField() {
        isFocused = true
    }
}

#Preview {
    LastChanceView(imposterName: "Ben") { _ in }
}
