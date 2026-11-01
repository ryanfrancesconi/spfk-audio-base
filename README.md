# SPFKAudioBase
[![Version](https://img.shields.io/github/v/tag/ryanfrancesconi/spfk-audio-base)](https://github.com/ryanfrancesconi/spfk-audio-base/tags)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanfrancesconi%2Fspfk-audio-base%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanfrancesconi/spfk-audio-base)

Support vocabulary for the audio packages: the types, extensions and small utilities they all share,
so that two packages describing the same thing describe it the same way. Nothing uses it on its own.
It is transitive in every audio package and in both products.

What belongs here is anything more than one package needs to agree on and nobody owns outright: the
audio file formats and what each can store, musical values such as tempo and key, loudness results,
the description of a pending edit (trim, channels, reverse, time and pitch, normalize, fade),
automation curves and the timeline they play against, conversion options, the persisted shape of an
effects chain, and AVFoundation conveniences. An edit is described here, rendered by
spfk-audio-conversion and played by spfk-audio-nodes, so a pending edit can be stored with a file
and survive a relaunch.

The arithmetic that has to be identical on and off the render thread, such as fade tapers and
automation curves, is in a small C target, `SPFKAudioBaseC`, so real-time code evaluates exactly
what the Swift side draws and exports.

Measuring belongs to spfk-loudness, spfk-tempo and spfk-musical-analysis; decoding and writing to
spfk-audio-conversion; metadata to spfk-metadata; anything below audio to spfk-base.

## Matroska

`AudioFileType` lists `.mka`, `.mkv` and `.webm` because their metadata is readable, but
AVFoundation cannot open them. Check `isMatroska` before any AVFoundation read and route those files
to spfk-matroska instead.

## About

Spongefork is the personal software projects of musician and developer [Ryan Francesconi](https://spongefork.com). Dedicated to creative sound manipulation, his first application, Spongefork, was released in 1999 for macOS 8. From 2026, Spongefork returns as his software container for more musical experimentation. In addition to [software releases](https://spongefork.com/shadowtag/), open source components can be found on his [GitHub page](https://github.com/ryanfrancesconi).
