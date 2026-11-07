// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

#pragma once

#include <math.h>
#include <stdint.h>

/// Which source position is processed at each render sample. `direction` is 1 or -1; the loop
/// applies when `loopEnd > loopStart`.
typedef struct TimelineMappingC {
    int64_t renderAnchor;
    double sourceAnchor;
    double rate;
    int32_t direction;
    double loopStart;
    double loopEnd;
    double renderSampleRate;
} TimelineMappingC;

/// The source position at `renderSample`, computed from the anchor rather than accumulated, and
/// wrapped into the loop. Before the anchor it is the source anchor.
static inline double timelinePosition(const TimelineMappingC *mapping, int64_t renderSample) {
    if (renderSample <= mapping->renderAnchor) return mapping->sourceAnchor;

    double elapsed = (double)(renderSample - mapping->renderAnchor) / mapping->renderSampleRate;
    double position = mapping->sourceAnchor + (double)mapping->direction * mapping->rate * elapsed;

    double length = mapping->loopEnd - mapping->loopStart;
    if (!(length > 0.0)) return position;

    if (mapping->direction > 0 && position >= mapping->loopEnd) {
        return mapping->loopStart + fmod(position - mapping->loopStart, length);
    }

    if (mapping->direction < 0 && position < mapping->loopStart) {
        double back = fmod(mapping->loopStart - position, length);
        return back > 0.0 ? mapping->loopEnd - back : mapping->loopStart;
    }

    return position;
}

/// The mapping with its rate changed from `renderSample` on: anchored there, at the position it
/// already gives that sample, so the position stays continuous and only its slope changes. A sample
/// before the anchor folds at the anchor.
static inline TimelineMappingC timelineFold(const TimelineMappingC *mapping, int64_t renderSample, double rate) {
    TimelineMappingC folded = *mapping;
    if (renderSample < mapping->renderAnchor) renderSample = mapping->renderAnchor;

    folded.sourceAnchor = timelinePosition(mapping, renderSample);
    folded.renderAnchor = renderSample;
    folded.rate = rate;
    return folded;
}
