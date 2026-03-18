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

## Architecture

PortBar follows the **MVVM (Model-View-ViewModel)** pattern for clean separation of concerns and testability.

### High-Level Overview

```
┌─────────────────────────────────────────────────┐
│              macOS Menu Bar                     │
│  (User clicks icon → shows popover)             │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│           MenuBarView (SwiftUI)                 │
│  - Displays port list                           │
│  - Handles user interactions                    │
│  - Search/filter UI                             │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│          PortViewModel                          │
│  - Business logic                               │
│  - State management (@Published)                │
│  - Coordinates services                         │
└─────────┬──────────────────────┬────────────────┘
          │                      │
┌─────────▼────────┐   ┌────────▼─────────────┐
│  PortService     │   │  ProcessService      │
│  - Runs lsof     │   │  - Kills processes   │
│  - Parses output │   │  - Uses kill -9      │
└──────────────────┘   └──────────────────────┘
```

### Component Breakdown

#### 1. **Models** (`Models/Port.swift`)
Simple data structures representing domain objects.

```swift
struct Port: Identifiable {
    let id = UUID()
    let number: Int          // 3000
    let command: String      // "node"
    let pid: Int             // 1234
    let type: String         // "IPv4" or "IPv6"
}
```

**Purpose:** Immutable data transfer objects. No business logic.

---

#### 2. **Services Layer**

##### PortService (`Services/PortService.swift`)
Responsible for detecting active ports.

**Responsibilities:**
- Execute `lsof` command via `Process`
- Parse output into `Port` models
- Handle errors (command not found, permission denied)

**Key Method:**
```swift
func getActivePorts() -> [Port] {
    // 1. Run: lsof -iTCP -sTCP:LISTEN -n -P
    // 2. Parse each line
    // 3. Extract: command, PID, port number
    // 4. Return array of Port models
}
```

**Why separate?** Keeps system interaction logic isolated and testable.

##### ProcessService (`Services/ProcessService.swift`)
Responsible for killing processes.

**Responsibilities:**
- Execute `kill -9 <PID>` via `Process`
- Return success/failure
- Handle errors (permission denied, process not found)

**Key Method:**
```swift
func killProcess(pid: Int) -> Bool {
    // 1. Run: kill -9 <PID>
    // 2. Check termination status
    // 3. Return true if successful
}
```

**Why separate?** Killing processes is a distinct responsibility. Easier to test and mock.

---

#### 3. **ViewModel** (`ViewModels/PortViewModel.swift`)
The brain of the app. Coordinates between UI and services.

**Responsibilities:**
- Maintain app state (`@Published var ports: [Port]`)
- Fetch ports from `PortService`
- Kill processes via `ProcessService`
- Handle search/filter logic
- Refresh data

**Key Properties:**
```swift
@Published var ports: [Port] = []           // All detected ports
@Published var searchText: String = ""      // User's search query

var filteredPorts: [Port] {                 // Computed property
    // Filter ports by searchText
}
```

**Key Methods:**
```swift
func refresh()              // Fetch fresh port list
func kill(port: Port)       // Kill specific port's process
```

**Why MVVM?** 
- ViewModel is observable (`ObservableObject`)
- Views react to state changes automatically
- Easy to test without UI

---

#### 4. **Views** (SwiftUI)

##### MenuBarView (`Views/MenuBarView.swift`)
Main popover UI shown when clicking menu bar icon.

**Structure:**
```
┌─────────────────────────────┐
│  Header (Title + Refresh)   │ ← HStack
├─────────────────────────────┤
│  Search Bar                 │ ← TextField
├─────────────────────────────┤
│  Port List (Scrollable)     │ ← ScrollView + ForEach
│    - PortRowView            │
│    - PortRowView            │
│    - PortRowView            │
├─────────────────────────────┤
│  Footer (Settings + About)  │ ← HStack
└─────────────────────────────┘
```

**Observes:** `PortViewModel` for state changes

##### PortRowView (`Views/PortRowView.swift`)
Single row showing one port.

**Layout:**
```
[ 3000 ] [ node          ] [ PID: 1234 ] [ Kill ]
 Port #    Process name     Process ID     Button
```

**Callback:** Calls `onKill()` closure when Kill button pressed

---

### Data Flow

#### Startup Flow
```
1. App launches
2. MenuBarExtra created (menu bar icon appears)
3. User clicks icon
4. MenuBarView appears
5. onAppear() → viewModel.refresh()
6. PortViewModel → PortService.getActivePorts()
7. Ports displayed in UI
```

#### Refresh Flow
```
1. User clicks Refresh button (or CMD+R)
2. viewModel.refresh()
3. PortService runs lsof
4. Parses output into [Port] array
5. Updates @Published var ports
6. SwiftUI automatically re-renders UI
```

