// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

#pragma once

#include <math.h>
#include <stdint.h>

#include "SPFKTaper.h"

/// How a segment moves from its start value to its end value.
typedef enum __attribute__((enum_extensibility(closed))) SPFKCurveShapeKind : int32_t {
    SPFKCurveShapeLinear = 0,
    SPFKCurveShapeTaper = 1,
    /// The start value up to the segment's end, then the end value.
    SPFKCurveShapeStep = 2,
} SPFKCurveShapeKind;

/// One segment of a parameter curve, in source seconds.
///
/// `shapeStart`/`shapeEnd` are the normalized part of the shape the segment covers: 0 and 1 unless
/// the segment was cut, so a cut keeps the shape exact. `startValue`/`endValue` are the shape's
/// values at 0 and 1, not at a cut.
typedef struct SPFKCurveSegment {
    double start;
    double end;
    double shapeStart;
    double shapeEnd;
    double startValue;
    double endValue;
    SPFKCurveShapeKind shape;
    double taperValue;
    double taperSkew;
} SPFKCurveSegment;

/// The shape's normalized value at `x` ∈ [0, 1].
static inline double spfk_curve_shape_value(const SPFKCurveSegment *segment, double x) {
    switch (segment->shape) {
        case SPFKCurveShapeLinear: return x;
        case SPFKCurveShapeTaper: return spfk_taper_gain(x, segment->taperValue, segment->taperSkew);
        case SPFKCurveShapeStep: return x >= 1.0 ? 1.0 : 0.0;
    }
    return x;
}

/// The segment's value at `position`, held at its ends outside it.
static inline double spfk_curve_segment_value(const SPFKCurveSegment *segment, double position) {
    double length = segment->end - segment->start;
    double u = length > 0.0 ? (position - segment->start) / length : 1.0;

    double x;
    if (!(u > 0.0)) {
        x = segment->shapeStart;
    } else if (u >= 1.0) {
        x = segment->shapeEnd;
    } else {
        x = segment->shapeStart + (segment->shapeEnd - segment->shapeStart) * u;
    }

    return segment->startValue + (segment->endValue - segment->startValue) * spfk_curve_shape_value(segment, x);
}

/// The index of the last segment starting at or before `position`, or -1 when none does.
/// `segments` are ordered and do not overlap.
static inline long spfk_curve_find(const SPFKCurveSegment *segments, long count, double position) {
    long low = 0, high = count;

    while (low < high) {
        long mid = low + (high - low) / 2;
        if (segments[mid].start <= position) {
            low = mid + 1;
        } else {
            high = mid;
        }
    }

    return low - 1;
}

/// The curve's value at `position`. Before the first segment it holds that segment's start value,
/// and between and after segments the previous one's end value. 0 for an empty curve.
static inline double spfk_curve_value(const SPFKCurveSegment *segments, long count, double position) {
    if (count <= 0) return 0.0;

    long index = spfk_curve_find(segments, count, position);
    if (index < 0) return spfk_curve_segment_value(&segments[0], segments[0].start);

    return spfk_curve_segment_value(&segments[index], position);
}

// MARK: - Timeline

/// Which source position is processed at each render sample. `direction` is 1 or -1; the loop
/// applies when `loopEnd > loopStart`.
typedef struct SPFKTimelineMapping {
    int64_t renderAnchor;
    double sourceAnchor;
    double rate;
    int32_t direction;
    double loopStart;
    double loopEnd;
    double renderSampleRate;
} SPFKTimelineMapping;

/// The source position at `renderSample`, computed from the anchor rather than accumulated, and
/// wrapped into the loop. Before the anchor it is the source anchor.
static inline double spfk_timeline_position(const SPFKTimelineMapping *mapping, int64_t renderSample) {
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
