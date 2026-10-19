import SwiftUI

/// The last row of a pack's word list: type a word and press Add.
struct AddWordField: View {
    @Binding var word: String
    var isFocused: FocusState<Bool>.Binding
    var submit: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "plus")
                .foregroundStyle(Color.crewInk)
                .accessibilityHidden(true)
            TextField("Add a word", text: $word)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused(isFocused)
                .onSubmit(submit)
        }
    }
}
