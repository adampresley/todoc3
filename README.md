# todoc3

`todoc3` is a small terminal todo application written in [C3](https://c3-lang.org/).
It was built as a learning project to practice C3 syntax, project structure,
foreign function calls into C, simple data modeling, tests, and using SQLite
from a C3 program.

The app stores todo items in a local SQLite database and presents a simple
interactive menu for:

- listing incomplete todo items
- listing completed todo items
- creating a todo item
- marking a todo item complete

This is intentionally a small, practical project rather than a production todo
system.

## Quickstart with Docker Compose

From the repository root:

```sh
docker compose run todoc3
```

Docker Compose builds the app image and starts the interactive todo program. The
container runs the compiled `todoc3` binary with `/data` as its working
directory, so the SQLite database is stored at `/data/todo.db`.

The compose file defines a named volume, `todoc3-data`, so your todo database
persists between runs. If you want Docker to remove the one-off container after
the app exits, use:

```sh
docker compose run --rm todoc3
```

## Running and Building with c3c

This project is configured with `project.json` and targets C3 compiler `0.8.1`.
The project includes C source files under `csource/`, and `project.json` tells
`c3c` to compile those files along with the C3 sources.

Run the app directly:

```sh
c3c run 
```

Build the executable:

```sh
c3c build
```

After building, run the compiled binary:

```sh
./build/todoc3
```

Run the tests:

```sh
c3c test
```

When run directly from your host machine, the app creates `todo.db` in the
current working directory.

## Project Layout

- `src/main.c3` - interactive terminal application and menu flow
- `src/pkg/todo/` - todo item model and repository functions
- `src/pkg/sqlite/` - small C3 wrapper around the SQLite C API
- `src/pkg/parsing/` - date/time helper functions
- `test/` - C3 tests
- `csource/` - vendored SQLite amalgamation source and header
- `Dockerfile` - multi-stage image build using `c3c`
- `compose.yml` - quick interactive Docker Compose runner with persistent data

## SQLite Source and License

This repository includes SQLite source code directly:

- `csource/sqlite3.c`
- `csource/sqlite3.h`

The included amalgamation identifies itself as SQLite `3.53.3`. SQLite is not
licensed under this repository's MIT license; SQLite's source header states that
the author disclaims copyright to the SQLite source code. Keep that distinction
in mind if you copy or redistribute this project.

## License

The original code in this repository is licensed under the MIT license. See
`LICENSE`.
