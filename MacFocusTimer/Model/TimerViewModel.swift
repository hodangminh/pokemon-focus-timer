import Foundation
import AppKit
import Combine

@MainActor
final class TimerViewModel: ObservableObject {
    @Published var taskName: String = ""
    @Published var initialSeconds: Int = 25 * 60
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var entries: [SessionEntry] = SessionLog.load()

    @Published var pendingPresetSeconds: Int? = nil

    private var ticker: AnyCancellable?
    private var startedAt: Date?

    var displayString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        if startedAt == nil { startedAt = Date() }
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
    }

    func reset() {
        pause()
        remainingSeconds = initialSeconds
        startedAt = nil
    }

    func setDuration(seconds: Int) {
        initialSeconds = max(1, seconds)
        remainingSeconds = initialSeconds
        startedAt = nil
    }

    func requestPreset(_ seconds: Int) {
        if isRunning {
            pendingPresetSeconds = seconds
        } else {
            setDuration(seconds: seconds)
        }
    }

    func confirmPendingPreset() {
        guard let seconds = pendingPresetSeconds else { return }
        pause()
        setDuration(seconds: seconds)
        pendingPresetSeconds = nil
    }

    func cancelPendingPreset() {
        pendingPresetSeconds = nil
    }

    func parseAndApplyManual(_ text: String) {
        let parts = text.split(separator: ":")
        var minutes = 0
        var seconds = 0
        if parts.count == 2 {
            minutes = Int(parts[0]) ?? 0
            seconds = Int(parts[1]) ?? 0
        } else if parts.count == 1 {
            minutes = Int(parts[0]) ?? 0
        }
        minutes = min(max(minutes, 0), 180)
        seconds = min(max(seconds, 0), 59)
        let total = minutes * 60 + seconds
        if total > 0 {
            setDuration(seconds: total)
        }
    }

    private func tick() {
        guard isRunning else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            complete()
        }
    }

    private func complete() {
        pause()
        let duration = initialSeconds
        let name = taskName.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : taskName
        let entry = SessionEntry(taskName: name, startedAt: startedAt ?? Date(), durationSeconds: duration)
        entries = SessionLog.append(entry)
        NSSound.beep()
        startedAt = nil
        remainingSeconds = initialSeconds
    }

    var canFinish: Bool {
        startedAt != nil
    }

    func finish() {
        guard let start = startedAt else { return }
        pause()
        let elapsed = max(1, initialSeconds - remainingSeconds)
        let name = taskName.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : taskName
        let entry = SessionEntry(taskName: name, startedAt: start, durationSeconds: elapsed)
        entries = SessionLog.append(entry)
        startedAt = nil
        remainingSeconds = initialSeconds
    }
}
