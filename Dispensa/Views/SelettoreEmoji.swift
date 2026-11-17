//
//  SelettoreEmoji.swift
//  Dispensa
//

import SwiftUI

/// Riga di un modulo per scegliere l'emoji di un prodotto o di una categoria:
/// apre una griglia di emoji adatte a una dispensa, con "Nessuna emoji" e un campo per scriverne un'altra.
struct SelettoreEmoji: View {
    let titolo: LocalizedStringKey
    /// L'emoji scelta; stringa vuota = nessuna.
    @Binding var selezione: String
    /// L'emoji che si userebbe senza sceglierne una (dalla categoria), mostrata come suggerimento.
    var ereditata: String?

    @State private var aperto = false

    var body: some View {
        Button {
            aperto = true
        } label: {
            LabeledContent(titolo) {
                if selezione.isEmpty {
                    if let ereditata {
                        Text("Nessuna (\(ereditata))")
                    } else {
                        Text("Nessuna")
                    }
                } else {
                    Text(selezione)
                        .font(.title2)
                }
            }
            .foregroundStyle(.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $aperto) {
            GrigliaEmojiView(selezione: $selezione)
        }
    }
}

/// Il contenuto del selettore: le emoji divise per gruppi.
private struct GrigliaEmojiView: View {
    @Binding var selezione: String
    @Environment(\.dismiss) private var dismiss
    @State private var altra = ""

    private let colonne = [GridItem(.adaptive(minimum: 44), spacing: 4)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button("Nessuna emoji", systemImage: "xmark.circle") { scegli("") }

                    ForEach(GruppoEmoji.tutti) { gruppo in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(gruppo.nome)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: colonne, spacing: 4) {
                                ForEach(gruppo.emoji, id: \.self) { emoji in
                                    pulsante(emoji)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Altra emoji")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Altra emoji", text: $altra, prompt: Text("Scrivi un'emoji"))
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if let scelta = Categoria.iconaNormalizzata(altra) { scegli(scelta) }
                            }
                            .onChange(of: altra) { _, nuovo in
                                // Con la tastiera emoji basta toccarne una: viene scelta subito.
                                if let scelta = Categoria.iconaNormalizzata(nuovo), scelta.unicodeScalars.contains(where: \.properties.isEmojiPresentation) {
                                    scegli(scelta)
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Emoji")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
#if os(macOS)
        .frame(width: 380, height: 460)
#endif
    }

    private func pulsante(_ emoji: String) -> some View {
        Button {
            scegli(emoji)
        } label: {
            Text(emoji)
                .font(.title)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(emoji == selezione ? Color.accentColor.opacity(0.25) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(emoji == selezione ? .isSelected : [])
    }

    private func scegli(_ emoji: String) {
        selezione = emoji
        dismiss()
    }
}

/// Un gruppo di emoji del selettore.
private struct GruppoEmoji: Identifiable {
    let nome: LocalizedStringKey
    let emoji: [String]

    var id: String { emoji.first ?? "" }

    static let tutti: [GruppoEmoji] = [
        GruppoEmoji(nome: "Frutta e verdura", emoji: ["🍎", "🍐", "🍊", "🍋", "🍌", "🍇", "🍓", "🍒", "🍑", "🍍", "🥝", "🍅", "🥕", "🥔", "🧅", "🧄", "🥦", "🥬", "🥒", "🌶️", "🫑", "🍆", "🌽", "🍄", "🫘", "🥜"]),
        GruppoEmoji(nome: "Carne e pesce", emoji: ["🥩", "🍗", "🥓", "🍖", "🌭", "🐟", "🦐", "🦑", "🦪"]),
        GruppoEmoji(nome: "Latticini e uova", emoji: ["🥛", "🧀", "🧈", "🥚", "🍦"]),
        GruppoEmoji(nome: "Pane, pasta e cereali", emoji: ["🍞", "🥖", "🥐", "🥨", "🍝", "🍚", "🌾", "🥣", "🍕"]),
        GruppoEmoji(nome: "Dispensa e condimenti", emoji: ["🫒", "🧂", "🍯", "🥫", "🫙", "🍲", "🥗", "🌿"]),
        GruppoEmoji(nome: "Dolci e snack", emoji: ["🍪", "🍫", "🍬", "🍰", "🧁", "🍩", "🍿"]),
        GruppoEmoji(nome: "Bevande", emoji: ["💧", "☕️", "🍵", "🧃", "🥤", "🍺", "🍷", "🍾"]),
        GruppoEmoji(nome: "Surgelati e casa", emoji: ["🧊", "❄️", "🧻", "🧼", "🧽", "🧴", "💊", "🐾"]),
    ]
}

#Preview {
    @Previewable @State var emoji = "🍝"
    Form {
        SelettoreEmoji(titolo: "Emoji", selezione: $emoji, ereditata: "🌾")
    }
}
