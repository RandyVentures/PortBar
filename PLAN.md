# Port Manager - Build Plan

**Target:** Menu bar app for macOS (like RepoBar)  
**Timeline:** 2 weeks to working release  
**Goal:** Ship for yourself, others using it is a bonus  
**Inspiration:** RepoBar by steipete

---

## Project Overview

### Name Ideas
- **PortBar** (follows RepoBar naming)
- **PortPal**
- **PortWatch**
- **Harbormaster**

**Recommendation:** **PortBar** (simple, clear, follows RepoBar pattern)

### Tagline
"Stop typing `lsof` commands. See and kill ports from your menu bar."

### Core Problem You're Solving
- Random ports running apps, lose track of what's running
- "Port already in use" errors = frustrating
- Current solution: `lsof -ti:3000 | xargs kill -9` (tedious to remember)

---

## MVP Features (v1.0)

### Must Have
1. **Menu bar icon** showing active port count
2. **Click to see list** of all listening ports
3. **Show for each port:**
   - Port number (e.g., 3000, 8080)
   - Process name (e.g., node, rails, python)
   - PID (process ID)
4. **Kill button** for each process
5. **Refresh button** to update list
6. **Search/filter** ports

### Nice to Have (v1.1+)
- Auto-refresh every 5-10 seconds
- Common ports highlighted (3000, 8080, 5432, etc.)
- Notification when common dev ports start
- Quick actions: "Kill all Node processes"
- History of killed processes

### Won't Have (v1.0)
- Network traffic monitoring
- Remote server monitoring
- Firewall features
- Analytics/usage tracking

---

## Technical Stack

### Language & Framework
- **Swift** (native macOS)
- **SwiftUI** for UI (modern, maintainable)
- **AppKit** for menu bar integration

### How It Works

**Backend (Port Detection):**
```bash
# List all listening TCP ports
lsof -iTCP -sTCP:LISTEN -n -P

# Output example:
# COMMAND   PID USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
# node      1234 randy  20u  IPv4  0x...      0t0  TCP *:3000 (LISTEN)
# rails     5678 randy  21u  IPv6  0x...      0t0  TCP *:8080 (LISTEN)
```

**Parsing:**
- Run `lsof` command via `Process`
- Parse output into `Port` models
- Display in menu bar popover

**Killing Process:**
```bash
kill -9 <PID>
```

### Data Model

```swift
struct Port: Identifiable {
    let id = UUID()
    let number: Int          // 3000
    let command: String      // "node"
    let pid: Int            // 1234
    let type: String        // "IPv4" or "IPv6"
}
```

### Menu Bar Structure

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
├─────────────────────────────┤
│  Settings       About       │
└─────────────────────────────┘
```

---

## Project Structure

```
PortBar/
├── PortBar.xcodeproj
├── PortBar/
│   ├── PortBarApp.swift          # Main app entry
│   ├── Models/
│   │   └── Port.swift            # Port data model
│   ├── ViewModels/
│   │   └── PortViewModel.swift   # Business logic
│   ├── Views/
│   │   ├── MenuBarView.swift     # Menu bar UI
│   │   └── PortRowView.swift     # Single port row
│   ├── Services/
│   │   ├── PortService.swift     # lsof wrapper
│   │   └── ProcessService.swift  # kill wrapper
│   ├── Assets.xcassets/
│   │   └── MenuBarIcon.png       # Icon
│   └── Info.plist
├── README.md
├── LICENSE (MIT)
└── .gitignore
```

---

## Week-by-Week Plan

### Week 1: Core Functionality

**Day 1-2: Project Setup**
- [ ] Create Xcode project (macOS app, SwiftUI)
- [ ] Set up menu bar app (LSUIElement = YES in Info.plist)
- [ ] Create basic app icon
- [ ] Git repo setup

**Day 3-4: Port Detection**
- [ ] Implement `PortService.swift` (lsof wrapper)
- [ ] Parse lsof output into Port models
- [ ] Test with multiple running servers
- [ ] Handle edge cases (no ports, parsing errors)

**Day 5-7: UI & Kill Functionality**
- [ ] Create menu bar popover UI
- [ ] Display list of ports
- [ ] Implement kill button functionality
- [ ] Add refresh button
- [ ] Test killing processes

### Week 2: Polish & Ship

**Day 8-9: Features & UX**
- [ ] Add search/filter
- [ ] Highlight common ports (3000, 8080, etc.)
- [ ] Empty state ("No ports in use")
- [ ] Error handling UI
- [ ] Keyboard shortcuts (CMD+R to refresh)

**Day 10-11: Polish**
- [ ] Icon design (menu bar + app)
- [ ] App name finalization
- [ ] README with screenshots
- [ ] Testing on clean Mac

**Day 12-14: Release**
- [ ] GitHub release (v1.0.0)
- [ ] Create website/GitHub Pages (optional)
- [ ] Homebrew formula (optional)
- [ ] Post on Reddit /r/macapps
- [ ] Tweet about it

---

## Implementation Details

### 1. Menu Bar Setup

**PortBarApp.swift:**
```swift
import SwiftUI

