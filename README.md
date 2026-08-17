# Pokémon Focus Timer

A pixel-art Pomodoro timer for macOS with animated Pokémon companions.

Lives in the menu bar. Set a duration, name your task, and hit start — Pikachu, Leafeon, and Sylveon wander around the popup and chase your cursor while a Pokéball rolls beneath the timer. Completed sessions are logged to disk.

## Features

- Menu-bar app with a pixel-art popup UI
- Preset durations (1m, 15m, 30m, 45m) or manual entry
- Press **Enter** in the task field to start the timer immediately
- **DONE** button logs the elapsed time to a JSON log and resets
- Session log persists in `~/Library/Application Support/FocusTimer/log.json`
- Animated Pokémon that hop, bob, and dash toward the cursor
- Rolling Pokéball animation while the timer is running

## Requirements

- macOS 13+
- Xcode 15+

## Build & run

Open `MacFocusTimer.xcodeproj` in Xcode and hit ⌘R. The app appears in the menu bar.

To archive a signed build:

1. Xcode → Product → Archive
2. Distribute → Copy App

## Tests

⌘U in Xcode, or:

```
xcodebuild test -project MacFocusTimer.xcodeproj -scheme MacFocusTimer -destination 'platform=macOS'
```

## Attribution

Pokémon sprites © Nintendo / Game Freak, sourced from
[PokeAPI/sprites](https://github.com/PokeAPI/sprites).

This is a personal, non-commercial fan project and is not affiliated with,
endorsed by, or sponsored by Nintendo, The Pokémon Company, or Game Freak.

## License

MIT — see [LICENSE](LICENSE).
