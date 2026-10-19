import SwiftUI

/// The last row of the player list: type a name and press Next to add it.
struct AddPlayerField: View {
    @Binding var name: String
    var isFocused: FocusState<Bool>.Binding
    var isFull: Bool
    var submit: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "plus")
                .foregroundStyle(Color.crewInk)
                .frame(minWidth: 22, alignment: .trailing)
                .accessibilityHidden(true)
            TextField(isFull ? "The table is full" : "Add a player", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused(isFocused)
                .onSubmit(submit)
                .disabled(isFull)
        }
    }
}
