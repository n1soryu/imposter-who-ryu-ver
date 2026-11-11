import SwiftUI

/// The caught imposter gets one guess at the secret word.
struct LastChanceView: View {
    var imposterName: String
    /// The phone's owner is the imposter, as in host mode, so the copy says "you".
    var isYou = false
    var guess: (String?) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Caught!")
                    .font(.display(64))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color.imposterGlow)
                Text(isYou
                     ? "You were the imposter. You get one last chance: guess the word to steal the win."
                     : "\(imposterName) was the imposter. They get one last chance: guess the word to steal the win.")
                    .font(.title3)
                    .foregroundStyle(Color.cardStock)
                    .padding(.top, 8)
    
                TextField(isYou ? "Your guess" : "Their guess", text: $text, prompt: Text(isYou ? "Your guess" : "Their guess").foregroundStyle(Color.haze))
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
            }
            .padding(Metrics.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.never)
        .background(Color.felt)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Lock in the guess", action: submit)
                    .buttonStyle(.pill)
                    .disabled(trimmed.isEmpty)
                Button(isYou ? "I give up" : "\(imposterName) gives up", action: giveUp)
                    .buttonStyle(.pillSecondary)
            }
            .padding(Metrics.gutter)
            .background(Color.felt)
        }
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
