import SwiftUI

enum Tab {
    case timer, log
}

struct PopoverView: View {
    @StateObject private var vm = TimerViewModel()
    @State private var tab: Tab = .timer
    @State private var cursorX: CGFloat? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                if tab == .timer {
                    TimerView(vm: vm)
                } else {
                    LogView(vm: vm)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 320, height: 420)
        .background(Pixel.cream)
        .overlay(alignment: .bottom) {
            PokemonRunner(cursorX: cursorX)
                .padding(.horizontal, 2)
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let loc): cursorX = loc.x
            case .ended: cursorX = nil
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            tabButton(title: "TIMER", isActive: tab == .timer) { tab = .timer }
            tabButton(title: "LOG",   isActive: tab == .log)   { tab = .log }
        }
        .frame(height: 34)
        .background(Pixel.red)
        .overlay(Rectangle().frame(height: 3).foregroundColor(Pixel.border), alignment: .bottom)
    }

    private func tabButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Pixel.font(12))
                .foregroundColor(isActive ? Pixel.navy : .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isActive ? Pixel.yellow : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