#### Kill Process Flow
```
1. User clicks Kill button
2. PortRowView calls onKill()
3. MenuBarView → viewModel.kill(port)
4. PortViewModel → ProcessService.killProcess(pid)
5. Process killed via kill -9
6. viewModel.refresh() to update list
7. Port disappears from UI
```

#### Search Flow
```
1. User types in search field
2. Updates viewModel.searchText (@Published)
3. filteredPorts computed property recalculates
4. UI shows filtered results (reactively)
```

---

### File Structure

```
PortBar/
├── PortBar.xcodeproj          # Xcode project
├── PortBar/
│   ├── PortBarApp.swift       # App entry point
│   │                          # Creates MenuBarExtra
│   │
│   ├── Models/
│   │   └── Port.swift         # Port data model
│   │
│   ├── ViewModels/
│   │   └── PortViewModel.swift # State & business logic
│   │                           # ObservableObject
│   │
│   ├── Views/
│   │   ├── MenuBarView.swift   # Main popover UI
│   │   └── PortRowView.swift   # Single port row
│   │
│   ├── Services/
│   │   ├── PortService.swift   # lsof wrapper
│   │   └── ProcessService.swift # kill wrapper
│   │
│   ├── Assets.xcassets/
│   │   └── MenuBarIcon.png     # Menu bar icon
│   │
│   └── Info.plist              # App configuration
│                               # LSUIElement = YES (menu bar only)
│
├── README.md                   # You are here
├── PLAN.md                     # Detailed build plan
└── LICENSE                     # MIT license
```

---

### Key Design Decisions

#### 1. **MVVM Pattern**
**Why?** Separates presentation logic from business logic. SwiftUI works naturally with MVVM through `@Published` and `ObservableObject`.

#### 2. **Service Layer**
**Why?** Isolates system calls (`lsof`, `kill`) from business logic. Makes testing easier and allows mocking.

#### 3. **SwiftUI for UI**
**Why?** Modern, declarative, reactive. Automatic UI updates when state changes. Less code than AppKit.

#### 4. **MenuBarExtra (not NSStatusItem)**
**Why?** SwiftUI-native menu bar integration. Cleaner than mixing AppKit and SwiftUI.

#### 5. **Synchronous Operations**
**Why?** `lsof` is fast (<100ms). No need for async/await complexity in v1.0. Can optimize later if needed.

#### 6. **No Database/Persistence**
**Why?** Port status is ephemeral. Always fetch fresh data. No historical tracking in v1.0.

---

### Performance Considerations

#### Port Detection
- `lsof` runs in ~50-100ms on typical Mac
- Only run on-demand (user clicks Refresh or opens menu)
- No auto-refresh in v1.0 (avoid unnecessary CPU usage)

#### UI Rendering
- SwiftUI handles list rendering efficiently
- Typical list: 5-20 ports (small dataset)
- Search filtering happens in-memory (instant)

#### Memory Usage
- Minimal: Just storing array of Port structs
- No caching, no images
- SwiftUI views are lightweight

---

### Security & Permissions

#### Why Accessibility Permissions?
macOS sandboxing restricts access to process information. To read `lsof` output and kill processes, PortBar needs:

1. **Accessibility API access** (to read process info)
2. **User approval** (macOS prompts on first run)

**What PortBar CANNOT do:**
- Access files/network without permission
- Run in background without user knowledge
- Modify system settings
- Access other apps' data

**What PortBar DOES:**
- Only reads public process info (`lsof`)
- Only kills processes user explicitly selects
- Runs only when menu bar item is clicked

---

### Testing Strategy

#### Unit Tests
```swift
// Test PortService parsing
func testLsofParsing() {
    let mockOutput = """
    COMMAND   PID   USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
    node      1234  randy  20u  IPv4  0x...      0t0  TCP *:3000 (LISTEN)
    """
    let ports = PortService().parseLsofOutput(mockOutput)
    XCTAssertEqual(ports.count, 1)
    XCTAssertEqual(ports[0].number, 3000)
    XCTAssertEqual(ports[0].command, "node")
}
```

#### Integration Tests
- Run app on clean Mac
- Start Node server on port 3000
- Verify PortBar detects it
- Kill via PortBar
- Verify process terminates

#### Manual Testing
- Test with multiple servers running
- Test search functionality
- Test empty state (no ports)
- Test permission denial handling

---

### Future Architecture Improvements

**Post v1.0 (if needed):**

1. **Async/Await**
   - Move `lsof` to background thread
   - Show loading indicator

2. **Caching**
   - Cache port list for 5 seconds
   - Reduce `lsof` calls

3. **Auto-refresh**
   - Timer-based refresh (every 5-10s)
   - Toggle in settings

4. **Notifications**
   - Detect new ports
   - Alert on common ports (3000, 8080)

5. **Persistence**
   - UserDefaults for settings
   - Port favorites
   - Kill history

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