@main
struct PortBarApp: App {
    @StateObject private var viewModel = PortViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Label("\(viewModel.ports.count)", systemImage: "network")
        }
    }
}
```

### 2. Port Service

**PortService.swift:**
```swift
import Foundation

class PortService {
    func getActivePorts() -> [Port] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return []
            }
            
            return parseLsofOutput(output)
        } catch {
            print("Error running lsof: \(error)")
            return []
        }
    }
    
    private func parseLsofOutput(_ output: String) -> [Port] {
        let lines = output.components(separatedBy: "\n")
        var ports: [Port] = []
        
        for line in lines.dropFirst() { // Skip header
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            guard components.count >= 9 else { continue }
            
            let command = String(components[0])
            guard let pid = Int(components[1]) else { continue }
            let type = String(components[4])
            
            // Parse port from "TCP *:3000 (LISTEN)"
            let addressPart = String(components[8])
            if let portString = addressPart.split(separator: ":").last?.split(separator: " ").first,
               let portNumber = Int(portString) {
                ports.append(Port(number: portNumber, command: command, pid: pid, type: type))
            }
        }
        
        return ports
    }
}
```

### 3. Process Service

**ProcessService.swift:**
```swift
import Foundation

class ProcessService {
    func killProcess(pid: Int) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/kill")
        task.arguments = ["-9", "\(pid)"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error killing process: \(error)")
            return false
        }
    }
}
```

### 4. View Model

**PortViewModel.swift:**
```swift
import Foundation

@MainActor
class PortViewModel: ObservableObject {
    @Published var ports: [Port] = []
    @Published var searchText: String = ""
    
    private let portService = PortService()
    private let processService = ProcessService()
    
    var filteredPorts: [Port] {
        if searchText.isEmpty {
            return ports
        }
        return ports.filter { port in
            "\(port.number)".contains(searchText) ||
            port.command.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func refresh() {
        ports = portService.getActivePorts()
    }
    
    func kill(port: Port) {
        if processService.killProcess(pid: port.pid) {
            refresh()
        }
    }
}
```

### 5. Menu Bar View

**MenuBarView.swift:**
```swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: PortViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("PortBar")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    viewModel.refresh()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding()
            
            Divider()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search ports...", text: $viewModel.searchText)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Port list
            if viewModel.filteredPorts.isEmpty {
                Text("No ports in use")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.filteredPorts) { port in
                            PortRowView(port: port, onKill: {
                                viewModel.kill(port: port)
                            })
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Settings") {
                    // TODO: Settings
                }
                Spacer()
                Button("About") {
                    // TODO: About
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 350)
        .onAppear {
            viewModel.refresh()
        }
    }
}
```

**PortRowView.swift:**
```swift
import SwiftUI

struct PortRowView: View {
    let port: Port
    let onKill: () -> Void
    
