import SwiftUI

struct TimerView: View {
    @ObservedObject var vm: TimerViewModel
    @State private var manualText: String = ""
    @FocusState private var timerFocused: Bool

    private let presets: [(label: String, seconds: Int)] = [
        ("1m", 60),
        ("15m", 15 * 60),
        ("30m", 30 * 60),
        ("45m", 45 * 60)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TASK")
                    .font(Pixel.font(9))
                    .foregroundColor(Pixel.navy)
                TextField("What are you focusing on?", text: $vm.taskName)
                    .textFieldStyle(.plain)
                    .font(Pixel.font(12))
                    .foregroundColor(Pixel.navy)
                    .tint(Pixel.navy)
                    .padding(8)
                    .pixelBox(fill: .white)
                    .onSubmit {
                        if !vm.isRunning { vm.start() }
                    }
            }

            VStack(spacing: 6) {
                if vm.isRunning {
                    Text(vm.displayString)
                        .font(Pixel.font(36))
                        .foregroundColor(Pixel.navy)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .pixelBox(fill: Pixel.yellow.opacity(0.35))
                } else {
                    TextField("25:00", text: $manualText)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .font(Pixel.font(36))
                        .foregroundColor(Pixel.navy)
                        .focused($timerFocused)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .pixelBox(fill: Pixel.yellow.opacity(0.35))
                        .onSubmit { commitManualEdit() }
                        .onChange(of: timerFocused) { focused in
                            if !focused { commitManualEdit() }
                        }
                }

                Group {
                    if vm.isRunning {
                        RollingPokeball()
                    } else {
                        Color.clear.frame(height: 28)
                    }
                }
                .frame(height: 28)

                HStack(spacing: 6) {
                    ForEach(presets, id: \.seconds) { preset in
                        Button(preset.label) { vm.requestPreset(preset.seconds) }
                            .buttonStyle(PixelButtonStyle(tint: Pixel.blue.opacity(0.9), textColor: .white))
                    }
                }
            }

            HStack(spacing: 8) {
                if vm.isRunning {
                    Button("PAUSE") { vm.pause() }
                        .buttonStyle(PixelButtonStyle(tint: Pixel.yellow))
                } else {
                    Button("START") { vm.start() }
                        .buttonStyle(PixelButtonStyle(tint: Pixel.green, textColor: .white))
                        .disabled(!vm.canStart)
                }
                Button("DONE") { vm.finish() }
                    .buttonStyle(PixelButtonStyle(tint: Pixel.blue, textColor: .white))
                    .disabled(!vm.canFinish)
                Button("RESET") { vm.reset() }
                    .buttonStyle(PixelButtonStyle(tint: Pixel.red, textColor: .white))
            }
            .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear { manualText = vm.displayString }
        .onChange(of: vm.remainingSeconds) { _ in
            if !vm.isRunning && !timerFocused {
                manualText = vm.displayString
            }
        }
        .confirmationDialog(
            "Cancel current session?",
            isPresented: Binding(
                get: { vm.pendingPresetSeconds != nil },
                set: { if !$0 { vm.cancelPendingPreset() } }
            ),
            presenting: vm.pendingPresetSeconds
        ) { seconds in
            Button("Switch to \(seconds / 60)m", role: .destructive) {
                vm.confirmPendingPreset()
                manualText = vm.displayString
            }
            Button("Keep current", role: .cancel) { vm.cancelPendingPreset() }
        } message: { seconds in
            Text("Your \(vm.taskName.isEmpty ? "session" : vm.taskName) will be discarded.")
        }
    }

    private func commitManualEdit() {
        vm.parseAndApplyManual(manualText)
        manualText = vm.displayString
    }
}
