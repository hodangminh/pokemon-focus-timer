import Testing
import Foundation
@testable import MacFocusTimer

@MainActor
struct TimerViewModelTests {

    @Test func defaultsToTwentyFiveMinutes() {
        let vm = TimerViewModel()
        #expect(vm.initialSeconds == 25 * 60)
        #expect(vm.remainingSeconds == 25 * 60)
        #expect(vm.isRunning == false)
        #expect(vm.displayString == "25:00")
        #expect(vm.canFinish == false)
    }

    @Test func displayStringFormatsMinutesAndSeconds() {
        let vm = TimerViewModel()
        vm.setDuration(seconds: 65)
        #expect(vm.displayString == "01:05")
        vm.setDuration(seconds: 9)
        #expect(vm.displayString == "00:09")
    }

    @Test func startTransitionsToRunningAndEnablesFinish() {
        let vm = TimerViewModel()
        vm.start()
        #expect(vm.isRunning == true)
        #expect(vm.canFinish == true)
        vm.pause()
        #expect(vm.isRunning == false)
        // canFinish stays true after pause because startedAt is preserved
        #expect(vm.canFinish == true)
    }

    @Test func startIsNoopWhenRemainingIsZero() {
        let vm = TimerViewModel()
        vm.setDuration(seconds: 1)
        vm.remainingSeconds = 0
        vm.start()
        #expect(vm.isRunning == false)
    }

    @Test func resetClearsRunningAndRestoresInitial() {
        let vm = TimerViewModel()
        vm.setDuration(seconds: 120)
        vm.start()
        vm.remainingSeconds = 30
        vm.reset()
        #expect(vm.isRunning == false)
        #expect(vm.remainingSeconds == 120)
        #expect(vm.canFinish == false)
    }

    @Test func setDurationClampsMinimumToOne() {
        let vm = TimerViewModel()
        vm.setDuration(seconds: 0)
        #expect(vm.initialSeconds == 1)
        #expect(vm.remainingSeconds == 1)

        vm.setDuration(seconds: -50)
        #expect(vm.initialSeconds == 1)
    }

    @Test func parseAndApplyManualAcceptsMinutesAndSeconds() {
        let vm = TimerViewModel()
        vm.parseAndApplyManual("10:30")
        #expect(vm.initialSeconds == 10 * 60 + 30)
        #expect(vm.remainingSeconds == 10 * 60 + 30)
    }

    @Test func parseAndApplyManualAcceptsMinutesOnly() {
        let vm = TimerViewModel()
        vm.parseAndApplyManual("7")
        #expect(vm.initialSeconds == 7 * 60)
    }

    @Test func parseAndApplyManualClampsMinutesTo180AndSecondsTo59() {
        let vm = TimerViewModel()
        vm.parseAndApplyManual("500:99")
        #expect(vm.initialSeconds == 180 * 60 + 59)
    }

    @Test func parseAndApplyManualIgnoresZeroOrGarbage() {
        let vm = TimerViewModel()
        vm.setDuration(seconds: 300)
        vm.parseAndApplyManual("0:0")
        #expect(vm.initialSeconds == 300)
        vm.parseAndApplyManual("abc")
        #expect(vm.initialSeconds == 300)
    }

    @Test func requestPresetAppliesImmediatelyWhenNotRunning() {
        let vm = TimerViewModel()
        vm.requestPreset(15 * 60)
        #expect(vm.initialSeconds == 15 * 60)
        #expect(vm.pendingPresetSeconds == nil)
    }

    @Test func requestPresetDefersWhenRunning() {
        let vm = TimerViewModel()
        vm.start()
        vm.requestPreset(45 * 60)
        #expect(vm.pendingPresetSeconds == 45 * 60)
        #expect(vm.initialSeconds == 25 * 60)
    }

    @Test func confirmPendingPresetAppliesAndClears() {
        let vm = TimerViewModel()
        vm.start()
        vm.requestPreset(45 * 60)
        vm.confirmPendingPreset()
        #expect(vm.initialSeconds == 45 * 60)
        #expect(vm.remainingSeconds == 45 * 60)
        #expect(vm.pendingPresetSeconds == nil)
        #expect(vm.isRunning == false)
    }

    @Test func cancelPendingPresetLeavesTimerUntouched() {
        let vm = TimerViewModel()
        vm.start()
        vm.requestPreset(30 * 60)
        vm.cancelPendingPreset()
        #expect(vm.pendingPresetSeconds == nil)
        #expect(vm.initialSeconds == 25 * 60)
        #expect(vm.isRunning == true)
        vm.pause()
    }

    @Test func finishIsNoopBeforeStart() {
        let vm = TimerViewModel()
        let countBefore = vm.entries.count
        vm.finish()
        #expect(vm.entries.count == countBefore)
        #expect(vm.canFinish == false)
    }
}

struct SessionEntryTests {

    @Test func codableRoundtripPreservesFields() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = SessionEntry(taskName: "Write tests", startedAt: start, durationSeconds: 1500)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionEntry.self, from: data)

        #expect(decoded.id == entry.id)
        #expect(decoded.taskName == "Write tests")
        #expect(decoded.startedAt == start)
        #expect(decoded.durationSeconds == 1500)
    }

    @Test func defaultInitAssignsUniqueIds() {
        let a = SessionEntry(taskName: "a", startedAt: Date(), durationSeconds: 60)
        let b = SessionEntry(taskName: "a", startedAt: Date(), durationSeconds: 60)
        #expect(a.id != b.id)
    }
}