    var body: some View {
        HStack {
            Text("\(port.number)")
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .leading)
            
            Text(port.command)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("PID: \(port.pid)")
                .foregroundColor(.secondary)
                .font(.caption)
            
            Button("Kill") {
                onKill()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

---

## Testing Checklist

### Manual Testing

**Before Release:**
- [ ] Start Node server on port 3000, verify it shows
- [ ] Kill process via app, verify it disappears
- [ ] Start multiple servers, verify all show
- [ ] Search for port numbers, verify filtering works
- [ ] Search for process names, verify filtering works
- [ ] Refresh while servers running, verify updates
- [ ] Test with no ports active, verify empty state
- [ ] Test keyboard shortcut (CMD+R)
- [ ] Test on clean Mac (no dev tools)

**Edge Cases:**
- [ ] Port with no process name
- [ ] Multiple processes on same port
- [ ] Permission denied to kill process
- [ ] lsof not found (unlikely but test)

---

## Distribution

### GitHub Release

**Files to include:**
1. `PortBar.app.zip` (zipped macOS app)
2. `README.md` (with screenshots)
3. `LICENSE` (MIT)
4. Release notes

**README.md structure:**
```markdown
# PortBar

Stop typing `lsof` commands. See and kill ports from your menu bar.

## Features
- See all active ports in menu bar
- Kill processes with one click
- Search and filter ports
- Lightweight and fast

## Installation
1. Download `PortBar.app.zip`
2. Unzip and drag to Applications
3. Open PortBar
4. Grant permissions when prompted

## Screenshots
[Add screenshots]

## Requirements
- macOS 12.0 or later

## License
MIT
```

### Optional: Homebrew Cask

**Later, if people want it:**
```ruby
cask "portbar" do
  version "1.0.0"
  sha256 "..."
  
  url "https://github.com/RandyVentures/PortBar/releases/download/v#{version}/PortBar.app.zip"
  name "PortBar"
  desc "Menu bar app to manage ports"
  homepage "https://github.com/RandyVentures/PortBar"
  
  app "PortBar.app"
end
```

---

## Marketing (Optional)

### If you want to share it:

**Day 1: Reddit**
- Post on /r/macapps: "I built a free menu bar app to kill ports (no more lsof commands)"
- Include screenshot, GitHub link
- Post on /r/webdev: "Tired of 'port already in use'? I made a free macOS app"

**Day 2: Twitter/X**
- Tweet with screenshot + GitHub link
- Tag relevant accounts (@macappstech, etc.)

**Day 3: Hacker News**
- Show HN: "PortBar – Menu bar app to manage ports on macOS"
- Post on weekday morning (best engagement)

**Optional:**
- ProductHunt (if you want more visibility)
- Dev.to blog post about building it
- YouTube demo video

---

## Success Metrics

### Personal Success (Primary Goal)
- ✅ You use it daily
- ✅ Saves you 30+ seconds every time you hit "port in use"
- ✅ Shipped in 2 weeks

### Bonus Success (Others Using It)
- 🎯 50+ GitHub stars in first month
- 🎯 100+ downloads in first month
- 🎯 5+ people saying "this is useful" on Reddit/Twitter

### Dream Success (Unlikely but Cool)
- 🚀 500+ stars (like kill-port CLI)
- 🚀 Featured on MacApps subreddit
- 🚀 Hacker News front page

---

## Known Issues to Handle

### Permissions
- macOS will prompt for accessibility permissions
- Document this in README
- Show friendly error if permissions denied

### Security
- Killing processes requires user permission
- App won't work in sandboxed mode
- This is fine for developer tool

### Performance
- lsof can be slow with many processes
- Cache results, only refresh on demand
- Auto-refresh optional (off by default)

---

## Future Ideas (Post v1.0)

**If people actually use it:**
- [ ] Auto-refresh toggle
- [ ] Notifications for port conflicts
- [ ] Quick kill "all node processes"
- [ ] Port favorites (always monitor 3000, 8080)
- [ ] History of killed processes
- [ ] Export port list to CSV
- [ ] Dark mode support (if not automatic)

**Don't build these until v1.0 ships and people ask for them.**

---

## Timeline Summary

| Week | Focus | Deliverable |
|------|-------|-------------|
| **Week 1** | Core functionality | Working port detection + kill |
| **Week 2** | Polish + ship | GitHub release, Reddit post |

**End goal:** Working app you use daily, GitHub repo with 50+ stars if you're lucky.

---

## Next Steps

1. **Day 1 (Today):** Create Xcode project, set up Git repo
2. **Day 2:** Implement PortService (lsof wrapper)
3. **Day 3:** Build UI
4. **Day 4:** Test and polish
5. **Day 5:** Ship to GitHub

**Start now?** Want me to help scaffold the Xcode project or write the initial Swift code?
