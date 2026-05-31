# Recallr

> **Your Mind, Engineered** — A personal link management app that helps you save, organize, and rediscover valuable content from the web.

---

## The Problem

You bookmark a link. Then forget it exists. Sound familiar?

Most people save dozens of interesting articles, tools, and resources every week — but retrieval is a mess. Browser bookmarks have no metadata, no search, no organization. Recallr fixes this by giving every saved link rich context: title, description, thumbnail, domain, tags, and read status — all searchable and filterable, stored entirely on your device.

---

## Features

- **Save any URL** — Paste a link and Recallr automatically fetches its title, description, thumbnail, and favicon via Open Graph metadata
- **Organize with Tags & Folders** — Create custom categories and tag links for structured recall
- **Powerful Search** — Full-text search across titles, descriptions, URLs, domains, and site names
- **Smart Filters** — Filter by favorites, read/unread status, tags, or folders; sort by newest, oldest, or last opened
- **Read Status Tracking** — Mark links as read to manage your reading queue
- **Favorites** — Star important links for quick access
- **100% Offline** — All data lives on your device; no account, no cloud, no tracking

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
| Typography | Space Grotesk + Google Fonts |

---

## Project Structure

```
lib/
├── main.dart                   # App entry point & theme setup
├── app_routes.dart             # Go Router navigation config
├── core/
│   ├── database/               # Isar DB singleton & providers
│   ├── features/view/          # App screens (Home, Search, Categories, Profile)
│   └── repositrories/          # Business logic & Riverpod providers
├── data/models/                # Isar collection models (Link, Tag, Folder)
├── theme/                      # Color system, typography, theme controller
└── common/                     # Shared widgets (link cards, filter chips, sheets)
```

---

## Data Models

**LinkModel** — stores a saved URL with full metadata
**TagModel** — user-defined tags with color and icon
**FolderModel** — categories/collections to group links

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

- **Riverpod** manages all state — no `setState`, no `BuildContext` abuse
- **Isar** provides reactive streams — UI auto-updates when data changes
- **Repository pattern** separates DB queries from UI logic
- **Go Router** handles type-safe navigation with nested routes

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

## License

[MIT](LICENSE)
