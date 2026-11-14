import SwiftUI
import Network
import KastideoCore

/// Recherche des Apple TV Kastideo sur le réseau local (service Bonjour « _kastideo._tcp »).
@MainActor @Observable
final class IOSTVBrowser {
    struct Box: Identifiable, Hashable {
        let name: String
        let endpoint: NWEndpoint
        var id: String { name }
    }
    private(set) var found: [Box] = []
    @ObservationIgnored private var browser: NWBrowser?

    func start() {
        guard browser == nil else { return }
        let browser = NWBrowser(for: .bonjour(type: "_kastideo._tcp", domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let boxes = results.compactMap { result -> Box? in
                if case .service(let name, _, _, _) = result.endpoint { return Box(name: name, endpoint: result.endpoint) }
                return nil
            }.sorted { $0.name < $1.name }
            Task { @MainActor in self?.found = boxes }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }
}

/// Envoi HTTP minimal vers l'Apple TV (POST /import).
enum IOSTVSender {
    private final class State: @unchecked Sendable {
        var buffer = Data()
        var finished = false
    }

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func post(to endpoint: NWEndpoint, code: String, body: Data) async throws -> String {
        let connection = NWConnection(to: endpoint, using: .tcp)
        let state = State()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            @Sendable func finish(_ result: Result<String, Error>) {
                guard !state.finished else { return }
                state.finished = true
                connection.cancel()
                continuation.resume(with: result)
            }
            @Sendable func receive() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                    if let data { state.buffer.append(data) }
                    if isComplete || error != nil {
                        let text = String(decoding: state.buffer, as: UTF8.self)
                        let status = Int(text.split(separator: " ").dropFirst().first ?? "") ?? 0
                        let reply = text.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")
                        if status == 200 { finish(.success(reply)) }
                        else if status == 0 { finish(.failure(Failure(message: String(localized: "L'Apple TV n'a pas répondu.")))) }
                        else { finish(.failure(Failure(message: reply.isEmpty ? "HTTP \(status)" : reply))) }
                    } else {
                        receive()
                    }
                }
            }
            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    var head = "POST /import?code=\(code) HTTP/1.1\r\nHost: kastideo\r\nContent-Type: application/json\r\n"
                    head += "Content-Length: \(body.count)\r\nConnection: close\r\n\r\n"
                    connection.send(content: Data(head.utf8) + body, completion: .contentProcessed { error in
                        if let error { finish(.failure(error)) } else { receive() }
                    })
                case .failed(let error):
                    finish(.failure(error))
                case .waiting:
                    break
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
            Task {
                try? await Task.sleep(for: .seconds(20))
                finish(.failure(Failure(message: String(localized: "Délai dépassé : vérifiez que l'écran « Ajouter depuis un téléphone » est ouvert sur l'Apple TV et que l'accès au réseau local est autorisé."))))
            }
        }
    }
}

/// Réglages > Sauvegarde > Envoyer vers l'Apple TV : sources, favoris, catégories et réglages.
struct IOSSendToTVView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(MediaInfoStore.self) private var mediaInfo
    @State private var browser = IOSTVBrowser()
    @State private var selected: IOSTVBrowser.Box?
    @State private var code = ""
    @State private var includePasswords = true
    @State private var busy = false
    @State private var message: String?
    @State private var failed = false

    var body: some View {
        Form {
            Section {
                Text("Sur l'Apple TV : Réglages > Ajouter depuis un téléphone. Le téléviseur affiche un code à 4 chiffres ; l'iPhone et l'Apple TV doivent être sur le même réseau Wi-Fi.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Apple TV détectées") {
                if browser.found.isEmpty {
                    HStack { ProgressView(); Text("Recherche…").foregroundStyle(.secondary) }
                }
                ForEach(browser.found) { box in
                    Button {
                        selected = box
                    } label: {
                        HStack {
                            Label(box.name, systemImage: "appletv")
                            Spacer()
                            if selected == box { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                    }
                    .tint(.primary)
                }
            }
            Section("Envoi") {
                TextField("Code affiché sur le téléviseur", text: $code).keyboardType(.numberPad)
                Toggle("Inclure les mots de passe", isOn: $includePasswords)
                Button {
                    Task { await send() }
                } label: {
                    if busy { ProgressView() } else { Label("Envoyer vers l'Apple TV", systemImage: "paperplane.fill") }
                }
                .disabled(busy || selected == nil || code.count != 4)
                if let message { Text(message).font(.footnote).foregroundStyle(failed ? Color.red : Color.green) }
            }
        }
        .navigationTitle("Envoyer vers l'Apple TV")
        .onAppear { browser.start() }
        .onDisappear { browser.stop() }
        .onChange(of: browser.found) { _, list in
            if selected == nil, list.count == 1 { selected = list.first }
        }
    }

    private func send() async {
        guard let selected else { return }
        busy = true
        message = nil
        defer { busy = false }
        var export = store.makeExport(includePasswords: includePasswords)
        export.app = "ios"
        if mediaInfo.usesTMDB { export.settings["tmdbKey"] = mediaInfo.tmdbKey }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(export)
            _ = try await IOSTVSender.post(to: selected.endpoint, code: code, body: data)
            failed = false
            message = String(localized: "Configuration envoyée à l'Apple TV.")
        } catch {
            failed = true
            message = error.localizedDescription
        }
    }
}
