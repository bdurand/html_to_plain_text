# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed

- Data tables with an explicit `tbody`, `thead`, or `tfoot` no longer lose their pipe separators.
- Trailing spaces are no longer removed from inside `pre` tag content.
- Fixed quadratic slowdown when converting large documents.
- Multiline `href` values are rejected so `javascript:` URLs can no longer leak into the output.

### Changed

- `mailto:` and `tel:` link URLs are now included in the output when the link text differs from the address.
- Return an empty string instead of `nil` when the parsed document has no body.
- Line breaks are normalized and whitespace stripped on plain text input for consistency with HTML input.

## 1.0.5

### Changed

Only add pipes on tables if border attributes set to non-zero value.

## 1.0.4

### Changed

Small tweak to outputing link URLs when they don't make sense.

## 1.0.3

### Changed

- improve performance slightly by replacing runtime strings with constants
- testing on modern rubies (grosser)
- using gemspec in Gemfile (grosser)
- not shipping test files for smaller gem / faster installs / smaller cached gems (grosser)
- rake bump:patch -> increment version (grosser)
- rake release -> ship new version (grosser)

## 1.0.2

### Changed

- remove trailing whitespace on converted text.

## 1.0.1

### Changed

- better handling of non-html or nil text

## 1.0.0

### Added

- initial release
