# Database Commands Cheatsheet for Alblog

This document provides a quick reference for interacting with your application's database using the terminal.

## 1. Interactive Elixir Shell (IEx)

The most powerful way to interact with your database is through the Elixir interactive shell, which gives you access to your application's code and Ecto queries.

### Start the Shell
```bash
iex -S mix
```

### Common Aliases
Once inside `iex`, run these aliases to save typing:
```elixir
alias Alblog.Repo
alias Alblog.Accounts.User
alias Alblog.Blog.Article
import Ecto.Query
```

### Common Queries

**Users**
```elixir
# List all users
Repo.all(User)

# Get user by ID
Repo.get(User, 1)

# Get user by email
Repo.get_by(User, email: "user@example.com")
```

**Articles**
```elixir
# List all articles
Repo.all(Article)

# Get article by ID
Repo.get(Article, 1)

# Create a new article (example)
%Article{title: "My Title", body: "Content", user_id: 1} |> Repo.insert()
```

**Advanced Queries**
```elixir
# Count users
Repo.aggregate(User, :count)

# Find articles by a specific user
query = from a in Article, where: a.user_id == 1
Repo.all(query)
```

## 2. Database Management (Mix Tasks)

Run these commands directly in your terminal (not in `iex`).

```bash
# Create the database
mix ecto.create

# Drop the database (WARNING: Deletes all data)
mix ecto.drop

# Run pending migrations
mix ecto.migrate

# Rollback the last migration
mix ecto.rollback

# Reset the database (Drop, Create, Migrate, Seed)
mix ecto.reset
```

## 3. One-off Commands from Terminal (mix run)

If you want to run a specific `Repo` command directly from your terminal without entering the interactive shell, you can use `mix run -e`.

```bash
# List all users
mix run -e "alias Alblog.Repo; alias Alblog.Accounts.User; IO.inspect(Repo.all(User))"

# Count all articles
mix run -e "alias Alblog.Repo; alias Alblog.Blog.Article; IO.inspect(Repo.aggregate(Article, :count))"
```

## 4. PostgreSQL Command Line (psql)

If you have the PostgreSQL client installed, you can connect directly to the SQL database.

```bash
# Connect to the development database
psql alblog_dev
```

### Common SQL Commands
- `\dt` - List all tables
- `\d users` - Describe the `users` table
- `SELECT * FROM users;` - Select all rows from users
- `\q` - Quit psql
