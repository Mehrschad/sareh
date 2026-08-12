// نور — سایه‌زنِ درخششِ لحظه‌ی دستاورد.
//
// برای افکت‌های نوری از Fragment Shader استفاده می‌شود، نه از انباشتِ ویجت‌های
// شفاف (بخش ۷٫۴). یک هاله‌ی شعاعی با افتِ نمایی، به‌علاوه‌ی چند پرتوِ نرم که
// از مرکز می‌تابند — مثلِ نوری که از کاشیِ شبستان می‌گذرد.
//
// بارگذاری:
//   final program = await FragmentProgram.fromAsset('shaders/nur.frag');

#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;      // اندازه‌ی بوم به پیکسل
uniform float uProgress;  // ۰ تا ۱ — پیشرفتِ انیمیشن
uniform vec4  uColour;    // رنگِ هاله، با آلفا

out vec4 fragColor;

const float PI = 3.14159265359;
const int   RAYS = 8;     // هشت پرتو، هم‌شمارِ پرهای شمسه

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 centred = uv - 0.5;
    // نسبتِ ابعاد را جبران می‌کنیم تا هاله بیضی نشود.
    centred.x *= uSize.x / uSize.y;

    float dist = length(centred);
    float angle = atan(centred.y, centred.x);

    // هاله رشد می‌کند و هم‌زمان محو می‌شود: اوجِ روشنایی در میانه‌ی راه است.
    float reach = 0.15 + uProgress * 0.45;
    float halo = exp(-pow(dist / reach, 2.0) * 3.0);
    float fade = sin(uProgress * PI);

    // پرتوها: تابعی کسینوسی حولِ زاویه، که با فاصله نازک می‌شود.
    float rays = 0.5 + 0.5 * cos(angle * float(RAYS) - uProgress * PI);
    rays = pow(rays, 6.0) * exp(-dist * 5.0);

    float intensity = (halo + rays * 0.35) * fade;
    fragColor = vec4(uColour.rgb, uColour.a * clamp(intensity, 0.0, 1.0));
}
