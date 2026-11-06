# SPFKAudioBase
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-audio-base)](https://github.com/ryanfrancesconi/spfk-audio-base/tags)
[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)

Shared types and extensions for the Spongefork audio packages.

## Features

- `AudioFileType`: audio file formats and what each can store
- Musical values: `Bpm` and `MusicalKeyValue`
- `LoudnessDescription` for loudness results
- `AudioEditDescription`: a pending edit (trim, channels, reverse, normalize, fade, time and pitch)
- `ParameterCurve` automation curves and `TimelineMapping`
- `AudioFormatConverterOptions` and `AudioUnitChainState`
- AVFoundation extensions
- `SPFKAudioBaseC`: fade taper and curve evaluation in C, for use on the render thread

## Notes

- `AudioFileType` includes `.mka`, `.mkv` and `.webm`, which AVFoundation cannot open. Check
  `isMatroska` before any AVFoundation read.

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
