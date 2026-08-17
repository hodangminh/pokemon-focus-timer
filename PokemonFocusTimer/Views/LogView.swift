import SwiftUI

struct LogView: View {
    @ObservedObject var vm: TimerViewModel

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LOG")
                .font(Pixel.font(11))
                .foregroundColor(Pixel.navy)
                .padding(.horizontal, 14)
                .padding(.top, 10)

            if vm.entries.isEmpty {
                Text("No sessions yet.")
                    .font(Pixel.font(10))
                    .foregroundColor(Pixel.navy.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(vm.entries.reversed()) { entry in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.taskName)
                                        .font(Pixel.font(11))
                                        .foregroundColor(Pixel.navy)
                                    Text(Self.dateFormatter.string(from: entry.startedAt))
                                        .font(Pixel.font(9))
                                        .foregroundColor(Pixel.navy.opacity(0.6))
                                }
                                Spacer()
                                Text(formatDuration(entry.durationSeconds))
                                    .font(Pixel.font(11))
                                    .foregroundColor(Pixel.darkRed)
                            }
                            .padding(8)
                            .pixelBox(fill: .white, lineWidth: 2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private func formatDuration(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        if sec == 0 { return "\(m)m" }
        return "\(m)m \(sec)s"
    }
}
