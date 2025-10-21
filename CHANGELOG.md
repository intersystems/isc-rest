# isc.rest

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.15] - 2025-10-03

### Fixed
- HSIEO-13170: Fix unique index length for action map to be under 511 to ensure we don't hit `<SUBSCRIPT>` errors.

## [2.4.0] - 2025-08-06

### Added 
- HSIEO-7815: Added /auth/login endpoint for customizing authorization requests

### Changed
- HSIEO-13080: Add Author info to module from "Ownership of AppModules" confluence page

### Fixed
- HSIEO-7815: Resolved method name conflict by updating /auth/login to invoke AuthLogin() instead of Login()

## [2.3.1] - 2025-06-03

### Fixed
- HSIEO-11531: Fix mixed use of Schema/Reference in OpenAPI generation WriteEndpoint

## [2.3.0] - 2025-02-12

### Added 
- HSIEO-11488: Add and use JSONExportToStream() for isc.rest.OpenAPI.model classes
- HSIEO-11745: Support a new contentType attribute for actions to override the default contentType.

### Fixed
- HSIEO-11745: Fix reported supportedTypes error message to filter correctly by HTTP verb.
Ensure that when */* is a media type, we add $Char(0) as well to search by.

## [2.2.0] - 2024-09-26

### Added 
- APPS-24948: Support inversion of control between strategy class and dispatch class

### Fixed
- HSIEO-10845: Ensure rest handler checks status from JSONExport. Fix compile check in singleton 
to not throw errors incorrectly. Fix identifying web app correctly for Open API spec gen when
web server prefix is in play.

## [2.1.3] - 2024-07-01

### Fixed
- HSIEO-10549, HSIEO-10797: when creating mappings for pkg.isc's persistent globals, make sure to avoid the prefix "^"

## [2.1.2] - 2024-04-10

### Fixed
- APPS-23422: Fix incorrect decoding of path parameters introduced by APPS-23171.
Unit test mocking doesn't correctly simulate %request.URL being automatically decoded.

## [2.1.1] - 2024-03-06

### Fixed
- APPS-23171: Ensure path parameters are url decoded. Fix unit test failures due to changes in %CSP.REST error projection

## [2.1.0] - 2023-10-18

### Added 
- HSIEO-5398: Add support for new default `SecurityResource` parameter. Add more compile time checks for `Singleton`
resource type.

## [2.0.0] - 2023-09-27

### Changed
- HSIEO-8297: IPM Adoption
- HSIEO-9269, HSIEO-9402: Deprecate % in perforce path

## [1.5.4] - 2023-09-15
 
## [1.5.3] - 2023-09-13

## [1.5.2] - 2023-06-22

## [1.5.1] - 2023-06-03

## [1.5.0] - 2023-05-02

### Added 
- APPS-20143: Support usage of DEFAULT param for custom actions
- APPS-20144: Treat no accept header as `*/*`

## [1.4.0] - 2023-08-16

### Added
- APPS-20985: Create singleton model and singleton abstract class.

### Fixed
- HSIEO-8028: Make sure singleton object is created and saved on initial creation
- APPS-21014: Ensure multidimensional properties skipped in schemas of OAS generation 
since they are not JSON-serializable.
Add handling for `%JSONFIELDNAMEASCAMELCASE` and FieldNameAsCamelCase
Fix OAS generation for singletons which are their own type of proxy.

### Changed
- HSIEO-8781: Use parent-child relationship to replace many-one relationship for Oauthconfig: Give abstractSingleton class's getSingeletonRecord util the option to save the record on first get

## [1.3.1] - 2023-03-29

### Changed
- APPS-20427: Add notes to trouble shooting guide about mismatched headers for 405.
Remove duplicates in 405 response.

## [1.3.0] - 2023-03-08

### Added 
- APPS-13404: When returning 406/415, return available media types for the resource.
- APPS-20003: New troubleshooting guide, some related updates to user guide + new
utility class `%pkg.isc.rest.utils` referenced in troubleshooting guide.
- APPS-20112: Added support for PATCH actions

### Changed
- APPS-20003: Added check to ensure no body argument can be used with GET actions.
- APPS-20339: Added %NOLOCK keyword to actionMap insert or update SQL statements in handler projection and action generator.

### Fixed
- APPS-13651: Support MEDIATYPE parameter for model.iSerializable in addition to 
model.resource for action request body and return type.
- APPS-13651: Remove requirement of json return type for actions.
- APPS-13404: Return 404 when resource doesn't exist instead of 406/415.
- APPS-20003: Fixed failing unit tests.

## [1.2.2] - 2024-12-05

### Fixed
- Added compatibility with IPM 0.9+

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
