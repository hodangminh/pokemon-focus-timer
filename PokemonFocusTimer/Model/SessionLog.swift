import Foundation

struct SessionEntry: Codable, Identifiable {
    let id: UUID
    let taskName: String
    let startedAt: Date
    let durationSeconds: Int

    init(id: UUID = UUID(), taskName: String, startedAt: Date, durationSeconds: Int) {
        self.id = id
        self.taskName = taskName
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
    }
}

enum SessionLog {
    private static let filename = "log.json"

    private static var fileURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FocusTimer", isDirectory: true)
        if !fm.fileExists(atPath: base.path) {
            try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base.appendingPathComponent(filename)
    }

    static func load() -> [SessionEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SessionEntry].self, from: data)) ?? []
    }

    static func save(_ entries: [SessionEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func append(_ entry: SessionEntry) -> [SessionEntry] {
        var entries = load()
        entries.append(entry)
        save(entries)
        return entries
    }
}
