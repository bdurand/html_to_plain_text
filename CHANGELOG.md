# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.1.0

### Added

- Markdown output can now be generated with the `markdown` method or by calling `plain_text` with the new `markdown: true` option. Headings, bold, italic, strikethrough, inline code, links, images, blockquotes, code blocks, lists, horizontal rules, and data tables are converted to Markdown syntax.
- New `all_tables` option to format all tables as data tables regardless of their markup.
- The `template`, `svg`, `math`, `canvas`, `audio`, `video`, `select`, and `textarea` tags are now stripped from the output.
- The `main`, `figcaption`, `caption`, `summary`, `details`, `form`, `fieldset`, and `hgroup` tags are now formatted as block elements.
- The `menu` tag is now formatted as a bulleted list.

### Changed

- Data tables are now detected by the presence of a `thead` or `tbody` element in addition to a non-zero `border` attribute since the `border` attribute is deprecated in HTML5.
- `mailto:` and `tel:` link URLs are now included in the output when the link text differs from the address.
- Return an empty string instead of `nil` when the parsed document has no body.
- Line breaks are normalized and whitespace stripped on plain text input for consistency with HTML input.
- Minimum required Ruby version is now 2.7.

### Fixed

- Data tables with an explicit `tbody`, `thead`, or `tfoot` no longer lose their pipe separators.
- Trailing spaces are no longer removed from inside `pre` tag content.
- Fixed quadratic slowdown when converting large documents.
- Multiline `href` values are rejected so `javascript:` URLs can no longer leak into the output.

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
