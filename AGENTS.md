# Repository instructions

## frost_ui

- frost_ui and frost_window are read-only from this repository. Local
  development uses a sibling checkout at `../frost_ui`, linked through
  `pubspec_overrides.yaml`.
- Follow `../frost_ui/docs/APP_WORKFLOW.md` for pacing, tests, running the app,
  and screenshots. Request Frost changes as described in
  `../frost_ui/docs/requests/README.md`.
- Widgets the app paints or lays out itself go in `lib/ui/custom/` and start
  with `// app-owned: <feature>`. Other exceptions need the owner's approval and
  are marked `// frost-escape: <request ID>`.

## Project specifics

- Maintain English, Simplified Chinese, Traditional Chinese, and Japanese in
  `lib/i18n/`. Write documentation and comments in English.
- The automation entry point is `tool/automation_entry.dart`: sample data from
  `tool/sample_main.dart` plus driver hooks, for debug builds only. Add missing
  hooks there rather than in `lib/main.dart`.
- Regenerate the Rust bridge only for source contract changes.
- Keep committed `pixiv_rs` on its Git source. Local development patches it to
  the sibling checkout in `.cargo/config.toml`; inspect staged `rust/Cargo.toml`
  before every commit.

## Local material

- `docs/FUNCTION_INVENTORY.md` lists pages, data, operations, states,
  persistence, and the app profile.
- `docs/IMPLEMENTATION_GUIDE.md` maps source responsibilities;
  `docs/DEVELOPMENT.md` describes tools and local dependencies;
  `docs/PIXIV_SEARCH_API.md` records the verified Pixiv search API contract.
- `docs/`, `design/`, `.cargo/config.toml`, and `pubspec_overrides.yaml` are
  local and are never staged.
