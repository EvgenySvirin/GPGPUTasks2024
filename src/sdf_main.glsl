
vec3 PLANCTON_COLOR = vec3(124.f / 256.f, 178.f / 256.f , 176.f / 256.f);
float INF = 1e9;
// sphere with center in (0, 0, 0)
float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

// XZ plane
float sdPlane(vec3 p)
{
    return p.y;
}

// косинус который пропускает некоторые периоды, удобно чтобы махать ручкой не все время
float lazycos(float angle)
{
    int nsleep = 10;
    
    int iperiod = int(angle / 6.28318530718) % nsleep;
    if (iperiod < 3) {
        return cos(angle);
    }
    
    return 1.0;
}

// возможно, для конструирования тела пригодятся какие-то примитивы из набора https://iquilezles.org/articles/distfunctions/
// способ сделать гладкий переход между примитивами: https://iquilezles.org/articles/smin/
vec4 sdBody(vec3 p)
{
    vec3 pos = (p - vec3(0.0, 0.45, -0.7)) * vec3(1.4, 1, 1.0);


    // return distance and color
    return vec4(sdSphere(pos, 0.35), PLANCTON_COLOR);
}

vec4 sdEye(vec3 p)
{
    vec3 pos = p - vec3(0.0, 0.55, -0.45);

    float dist = sdSphere(pos, 0.13);

    float rad = length(vec3(pos.x, pos.y, 0.0));
    if (0.05 < rad) {
        return vec4(dist, 1.0, 1.0, 1.0);
    } else {
        return vec4(dist, 1.0, 0.0, 0.0);
    } 
}


float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

vec4 sdLimb(vec3 pos, vec3 limbEnd, vec3 limbStart, float limbRadius)
{

  return vec4(sdCapsule(pos, limbEnd, limbStart, limbRadius), PLANCTON_COLOR);
}


float sdCone( vec3 p, vec2 c, float h )
{
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}

vec4 sdTentacle(vec3 pos, vec2 c, float h)
{

  return vec4(sdCone(pos, c, h), PLANCTON_COLOR);
}

float sdCappedTorus( vec3 p, vec2 sc, float ra, float rb)
{
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

vec4 sdMouth(vec3 p)
{
    vec3 pos = p;

    return vec4(sdCappedTorus(pos, vec2(-0.3, 0.4), 0.2, 0.01), 0.0, 0.0, 0.0);
}


vec4 sdMonster(vec3 p)
{
    // при рисовании сложного объекта из нескольких SDF, удобно на верхнем уровне 
    // модифицировать p, чтобы двигать объект как целое
    p -= vec3(0.0, 0.04, 0.0);
    
    vec4 res = sdBody(p);
    
    vec4 eye = sdEye(p);
    if (eye.x < res.x) {
        res = eye;
    }
    
    float armRadius = 0.03;
    
    vec3 leftArmStart = vec3(-0.15, 0.2, -0.07);
    vec3 leftArmEnd = vec3(0.05, 0.02, -0.07);
    vec4 leftArm = sdLimb(p - vec3(0.35, 0.3, -0.55),
        leftArmEnd,
        leftArmStart,
        armRadius);
    if (leftArm.x < res.x) {
        res = leftArm;
    }
    
    vec3 rightArmStart = leftArmStart * vec3(-1.0, 1.0, 1.0);
    
    vec3 rightArmEnd = rightArmStart;
    rightArmEnd *= vec3(-1.0, 1.0, 1.0);
    
    
    float period = 1.3;
    int periodNum = int(iTime / period);
    bool isEvenPeriod = (periodNum % 2 == 0);
    float t = (iTime - float(periodNum) * period);
    if (!isEvenPeriod) {
        t = period - t;
    }
    
    float armLength = length(leftArmEnd - leftArmStart);
    rightArmEnd.y +=  1.4 * sin(t - 0.1) * armLength;
    rightArmEnd.z += 1.4 * cos(t - 0.1) * armLength;
    
    
    vec4 rightArm = sdLimb(p - vec3(-0.35, 0.3, -0.55),
        rightArmEnd,
        rightArmStart,
        armRadius);
    if (rightArm.x < res.x) {
        res = rightArm;
    }
    
    
    float legRadius = 0.02;
    vec3 leftLegStart = vec3(-0.3, 0.0, 0.05);
    vec3 leftLegEnd = vec3(-0.3, -0.2, 0.05);
    vec4 leftLeg = sdLimb(p - vec3(0.35, 0.3, -0.55),
        leftLegEnd,
        leftLegStart,
        legRadius);
    if (leftLeg.x < res.x) {
        res = leftLeg;
    }
    
    vec3 rightLegStart = leftLegStart  * vec3(-1.0, 1.0, 1.0);
    vec3 rightLegEnd = leftLegEnd * vec3(-1.0, 1.0, 1.0);
    vec4 rightLeg = sdLimb(p - vec3(-0.35, 0.3, -0.55),
        rightLegEnd,
        rightLegStart,
        legRadius);
    if (rightLeg.x < res.x) {
        res = rightLeg;
    }
    
    vec4 leftTentacle = sdTentacle(p - vec3(0.05, 1.2, -0.55), vec2(0.85, 0.04), 0.45);
    if (leftTentacle.x < res.x) {
        res = leftTentacle;
    }
    
    vec4 rightTentacle = sdTentacle(p - vec3(-0.05, 1.2, -0.55), vec2(0.85, 0.04), 0.45);
    if (rightTentacle.x < res.x) {
        res = rightTentacle;
    }
    
    vec4 mouth = sdMouth(p - vec3(0.0, 0.6, -0.3));
    
    if (mouth.x < res.x) {
    res = mouth;
    }
    
    return res;
}


vec4 sdTotal(vec3 p)
{

    vec4 res = sdMonster(p);
    
    
    float dist = sdPlane(p);
    if (dist < res.x) {
        res = vec4(dist, vec3(1.0, 0.0, 0.0));
    }
    
    return res;
}
// see https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sdTotal(p+h.xyy).x - sdTotal(p-h.xyy).x,
                           sdTotal(p+h.yxy).x - sdTotal(p-h.yxy).x,
                           sdTotal(p+h.yyx).x - sdTotal(p-h.yyx).x ) );
}


