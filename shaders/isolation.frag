#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uPulse;
uniform float uFrameInterval;
uniform vec3 uColor0;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec3 uRandom;

out vec4 fragColor;

float hash(vec2 point) {
  return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 point) {
  vec2 cell = floor(point);
  vec2 offset = fract(point);
  vec2 eased = offset * offset * (3.0 - 2.0 * offset);
  float a = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), eased.x);
  float b = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), eased.x);
  return mix(a, b, eased.y);
}

vec2 rotatePoint(vec2 point, float angle) {
  float sine = sin(angle);
  float cosine = cos(angle);
  return vec2(point.x * cosine - point.y * sine, point.x * sine + point.y * cosine);
}

vec3 srgbToLinear(vec3 color) {
  return pow(max(color, vec3(0.0)), vec3(2.2));
}

vec3 linearToSrgb(vec3 color) {
  return pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 protectHighlights(vec3 linearColor) {
  const float highlightThreshold = 0.62;
  const float kneeStrength = 1.8;
  float luminance = dot(
    linearColor,
    vec3(0.2126, 0.7152, 0.0722)
  );

  if (luminance <= highlightThreshold || luminance <= 0.0001) {
    return linearColor;
  }

  // 只压缩流光背景的高亮区域，保留暗部和中间调，避免影响歌词与控件的对比度。
  float excess = luminance - highlightThreshold;
  float compressedLuminance = highlightThreshold
      + excess / (1.0 + excess * kneeStrength);
  return linearColor * (compressedLuminance / luminance);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 point = uv - 0.5;
  float quantizedTime = floor(uTime / max(uFrameInterval, 0.0001)) * uFrameInterval;
  float time = quantizedTime * 0.1;
  float degree = noise(vec2(time + uRandom.x, point.x * point.y + uRandom.y));
  float angle = (degree - 0.5) * 6.28318 + uRandom.z;
  point = rotatePoint(point, angle);

  float pulse = 1.0 + uPulse * 0.12;
  float speed = time * pulse;
  point.x += sin(point.y * 5.0 + speed) / 24.0;
  point.y += sin(point.x * 7.5 + speed) / 12.0;

  float horizontal = smoothstep(-0.3, 0.2, point.x);
  float vertical = 1.0 - smoothstep(-0.3, 0.5, point.y);
  vec3 top = mix(uColor0, uColor1, horizontal);
  vec3 bottom = mix(uColor2, uColor3, horizontal);
  vec3 color = mix(top, bottom, vertical);
  color = mix(color, color * (1.0 + uPulse * 0.02), uPulse);
  vec3 linearColor = srgbToLinear(color);
  linearColor = protectHighlights(linearColor);
  color = linearToSrgb(linearColor);
  color += (hash(FlutterFragCoord().xy + uRandom.xy * 97.0) - 0.5) / 255.0;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
