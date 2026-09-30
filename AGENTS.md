# Repository instructions

Project-specific code preferences and operating constraints.

## Dart, Riverpod, and state

- Prefer immutable, explicitly typed state and clear Dart 3 control flow. Use
  `Dto` only to distinguish transport models from internal models.
- Generate providers and notifiers from annotations. Do not suffix notifiers with
  `Controller`; prefer default generated provider names.
- Use `logic.dart` for a directory's sole logic file; use meaningful `xx_logic.dart`
  names when several are justified.
- Manage business/shared state consistently through Riverpod and service injection.
  Keep text, focus, animation, scrolling, and temporary expansion state in the
  owning UI scope. Choose provider retention for the required lifecycle.
- In Riverpod disposal, cancellation, and resume callbacks, do not synchronously
  access or mutate provider state.
- Scope account-dependent state, caches, and requests by account and content
  identity; discard stale responses after account or request changes. Preserve
  loading/content/empty/error, refresh, retry, and cancellation semantics.
- Keep types, error semantics, and resource ownership consistent across the
  Rust bridge and platform interfaces.

## Localization and generated code

- Use existing localization for user-facing text; maintain English, Simplified
  Chinese, Traditional Chinese, and Japanese. Format values by locale.
- Change source definitions and regenerate affected outputs with project-configured
  tools. Include required outputs; never hand-edit generated files or create
  unrelated generated churn. Regenerate the Rust bridge only for source contract
  changes. Code generation alone is not an application build.

## Project documentation

- UI/interaction tasks enter through `docs/UI_GLASS_IMPLEMENTATION.md`. Read relevant
  sections of `DESIGN_SYSTEM.md`, `PAGE_SPEC.md`, and `MOTION_SPEC.md` as directed.
  Visual rules live there; the execution guide owns validation flow and environment.
- `docs/IMPLEMENTATION_GUIDE.md` maps source responsibilities; `docs/DEVELOPMENT.md`
  describes tools and local dependencies.
- `docs/REGRESSION_PLAN.md` is the full-regression run sheet; its results go back into
  the execution guide's validation status.
- `docs/` and `.cargo/config.toml` are local excluded material; do not stage or commit
  them.

## Costly verification and local dependencies

- APK and Windows application builds require explicit authorization. Flutter run
  and test commands can invoke `hook/build.dart` to compile Rust native assets;
  assess that execution path before running them and obtain authorization when
  it entails costly native compilation.
- Windows desktop acceptance requiring app launches, focus changes, mouse or
  keyboard input needs explicit authorization for desktop interaction. Permission
  to run background checks alone does not authorize taking over the desktop.
  UI observations use the execution guide's size-based flow.
- Never track lock files, including force-added ignored files. Add appropriate
  ignore rules before staging when a lock file first appears.
- Keep committed `pixiv_rs` on its Git source. Local development uses the Git-source
  patch in `.cargo/config.toml` for the sibling checkout; preserve that override and
  never stage it. Inspect staged `rust/Cargo.toml` before every commit.
