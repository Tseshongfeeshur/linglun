#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uPulse;
uniform float uPhase;
uniform vec3 uColor0;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec3 uRandom;

out vec4 fragColor;

// 纯 float 运算的 hash，不依赖 sin()（避免大参数下三角函数精度退化导致的条纹），
// 也不依赖 uint / 位运算（避免 Flutter shader 编译工具链对这类构造的兼容性问题）。
// 写法参考自常见的乘法混合 hash（IQ 风格），在各平台/精度模式下表现稳定。
float hash(vec2 point) {
  vec3 p3 = fract(vec3(point.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
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

// 对时间轴做三点三角核平均，削弱噪声格之间的尖锐过渡。
float smoothedDegree(float time, float y) {
  const float sampleDistance = 0.35;
  float previous = noise(vec2(
    time - sampleDistance + uRandom.x,
    y + uRandom.y
  ));
  float current = noise(vec2(time + uRandom.x, y + uRandom.y));
  float next = noise(vec2(
    time + sampleDistance + uRandom.x,
    y + uRandom.y
  ));
  return previous * 0.25 + current * 0.5 + next * 0.25;
}

vec3 srgbToLinear(vec3 color) {
  return pow(max(color, vec3(0.0)), vec3(2.2));
}

vec3 linearToSrgb(vec3 color) {
  return pow(max(color, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 protectHighlights(vec3 linearColor) {
  const float highlightThreshold = 0.16;
  const float highlightCeiling = 0.30;
  const float channelCeiling = 0.34;

  float luminance = dot(
    linearColor,
    vec3(0.2126, 0.7152, 0.0722)
  );

  vec3 result = linearColor;

  if (luminance > highlightThreshold && luminance > 0.0001) {
    float excess = luminance - highlightThreshold;
    float kneeRange = highlightCeiling - highlightThreshold;
    float compressedLuminance = highlightThreshold
        + kneeRange * (1.0 - exp(-excess / kneeRange));
    result *= (compressedLuminance / luminance);
  }

  float maxChannel = max(result.r, max(result.g, result.b));
  if (maxChannel > channelCeiling) {
    result *= (channelCeiling / maxChannel);
  }

  return result;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 point = uv - 0.5;
  float time = uTime * 0.1;
  float degree = smoothedDegree(time, point.x * point.y);
  float angle = (degree - 0.5) * 3.0 + uRandom.z;
  point = rotatePoint(point, angle);

  float speed = uPhase;
  point.x += sin(point.y * 5.0 + speed) / 24.0;
  point.y += sin(point.x * 7.5 + speed) / 12.0;

  float horizontal = smoothstep(-0.3, 0.2, point.x);
  float vertical = 1.0 - smoothstep(-0.3, 0.5, point.y);
  vec3 top = mix(uColor0, uColor1, horizontal);
  vec3 bottom = mix(uColor2, uColor3, horizontal);
  vec3 color = mix(top, bottom, vertical);
  color = mix(color, color * (1.0 + uPulse * 0.06), uPulse);
  vec3 linearColor = srgbToLinear(color);
  linearColor = protectHighlights(linearColor);
  color = linearToSrgb(linearColor);
  color += (hash(FlutterFragCoord().xy + uRandom.xy * 97.0) - 0.5) / 255.0;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
