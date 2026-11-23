//
//  MenuVista.swift
//  Dispensa
//

import SwiftUI
import SwiftData

extension EnvironmentValues {
    /// Azione "Salva come vista…" offerta dal foglio dei filtri (`nil` se non disponibile).
    @Entry var salvaComeVista: (() -> Void)? = nil
}

extension View {
    /// Aggiunge nella barra il menu "Vista": viste salvate, filtri, ordinamento, salvataggio e gestione delle viste.
    /// `filtri` è il foglio dei filtri di questo elenco. Senza dispensa restano solo filtri e ordinamento.
    func menuVista<Filtro: FiltroSalvabile, Criterio: CriterioOrdinamento, Filtri: View>(
        _ stato: Binding<StatoElenco<Filtro, Criterio>>,
        dispensa: Dispensa?,
        @ViewBuilder filtri: @escaping () -> Filtri
    ) -> some View {
        modifier(ModificatoreVista(stato: stato, dispensa: dispensa, filtri: filtri))
    }
}

private struct ModificatoreVista<Filtro: FiltroSalvabile, Criterio: CriterioOrdinamento, Filtri: View>: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var stato: StatoElenco<Filtro, Criterio>
    let dispensa: Dispensa?
    let filtri: () -> Filtri

    @State private var mostraFiltri = false
    /// "Salva come vista…" scelto dal foglio dei filtri: il nome si chiede quando il foglio si è chiuso.
    @State private var salvaDopoIFiltri = false
    @State private var chiediNome = false
    @State private var nome = ""
    @State private var mostraGestione = false
    @State private var errore: String?

    private var viste: [VistaSalvata] {
        dispensa?.viste(per: stato.tipo) ?? []
    }

    private var applicata: VistaSalvata? {
        dispensa.flatMap { stato.vistaApplicata(in: $0) }
    }

    private var attivo: Bool { !stato.filtro.vuoto || applicata != nil }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    menu
                }
            }
            .sheet(isPresented: $mostraFiltri, onDismiss: {
                if salvaDopoIFiltri {
                    salvaDopoIFiltri = false
                    chiediNuovoNome()
                }
            }) {
                filtri()
                    .environment(\.salvaComeVista, dispensa == nil ? nil : { salvaDopoIFiltri = true })
            }
            .sheet(isPresented: $mostraGestione) {
                if let dispensa {
                    GestioneVisteView(dispensa: dispensa, tipo: stato.tipo)
                }
            }
            .alert("Salva vista", isPresented: $chiediNome) {
                TextField("Nome", text: $nome)
                Button("Annulla", role: .cancel) {}
                Button("Salva", action: salva)
            } message: {
                Text("Filtri e ordine attuali verranno salvati con questo nome.")
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } }),
                presenting: errore
            ) { _ in
                Button("OK") {}
            } message: { errore in
                Text(errore)
            }
    }

    private var menu: some View {
        Menu {
            if let dispensa, !viste.isEmpty {
                Section("Viste salvate") {
                    ForEach(viste) { vista in
                        Button {
                            stato.applica(vista, in: dispensa)
                        } label: {
                            if vista.id == applicata?.id {
                                Label(vista.nome, systemImage: "checkmark")
                            } else {
                                Text(vista.nome)
                            }
                            // Seconda riga della voce di menu.
                            if vista.predefinita {
                                Text("Predefinita")
                            }
                        }
                    }
                }
            }
            Section {
                if attivo {
                    Button("Mostra tutto", systemImage: "xmark.circle") { stato.mostraTutto() }
                }
                Button("Filtri…", systemImage: "line.3.horizontal.decrease.circle") { mostraFiltri = true }
                Menu {
                    ScelteOrdinamento(criteri: stato.criteri, ordine: $stato.ordine)
                } label: {
                    Label("Ordina", systemImage: "arrow.up.arrow.down")
                }
            }
            if let dispensa {
                Section {
                    Button("Salva come vista…", systemImage: "rectangle.stack.badge.plus", action: chiediNuovoNome)
                    if let applicata, stato.differisce(da: applicata, in: dispensa) {
                        Button("Aggiorna «\(applicata.nome)»", systemImage: "arrow.triangle.2.circlepath") {
                            modelContext.aggiornaVista(applicata, con: stato)
                        }
                    }
                    if let applicata {
                        if applicata.predefinita {
                            Button("Togli predefinita", systemImage: "star.slash") {
                                modelContext.togliPredefinita(applicata)
                            }
                        } else {
                            Button("Usa come predefinita", systemImage: "star") {
                                modelContext.impostaPredefinita(applicata)
                            }
                        }
                    }
                    if !viste.isEmpty {
                        Button("Gestisci viste…", systemImage: "slider.horizontal.3") { mostraGestione = true }
                    }
                }
            }
        } label: {
            Label(
                "Vista",
                systemImage: attivo ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
            )
        }
        .accessibilityValue(valoreAccessibilita)
    }

    /// VoiceOver legge la vista applicata o quanti filtri sono attivi.
    private var valoreAccessibilita: Text {
        if let applicata {
            Text(applicata.nome)
        } else if !stato.filtro.vuoto {
            Text("Filtri attivi: \(stato.filtro.numeroAttivi)")
        } else {
            Text("")
        }
    }

    private func chiediNuovoNome() {
        nome = ""
        chiediNome = true
    }

    private func salva() {
        guard let dispensa else { return }
        do {
            let vista = try modelContext.creaVista(nome: nome, stato: stato, in: dispensa)
            stato.vista = vista.id
        } catch {
            errore = error.localizedDescription
        }
    }
}

