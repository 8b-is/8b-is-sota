# Changelog

All notable changes to SOTA.app are documented here.
This project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

### Fixed
- Apply per-capability model overrides to the settings board. New preferences
  default to Auto; saved selections are preserved. Unavailable engines or choices
  excluded by the on-device/latency policy fall back to automatic scoring.

## [0.1.1] — 2026-10-09

### Added
- `SOTAUI` SwiftUI target: `OnboardingView` (first-install flow mirroring
  https://setup.vaked.dev) and `SettingsView` (routing policy, the live board,
  per-capability model overrides, integrations, sync, about).
- App icon asset catalog (`AppIcon.appiconset`) for iOS + macOS.
- Setup-guide links in the README.

## [0.1.0] — 2026-10-09

### Added
- Initial release of SOTA.app.
- Offline-first core (no networking APIs; enforced in CI).
- Tests (`swift test`) and the offline-first gate (`scripts/check-offline.sh`).
- Repository furniture: README, SECURITY, PRIVACY, TERMS, CONTRIBUTING,
  CODE_OF_CONDUCT, issue/PR templates, CI.
