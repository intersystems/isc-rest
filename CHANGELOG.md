# isc.rest

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased - 1.2.2+snapshot]

### Added 
- 

### Changed
-

### Fixed
-

### Security
-

### Removed
- 

### Deprecated
-

## [1.2.1] - 2022-10-05

### Fixed
- APPS-15075: Generating OpenAPI doc produces deterministic results
- APPS-13794: OpenAPI generated properly for query/path action parameters
- APPS-13849: OpenAPI doc includes query filter
- APPS-13664: %Dictionary.Classname is treated as string instead of object
- Unsupported actions are always omitted from OpenAPI generation

## [1.2.0] - 2022-08-08

### Added 
- APPS-12985: Support removal of certain endpoints at the dispatch class and resource level
via new `Supports()` method that can be overridden at REST handler and resource levels.
- APPS-13327: Add "user-context" source for arguments in action map XData blocks.
- APPS-13152: Do compile time validation for classes part of public API to ensure
appropriate class members are overridden in subclasses.
- APPS-12782: Support for fallback/default mimetype/representation of a resource when a 
regular expression of either `*/*` or `application/*` is used in an Accept header.
- APPS-13359: Add appropriate error handling for unsupported return data types for custom actions.
- APPS-13361: Add support for return type of literals i.e. datatype classes for actions.
- APPS-13650: Add support for %CSP.Stream for return type of actions.

### Changed
- APPS-13152: Locked down methods as final in classes part of public API.
- APPS-13361: Remove constraint of JSON for action return types in handlers (keep it for content for now).

### Fixed
- APPS-13327: Fix a small issue in `$$$OperationAction` macro where lack of 
parentheses could cause invalid equality checks against an action name.
- APPS-13388: Swap `write` for `do` when using `%ToJSON()` to write to the current 
device to avoid `<MAXLEN>` errors.
- APPS-13698: Prevent spurious compilation errors validating default representations

## [1.0.1] - 2022-05-25
- Last released version before CHANGELOG existed.