/// Elenco delle viste salvate di un elenco, per rinominarle o eliminarle.
struct GestioneVisteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    let tipo: TipoElenco

    @State private var daRinominare: VistaSalvata?
    @State private var nome = ""
    @State private var errore: String?

    var body: some View {
        let viste = dispensa.viste(per: tipo)
        NavigationStack {
            List {
                ForEach(viste) { vista in
                    HStack {
                        Text(vista.nome)
                        if vista.predefinita {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .accessibilityLabel(Text("Predefinita"))
                        }
                        Spacer()
                        // Un menu nella riga: sul Mac non ci sono le azioni a scorrimento.
                        Menu {
                            pulsantePredefinita(vista)
                            pulsanteRinomina(vista)
                            pulsanteElimina(vista)
                        } label: {
                            Label("Azioni per \(vista.nome)", systemImage: "ellipsis.circle")
                                .labelStyle(.iconOnly)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                    .swipeActions {
                        pulsanteElimina(vista)
                        pulsanteRinomina(vista)
                    }
                    .contextMenu {
                        pulsantePredefinita(vista)
                        pulsanteRinomina(vista)
                        pulsanteElimina(vista)
                    }
                }
            }
            .overlay {
                if viste.isEmpty {
                    ContentUnavailableView(
                        "Nessuna vista salvata",
                        systemImage: "rectangle.stack",
                        description: Text("Scegli i filtri e l'ordine, poi «Salva come vista…» nel menu Vista.")
                    )
                }
            }
            .navigationTitle("Viste salvate")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .alert(
                "Rinomina vista",
                isPresented: Binding(get: { daRinominare != nil }, set: { if !$0 { daRinominare = nil } }),
                presenting: daRinominare
            ) { vista in
                TextField("Nome", text: $nome)
                Button("Annulla", role: .cancel) {}
                Button("Salva") { rinomina(vista) }
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } }),
                presenting: errore
            ) { _ in
                Button("OK") {}
            } message: { errore in
                Text(errore)
            }
        }
#if os(macOS)
        .frame(minWidth: 360, minHeight: 320)
#endif
    }

    @ViewBuilder
    private func pulsantePredefinita(_ vista: VistaSalvata) -> some View {
        if vista.predefinita {
            Button("Togli predefinita", systemImage: "star.slash") { modelContext.togliPredefinita(vista) }
        } else {
            Button("Imposta come predefinita", systemImage: "star") { modelContext.impostaPredefinita(vista) }
        }
    }

    private func pulsanteRinomina(_ vista: VistaSalvata) -> some View {
        Button("Rinomina", systemImage: "pencil") {
            nome = vista.nome
            daRinominare = vista
        }
        .tint(.accentColor)
    }

    /// Una vista si elimina senza conferma: non si perde nient'altro.
    private func pulsanteElimina(_ vista: VistaSalvata) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) {
            modelContext.eliminaVista(vista)
        }
    }

    private func rinomina(_ vista: VistaSalvata) {
        do {
            try modelContext.rinominaVista(vista, nome: nome)
        } catch {
            errore = error.localizedDescription
        }
    }
}
