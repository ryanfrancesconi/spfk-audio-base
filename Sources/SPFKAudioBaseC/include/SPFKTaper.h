// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio-base

#pragma once

#include <math.h>

/// The taper's gain at normalized position `t`, with exponent `value` and blend weight `skew`.
///
/// The one evaluation of a taper: offline rendering and the render thread both call it, so a curve
/// renders as it plays. Real-time safe. `t` and the result are clamped to [0, 1].
static inline double spfk_taper_gain(double t, double value, double skew) {
    if (!(t > 0.0)) t = 0.0;
    if (t > 1.0) t = 1.0;

    double concave = pow(t, value);
    double convex = 1.0 - pow(1.0 - t, 1.0 / value);
    double result = concave * (1.0 - skew) + convex * skew;

    if (!(result > 0.0)) return 0.0;
    return result > 1.0 ? 1.0 : result;
}