vec4 raycast(vec3 ray_origin, vec3 ray_direction)
{
    
    float EPS = 1e-3;
    
    
    // p = ray_origin + t * ray_direction;
    
    float t = 0.0;
    
    for (int iter = 0; iter < 200; ++iter) {
        vec4 res = sdTotal(ray_origin + t * ray_direction);
        t += res.x;
        if (res.x < EPS) {
            return vec4(t, res.yzw);
        }
    }

    return vec4(1e10, vec3(0.0, 0.0, 0.0));
}


float shading(vec3 p, vec3 light_source, vec3 normal)
{
    
    vec3 light_dir = normalize(light_source - p);
    
    float shading = dot(light_dir, normal);
    
    return clamp(shading, 0.5, 1.0);

}

// phong model, see https://en.wikibooks.org/wiki/GLSL_Programming/GLUT/Specular_Highlights
float specular(vec3 p, vec3 light_source, vec3 N, vec3 camera_center, float shinyness)
{
    vec3 L = normalize(p - light_source);
    vec3 R = reflect(L, N);

    vec3 V = normalize(camera_center - p);
    
    return pow(max(dot(R, V), 0.0), shinyness);
}


float castShadow(vec3 p, vec3 light_source)
{
    
    vec3 light_dir = p - light_source;
    
    float target_dist = length(light_dir);
    
    
    if (raycast(light_source, normalize(light_dir)).x + 0.001 < target_dist) {
        return 0.5;
    }
    
    return 1.0;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y;
    
    vec2 wh = vec2(iResolution.x / iResolution.y, 1.0);
    

    vec3 ray_origin = vec3(0.0, 0.5, 1.0);
    vec3 ray_direction = normalize(vec3(uv - 0.5*wh, -1.0));
    

    vec4 res = raycast(ray_origin, ray_direction);
    
    
    
    vec3 col = res.yzw;
    
    
    vec3 surface_point = ray_origin + res.x*ray_direction;
    vec3 normal = calcNormal(surface_point);
    
    vec3 light_source = vec3(1.0 + 2.5*sin(iTime), 15.0, 10.0);
    
    float shad = shading(surface_point, light_source, normal);
    shad = min(shad, castShadow(surface_point, light_source));
    col *= shad;
    
    float spec = specular(surface_point, light_source, normal, ray_origin, 30.0);
    col += vec3(1.0, 1.0, 1.0) * spec;
    
    
    
    // Output to screen
    fragColor = vec4(col, 1.0);
}
