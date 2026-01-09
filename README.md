# Abbey

A beautiful writing application for Linux, built with GTK4 and Rust.

![Abbey Screenshot](docs/screenshot.png)

## Features

### 🌊 Flow Mode
Enter a zen-like writing state with timed sessions (5, 10, 15, or 20 minutes). Flow mode encourages continuous writing without distraction. All your flows are saved into a single journal that you can review anytime.

- **Timed Sessions**: Choose your duration and write until the timer ends
- **Distraction-free**: Full-screen zen mode for focused writing
- **Flow Journal**: All sessions saved in a read-only, formatted document
- **Reuse Content**: Highlight any text from your flows to use in compositions

### ✍️ Composition Mode
Create essays, short stories, articles, and more with a clean, focused editor.

- **Auto-titled**: Documents start with timestamp, rename when ready
- **Notes Sidebar**: Attach research notes and ideas to each document
- **Archive**: Keep old work without clutter
- **Publish**: Post directly to your microblog (Micro.blog, etc.)

### 📚 Projects
Organize your compositions into books and collections.

- **Collect Works**: Add essays and stories to a project
- **Reorder**: Arrange pieces in your preferred order
- **Export**: Generate a single markdown file of your entire project

### 🎨 Beautiful Themes
Four carefully designed themes for comfortable writing:

- **System Light**: Clean, bright, modern
- **System Dark**: Easy on the eyes for night writing
- **Newspaper**: Classic editorial aesthetic with serif typography
- **Parchment**: Warm, aged paper feel for a bookish experience

## Installation

### Dependencies

```bash
# Fedora
sudo dnf install gtk4-devel libadwaita-devel gtksourceview5-devel graphene-devel

# Ubuntu/Debian
sudo apt install libgtk-4-dev libadwaita-1-dev libgtksourceview-5-dev libgraphene-1.0-dev

# Arch Linux
sudo pacman -S gtk4 libadwaita gtksourceview5 graphene

# openSUSE
sudo zypper install gtk4-devel libadwaita-devel gtksourceview5-devel graphene-devel
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourname/abbey.git
cd abbey

# Build in release mode
cargo build --release

# Run
./target/release/abbey
```

### Install Desktop Integration

To make Abbey appear in your application menu with proper icons on all Linux desktop environments:

```bash
# Install icons and desktop file (user-local)
./install-icons.sh

# Or install system-wide (requires root)
sudo ./install-icons.sh
```

This installs:
- Icons at all standard sizes (16x16 to 512x512) in the hicolor theme
- Desktop file for application menu integration
- Updates icon caches for immediate visibility

### Install Fonts (Recommended)

Abbey looks best with these fonts installed:

- **Crimson Pro** - Beautiful serif for body text
- **Inter** - Clean sans-serif for UI
- **JetBrains Mono** - Monospace for code and timers

```bash
# Fedora
sudo dnf install google-noto-serif-fonts inter-fonts jetbrains-mono-fonts

# Or download from Google Fonts:
# https://fonts.google.com/specimen/Crimson+Pro
# https://fonts.google.com/specimen/Inter
# https://www.jetbrains.com/mono/
```

## Usage

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Composition | `Ctrl+N` |
| Save | `Ctrl+S` |
| Enter Flow Mode | `Ctrl+Shift+F` |
| Quit | `Ctrl+Q` |

### Microblog Publishing

Abbey supports publishing to Micropub-compatible blogs:

1. Open a composition
2. Click the menu → "Publish to Microblog"
3. Enter your endpoint URL and API token
4. Click Publish

Works with:
- Micro.blog
- WordPress with Micropub plugin
- Any Micropub-compatible endpoint

## Data Storage

Abbey stores all data in `~/.local/share/abbey/`:

```
~/.local/share/abbey/
├── compositions.json    # Your compositions
├── flows.json           # Flow session history
├── projects.json        # Project collections
└── settings.json        # App preferences
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

GPL-3.0 - see [LICENSE](LICENSE) for details.

---

*Abbey - Write without distraction. Create without limits.*
