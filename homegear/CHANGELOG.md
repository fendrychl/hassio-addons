# Changelog
Documentation of changes to this project.

## [0.73.0] - 2026-10-04

### Changed
- Based on `debian:trixie-slim` and Homegear stable 0.9.22 from the trixie repository
  (stretch/bullseye repositories are gone, so the old Dockerfile no longer builds)
- Repository key installed as a signed-by keyring instead of `apt-key`
- Base image set in the Dockerfile; `build.json` removed (deprecated by the Supervisor,
  which fell back to the Alpine base image)
- Supported architectures: aarch64, amd64, armv7

### Fixed
- Clean shutdown: daemons are signalled directly (`service homegear stop` fails on
  non-root pidfiles) and the add-on gets 30 s to stop, so peers are saved
- Logs in `/share/homegear/log` are rotated (10 MB, 3 copies) instead of growing forever

### Removed
- Unused `installNightly.sh` and `qemu-arm-static`

## [Unreleased]

- Support for Homeassistant Users
- Fix folder permissions
- add fix version of homegear
- get addon working in the sidebar
- access only from Hass (172.30.32.2)
- adding apparmor

## [0.72.1] - 2021-03-17

### Added
- Logo to the Addon
- Portsettings are now marked as Deprecated

### Remove

* remove the aarch64 architecture becouse there is no support from homegear for this

### Fixed
- Fix faile nodeBlueCredentialKey.txt
- Fix wrong Ingress Port

### Remove Port settings

## [0.72.0] - 2021-03-10

### Added
- Add support for Raspberry Pi 4 (64bit)

### Fixed
- Fix deprecated "auto-uart"
- Fix changelog

## Version 0.71.0

- Add native sidebare integration
- Add Port-description
- Add i386 support
- Change container to Debian


## Version 0.70.4

- Fix permission issues

## Version 0.70.3

- Adding Webui link
- Changing hard coded device to auto_uart
