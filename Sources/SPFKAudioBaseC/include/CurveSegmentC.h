// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

#pragma once

#include <math.h>
#include <stdint.h>

#include "AudioTaperC.h"

/// How a segment moves from its start value to its end value.
typedef enum __attribute__((enum_extensibility(closed))) CurveShapeKindC : int32_t {
    CurveShapeLinear = 0,
    CurveShapeTaper = 1,
    /// The start value up to the segment's end, then the end value.
    CurveShapeStep = 2,
} CurveShapeKindC;

/// One segment of a parameter curve, in source seconds.
///
/// `shapeStart`/`shapeEnd` are the normalized part of the shape the segment covers: 0 and 1 unless
/// the segment was cut, so a cut keeps the shape exact. `startValue`/`endValue` are the shape's
/// values at 0 and 1, not at a cut.
typedef struct CurveSegmentC {
    double start;
    double end;
    double shapeStart;
    double shapeEnd;
    double startValue;
    double endValue;
    CurveShapeKindC shape;
    double taperValue;
    double taperSkew;
} CurveSegmentC;

/// The shape's normalized value at `x` ∈ [0, 1].
static inline double curveShapeValue(const CurveSegmentC *segment, double x) {
    switch (segment->shape) {
        case CurveShapeLinear: return x;
        case CurveShapeTaper: return taperGain(x, segment->taperValue, segment->taperSkew);
        case CurveShapeStep: return x >= 1.0 ? 1.0 : 0.0;
    }
    return x;
}

/// The segment's value at `position`, held at its ends outside it.
static inline double curveSegmentValue(const CurveSegmentC *segment, double position) {
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

    return segment->startValue + (segment->endValue - segment->startValue) * curveShapeValue(segment, x);
}

/// The value the segment opens on, whatever its length; a curve holds it before its first segment.
static inline double curveSegmentStartValue(const CurveSegmentC *segment) {
    return segment->startValue +
           (segment->endValue - segment->startValue) * curveShapeValue(segment, segment->shapeStart);
}

/// The index of the last segment starting at or before `position`, or -1 when none does.
/// `segments` are ordered and do not overlap.
static inline long curveFind(const CurveSegmentC *segments, long count, double position) {
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
static inline double curveValue(const CurveSegmentC *segments, long count, double position) {
    if (count <= 0) return 0.0;

    long index = curveFind(segments, count, position);
    if (index < 0) return curveSegmentStartValue(&segments[0]);

    return curveSegmentValue(&segments[index], position);
}
