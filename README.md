# Live Wallpaper Tool (macOS Apple Silicon)

A lightweight local CLI to run looping live wallpapers on macOS (M-series supported).

## Features

- Set a wallpaper video and relaunch it anytime
- Auto-convert unsupported videos (for example `.webm`) to compatible `.mp4`
- Persist selected video path between runs
- Keep a local action history log

## Requirements

- macOS
- Xcode Command Line Tools
- ffmpeg (`brew install ffmpeg`) for conversion

## Quick Start

```bash
git clone https://github.com/<your-username>/livewallpaper-macos.git
cd livewallpaper-macos
chmod +x livewallpaper
./livewallpaper add-auto /absolute/path/to/video.webm
```

## Commands

```bash
./livewallpaper add <video-path>
./livewallpaper add-auto <video-path>
./livewallpaper convert <video-path>
./livewallpaper launch
./livewallpaper launch <video-path>
./livewallpaper stop
./livewallpaper status
./livewallpaper history
./livewallpaper build
```

## Logs and State

- Selected video: `~/.livewallpaper/video_path`
- Runtime log: `~/.livewallpaper/livewallpaper.log`
- History log: `~/.livewallpaper/history.log`
- Converted videos: `~/.livewallpaper/videos/`

## Troubleshooting

If a file fails with `Unsupported or unreadable video: Cannot Open`, convert and retry:

```bash
./livewallpaper add-auto /absolute/path/to/video.webm
```
