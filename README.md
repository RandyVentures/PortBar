# PortBar

> Stop typing `lsof` commands. See and kill ports from your menu bar.

![PortBar Icon](assets/icon-placeholder.png)
*macOS menu bar app for managing active ports*

---

## The Problem

Every developer has been here:

```bash
$ npm start
Error: Port 3000 is already in use
```

Then you have to:
1. Remember the `lsof` command
2. Find the process ID
3. Kill it manually
4. Try again

**There's a better way.**

---

## PortBar Solution

Click your menu bar → see all active ports → kill with one click.

**Features:**
- 🔍 **See all active ports** at a glance
- ⚡ **Kill processes** with one click
- 🔎 **Search and filter** by port or process name
- 🎯 **Lightweight** - menu bar only, no bloat
- 🆓 **Free and open source**

---

## Status

**🚧 In Development**

PortBar is currently being built. Expected release: Early April 2026.

**Follow development:**
- Star this repo to get notified when v1.0 ships
- Check [PLAN.md](PLAN.md) for build progress
- Issues and PRs welcome!

---

## How It Works

PortBar wraps the `lsof` command in a clean, native macOS menu bar interface:

```
┌─────────────────────────────┐
│  PortBar          [Refresh] │
├─────────────────────────────┤
│  Search: [________]          │
├─────────────────────────────┤
│  3000  │ node      │ [Kill] │
│  8080  │ rails     │ [Kill] │
│  5432  │ postgres  │ [Kill] │
│  3306  │ mysql     │ [Kill] │
└─────────────────────────────┘
```

**Under the hood:**
- Detects ports: `lsof -iTCP -sTCP:LISTEN -n -P`
- Shows process name, PID, port number
- Kills process: `kill -9 <PID>`

---

## Planned Features

### v1.0 (MVP)
- [x] Menu bar integration
- [x] List active ports
- [x] Show process name and PID
- [x] Kill process button
- [x] Search/filter ports
- [ ] App icon
- [ ] First release

### v1.1+ (Future)
- [ ] Auto-refresh toggle
- [ ] Highlight common dev ports (3000, 8080, 5432)
- [ ] Notifications for port conflicts
- [ ] Quick actions: "Kill all Node processes"
- [ ] Port favorites
- [ ] History of killed processes

---

## Installation

**Coming soon!**

When v1.0 ships, you'll be able to:

### Direct Download
1. Download `PortBar.app.zip` from [Releases](https://github.com/RandyVentures/PortBar/releases)
2. Unzip and drag to Applications folder
3. Open PortBar
4. Grant permissions when prompted

### Homebrew (planned)
```bash
brew install --cask portbar
```

---

## Requirements

- macOS 12.0 or later
- Accessibility permissions (to read process information)

---

## Why PortBar?

**Existing solutions:**
- `lsof` + `kill` commands: Tedious to remember and type
- Activity Monitor: Clunky, hard to find process by port
- [kill-port](https://github.com/tiaanduplessis/kill-port) (559 stars): CLI only, requires Node.js
- Full network monitors: Overkill and expensive

**PortBar difference:**
- Native macOS menu bar app
- Simple, focused on one problem
- No installation hassle (just download and run)
- Free and open source

---

## Inspiration

PortBar follows the pattern of simple, focused developer menu bar tools like:
- [RepoBar](https://github.com/steipete/RepoBar) (1,132 stars) - GitHub repo status
- [Maccy](https://github.com/p0deje/Maccy) (14k+ stars) - Clipboard manager
- [Rectangle](https://github.com/rxhanson/Rectangle) - Window management

**Philosophy:** Do one thing well. No bloat. No subscription. Just solve the problem.

---

## Development

**Tech Stack:**
- Swift
- SwiftUI
- AppKit (menu bar integration)

**Want to contribute?**
1. Check [Issues](https://github.com/RandyVentures/PortBar/issues)
2. See [PLAN.md](PLAN.md) for development roadmap
3. Fork and submit PRs!

**Build from source:**
```bash
git clone https://github.com/RandyVentures/PortBar.git
cd PortBar
open PortBar.xcodeproj
```

---

## Roadmap

| Milestone | Target | Status |
|-----------|--------|--------|
| Project setup | Week 1 | 🚧 In Progress |
| Core functionality | Week 1 | 📅 Planned |
| UI polish | Week 2 | 📅 Planned |
| v1.0 Release | Early April 2026 | 📅 Planned |
| Homebrew formula | Post-launch | 📅 Future |

---

## FAQ

**Q: Is this free?**  
A: Yes, completely free and open source (MIT license).

**Q: Why do you need accessibility permissions?**  
A: To read process information and kill processes. This is standard for system utilities.

**Q: Will this work on my M1/M2/M3 Mac?**  
A: Yes! PortBar is native Swift and works on all modern Macs.

**Q: What about Windows/Linux?**  
A: PortBar is macOS-only for now. The concept could work on other platforms, but each would need a native implementation.

**Q: Can I use this in my company?**  
A: Absolutely! MIT license means you can use it anywhere.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

Free to use, modify, and distribute. No warranty.

---

## Contact

**Built by:** [Randy Torres](https://github.com/RandyVentures)

**Issues?** Open an [issue](https://github.com/RandyVentures/PortBar/issues)

**Want updates?** Star the repo and watch for releases!

---

**PortBar** - Because life's too short to type `lsof -ti:3000 | xargs kill -9` 🚀
