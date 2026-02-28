# Release Checklist

Use this checklist before publishing a new release.

## Pre-release

- [ ] Confirm code compiles: `./livewallpaper build`
- [ ] Validate launch flow with a known good mp4:
  - `./livewallpaper add /absolute/path/to/video.mp4`
  - `./livewallpaper launch`
  - `./livewallpaper stop`
- [ ] Validate auto conversion flow:
  - `./livewallpaper add-auto /absolute/path/to/video.webm`
- [ ] Confirm docs are up to date (`README.md`)
- [ ] Confirm license file exists (`LICENSE`)
- [ ] Ensure generated/local data is ignored (`.gitignore`)

## Git release

- [ ] Ensure clean git state: `git status`
- [ ] Commit final changes
- [ ] Create tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
- [ ] Push branch: `git push origin main`
- [ ] Push tags: `git push origin --tags`

## GitHub release page

- [ ] Create a new GitHub Release from the tag
- [ ] Add release notes:
  - Features added
  - Fixes
  - Known limitations (for example unsupported codecs)
- [ ] Mark as latest stable release
