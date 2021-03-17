# RELEASE NOTES for svlib

All notable changes to this project will be documented in this file.

From version 1.0.0 on, the format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2021-03-17

### Changed
- resolved issue #6
- resolved issue #11: migrated utest/ to svunit 3.34 (https://github.com/tudortimi/svunit)
- resolved issue #10
- moved repository from Trac to bitbucket
- changed informational files to markdown
- changed RELEASE_NOTES to use semantic versioning and Keep-A-Changelog

### Added
- added missing documentation for package-level functions (Trac #34 and #36)
- added str_range() package-level function

## [0.5.1] - 2020-11-23

### Fixed

- Trac #35: file_accessible throws if file not accessible.
Fixed (thorsten).
- Trac #36: Change Str::split() to exhibit behaviour of Perl/Awk regarding whitespace.
Done, not yet documented (thorsten).

### Added
- Trac #34: Add split package-level function
Added str_split(), not yet documented (thorsten).

## [0.5.0] - 2015-02-15

### Fixed
- Trac #28: Str::create can cause runtime crash
Obstack::obtain now checks for null process handle before interrogating
process::get_randstate().
- Trac #31: File descriptor argument to foreach_line macro evaluated repeatedly
This defect has been fixed so that the following idiom works as expected:
  `` `foreach_line($fopen("MYFILE.TXT","r"), lineVar, lineNumVar) ...``

### Added
- Trac #29: Add regex_match to documentation
This package-level function is now documented.
- Trac #24: Add Perl-style regex-based split
Regex::split method, and package-level function regex_split,
implemented and documented.
