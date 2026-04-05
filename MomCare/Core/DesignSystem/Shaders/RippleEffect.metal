#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Radial ripple distortion effect for interactive feedback on quick-log buttons.
// Parameters:
//   origin    - tap position in view-local pixels
//   time      - seconds since the tap
//   intensity - peak displacement in pixels
//   frequency - oscillation frequency (radians/second)
//   decay     - exponential decay rate
[[stitchable]] float2 feedingRipple(
    float2 position,
    float2 origin,
    float time,
    float intensity,
    float frequency,
    float decay
) {
    float2 delta = position - origin;
    float dist = length(delta);
    if (dist < 0.001) return position;

    float delay = dist / 600.0;
    float elapsed = max(0.0, time - delay);
    float amplitude = intensity * sin(elapsed * frequency) * exp(-elapsed * decay);

    return position + (delta / dist) * amplitude;
}
