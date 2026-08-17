


# Pokémon Focus Timer

A pixel-art Pomodoro timer for macOS with animated Pokémon companions.

Lives in the menu bar. Set a duration, name your task, and hit start — Pikachu, Leafeon, and Sylveon wander around the popup and chase your cursor while a Pokéball rolls beneath the timer. Completed sessions are logged to disk.

https://github.com/user-attachments/assets/e9bd742a-20c7-4ac9-91e2-314f1bb424b4

## Features

- Menu-bar app with a pixel-art popup UI
- Preset durations (1m, 15m, 30m, 45m) or manual entry
- Press **Enter** in the task field to start the timer immediately
- **DONE** button logs the elapsed time to a JSON log and resets
- Session log persists in `~/Library/Application Support/FocusTimer/log.json`
- Animated Pokémon that hop, bob, and dash toward the cursor
- Rolling Pokéball animation while the timer is running

## Download

Grab the [latest build (v1.1)](https://github.com/hodangminh/pokemon-focus-timer/releases/latest) or browse all versions on the [Releases page](https://github.com/hodangminh/pokemon-focus-timer/releases).

The app is **ad-hoc signed** (not notarized), so macOS Gatekeeper will refuse
to open it on first launch. To bypass:

1. Unzip and drag `PokemonFocusTimer.app` into `/Applications`.
2. **Right-click** the app → **Open** → **Open** in the dialog.
   (Only needed the first time; after that it launches normally.)

Alternatively, remove the quarantine attribute from the Terminal:

```
xattr -dr com.apple.quarantine /Applications/PokemonFocusTimer.app
```

## Requirements

- macOS 13+
- Xcode 15+ (only if building from source)

## Build & run

Open `PokemonFocusTimer.xcodeproj` in Xcode and hit ⌘R. The app appears in the menu bar.

To archive a signed build:

1. Xcode → Product → Archive
2. Distribute → Copy App

## Tests

⌘U in Xcode, or:

```
xcodebuild test -project PokemonFocusTimer.xcodeproj -scheme PokemonFocusTimer -destination 'platform=macOS'
```

## Attribution

Pokémon sprites © Nintendo / Game Freak, sourced from
[PokeAPI/sprites](https://github.com/PokeAPI/sprites).

This is a personal, non-commercial fan project and is not affiliated with,
endorsed by, or sponsored by Nintendo, The Pokémon Company, or Game Freak.

## License

MIT — see [LICENSE](LICENSE).
