# Recallr

> **Your Mind, Engineered** — A personal link management app that helps you save, organize, and rediscover valuable content from the web.

---

## The Problem

You bookmark a link. Then forget it exists. Sound familiar?

Most people save dozens of interesting articles, tools, and resources every week — but retrieval is a mess. Browser bookmarks have no metadata, no search, no organization. Recallr fixes this by giving every saved link rich context: title, description, thumbnail, domain, tags, and read status — all searchable and filterable, stored entirely on your device.

---

## Features

### Core
- **Save any URL** — Paste or share a link; Recallr automatically fetches title, description, thumbnail, and favicon via Open Graph metadata
- **Share-to-save** — Share any link from any app directly into Recallr via the system share sheet
- **Organize with Tags & Folders** — Create custom categories and tag links for structured recall
- **Powerful Search** — Full-text search across titles, descriptions, notes, URLs, and domains with snippet previews and bold match highlighting
- **Smart Filters** — Filter by favorites, read/unread status, tags, or folders; sort by newest, oldest, or last opened
- **Read Status & Favorites** — Mark links as read, star important ones; swipe right on any card to favorite instantly
- **Notes** — Attach personal notes to any saved link
- **100% Offline** — All data lives on your device; no account, no cloud, no tracking

### Discovery & Recall
- **Discover Mode** — "Remember This?" card surfaces a random unread link saved over 7 days ago
- **Reading Streak** — Tracks consecutive days you've opened links, shown in your profile
- **Spaced Repetition Notifications** — Optional daily reminder to revisit saved content

### Organization
- **Collections/Folders** — Group links into named folders; assign during save or edit later
- **Platform Cards** — Browse links by source platform (YouTube, Instagram, X/Twitter, Reddit, GitHub, Medium, LinkedIn, Facebook) with Font Awesome brand icons and platform colors
- **Add Category** — Create custom categories with a name, color (8 choices), and icon (12 choices)
- **Edit Links** — Update title, notes, tags, and folder at any time via the options sheet

### Data & Health
- **Export** — Export your library as JSON or CSV and share via the system share sheet
- **Link Health Checker** — Checks all saved links for broken URLs; broken links show a warning badge on their card
- **Reading Time** — Estimated read time shown on every link card (200 wpm)

### UI & Animations
- **Scroll-driven hero** — "Your Mind, Engineered." collapses and sticks below the app badge as you scroll; the cycling word changes every 2.5s (Engineered → Organized → Curated → Amplified → Supercharged) with a slot-machine slide animation and brand gradient
- **Insights chart** — 7-day reading activity bar chart in Profile with animated bars; today highlighted with brand gradient
- **Staggered card animations** — Link cards fade and slide up on entry; scale on press
- **Animated bottom nav** — Custom painter with animated arch that slides to the active tab

---

## Screenshots

> _Coming soon_

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK 3.10.4+) |
| State Management | Riverpod 2.5 |
| Local Database | Isar 3.1 (embedded NoSQL) |
| Navigation | Go Router 17 |
| Metadata Extraction | metadata_fetch |
| Typography | Space Grotesk |
| Icons | Material Icons + Font Awesome (brand icons) |
| Notifications | flutter_local_notifications |
| Export | share_plus |

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, theme setup, share intent init
├── app_routes.dart              # Go Router navigation config
├── core/
│   ├── database/                # Isar DB singleton & providers
│   ├── features/view/           # Screens: Home, Search, Categories, Profile, Collections
│   ├── repositrories/           # Business logic & Riverpod providers
│   └── services/                # Export, notifications, link health, share intent
├── data/models/                 # Isar models (Link, Tag, Folder) + SearchResult value object
├── theme/                       # Color system, typography, theme controller
├── common/                      # Shared widgets (link cards, filter chips, option/edit sheets)
└── navigation/                  # Bottom nav bar with animated arch painter
```

---

## Data Models

**LinkModel** — stores a saved URL with full metadata (title, description, thumbnail, domain, notes, read/favorite flags, timestamps)  
**TagModel** — user-defined tags with color and icon  
**FolderModel** — collections to group links  
**SearchResult** — value object wrapping a `LinkModel` with matched field and snippet for search UI

Relationships are managed via Isar's `IsarLinks` (many-to-many tags, one-to-many folders).

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.10.4`
- Dart SDK `>=3.0.0`

### Run Locally

```bash
# Clone the repo
git clone https://github.com/your-username/recallr.git
cd recallr

# Install dependencies
flutter pub get

# Generate Isar schema files
dart run build_runner build

# Run the app
flutter run
```

---

## Architecture

Recallr follows a **feature-first, local-first** architecture:

- **Riverpod** manages all state — no `setState` in business logic, no `BuildContext` abuse
- **Isar** provides reactive streams — UI auto-updates when data changes
- **Repository pattern** separates DB queries from UI logic
- **Go Router** handles type-safe navigation with nested routes
- **Share intent** handled in `MainActivity.kt` (Android), surfaced via `StreamController` in `ShareIntentService`

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

## License

[MIT](LICENSE)
