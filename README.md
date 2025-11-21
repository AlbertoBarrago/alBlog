# Alblog

A modern blog platform built with Phoenix LiveView, featuring real-time collaboration, markdown support, and role-based access control.

## Tech Stack

- **Framework**: Phoenix 1.8.1 with LiveView 1.1.0
- **Language**: Elixir 1.18
- **Database**: PostgreSQL with Ecto 3.13
- **Authentication**: bcrypt_elixir with custom user auth
- **Styling**: TailwindCSS + Heroicons
- **Email**: Swoosh with Gmail SMTP
- **Markdown**: Earmark parser
- **Server**: Bandit 1.5

## Architecture

### Core Features

- **Article Management**: CRUD operations with markdown rendering and slug generation
- **Real-time Presence**: Phoenix Presence tracking for concurrent article viewers
- **Authentication System**: User registration, login, password recovery, and email confirmation
- **Role-based Access**: Public article viewing with admin-only editing capabilities
- **LiveView Components**: Reactive UI with server-side rendering

### Key Modules

```
lib/alblog/
├── accounts/          # User authentication and management
├── blog/              # Article schema and business logic
└── repo.ex            # Database interface

lib/alblog_web/
├── live/              # LiveView modules (articles, auth)
├── controllers/       # Traditional controllers
└── components/        # Reusable UI components
```

## Development Setup

```bash
# Install dependencies and setup database
mix setup

# Start development server
mix phx.server

# Or with interactive shell
iex -S mix phx.server
```

Access the application at `http://localhost:4000`

## Deployment

Currently deployed on Gigalixir with automated CI/CD via GitHub Actions.

For production deployment: [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
