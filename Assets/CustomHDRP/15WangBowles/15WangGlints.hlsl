#ifndef __GLINTS15__
#define __GLINTS15__

#ifndef LAYERED_LIT_SHADER
#define "LitProperties.hlsl"
#endif

// i have chosen to use parts of FastNoiseLite/ noise generators
// source: https://github.com/Auburn/FastNoiseLite/tree/master
static const int PRIME_X = 501125321;
static const int PRIME_Y = 1136930381;
static const int PRIME_Z = 1720413743;


float _fnlFastFloor(float f) { return (f >= 0 ? (int)f : (int)f - 1); }
float _fnlInterpQuintic(float t) { return t * t * t * (t * (t * 6 - 15) + 10); }
float _fnlLerp(float a, float b, float t) { return a + t * (b - a); }


int _fnlHash3D(int seed, int xPrimed, int yPrimed, int zPrimed)
{
    int hash = seed ^ xPrimed ^ yPrimed ^ zPrimed;

    hash *= 0x27d4eb2d;
    return hash;
}
static const float GRADIENTS_3D[] = 
{
    0, 1, 1, 0,  0,-1, 1, 0,  0, 1,-1, 0,  0,-1,-1, 0,
    1, 0, 1, 0, -1, 0, 1, 0,  1, 0,-1, 0, -1, 0,-1, 0,
    1, 1, 0, 0, -1, 1, 0, 0,  1,-1, 0, 0, -1,-1, 0, 0,
    0, 1, 1, 0,  0,-1, 1, 0,  0, 1,-1, 0,  0,-1,-1, 0,
    1, 0, 1, 0, -1, 0, 1, 0,  1, 0,-1, 0, -1, 0,-1, 0,
    1, 1, 0, 0, -1, 1, 0, 0,  1,-1, 0, 0, -1,-1, 0, 0,
    0, 1, 1, 0,  0,-1, 1, 0,  0, 1,-1, 0,  0,-1,-1, 0,
    1, 0, 1, 0, -1, 0, 1, 0,  1, 0,-1, 0, -1, 0,-1, 0,
    1, 1, 0, 0, -1, 1, 0, 0,  1,-1, 0, 0, -1,-1, 0, 0,
    0, 1, 1, 0,  0,-1, 1, 0,  0, 1,-1, 0,  0,-1,-1, 0,
    1, 0, 1, 0, -1, 0, 1, 0,  1, 0,-1, 0, -1, 0,-1, 0,
    1, 1, 0, 0, -1, 1, 0, 0,  1,-1, 0, 0, -1,-1, 0, 0,
    0, 1, 1, 0,  0,-1, 1, 0,  0, 1,-1, 0,  0,-1,-1, 0,
    1, 0, 1, 0, -1, 0, 1, 0,  1, 0,-1, 0, -1, 0,-1, 0,
    1, 1, 0, 0, -1, 1, 0, 0,  1,-1, 0, 0, -1,-1, 0, 0,
    1, 1, 0, 0,  0,-1, 1, 0, -1, 1, 0, 0,  0,-1,-1, 0
};
float _fnlGradCoord3D(int seed, int xPrimed, int yPrimed, int zPrimed, float xd, float yd, float zd)
{
    int hash = _fnlHash3D(seed, xPrimed, yPrimed, zPrimed);
    hash ^= hash >> 15;
    hash &= 63 << 2;
    return xd * GRADIENTS_3D[hash] + yd * GRADIENTS_3D[hash | 1] + zd * GRADIENTS_3D[hash | 2];
}
float cnoise2(float3 inpt)
{
    float x = inpt.x;
    float y = inpt.y;
    float z = inpt.z;
    int seed =128;
    int x0 = _fnlFastFloor(x);
    int y0 = _fnlFastFloor(y);
    int z0 = _fnlFastFloor(z);

    float xd0 = (float)(x - x0);
    float yd0 = (float)(y - y0);
    float zd0 = (float)(z - z0);
    float xd1 = xd0 - 1;
    float yd1 = yd0 - 1;
    float zd1 = zd0 - 1;

    float xs = _fnlInterpQuintic(xd0);
    float ys = _fnlInterpQuintic(yd0);
    float zs = _fnlInterpQuintic(zd0);

    x0 *= PRIME_X;
    y0 *= PRIME_Y;
    z0 *= PRIME_Z;
    int x1 = x0 + PRIME_X;
    int y1 = y0 + PRIME_Y;
    int z1 = z0 + PRIME_Z;

    float xf00 = _fnlLerp(_fnlGradCoord3D(seed, x0, y0, z0, xd0, yd0, zd0), _fnlGradCoord3D(seed, x1, y0, z0, xd1, yd0, zd0), xs);
    float xf10 = _fnlLerp(_fnlGradCoord3D(seed, x0, y1, z0, xd0, yd1, zd0), _fnlGradCoord3D(seed, x1, y1, z0, xd1, yd1, zd0), xs);
    float xf01 = _fnlLerp(_fnlGradCoord3D(seed, x0, y0, z1, xd0, yd0, zd1), _fnlGradCoord3D(seed, x1, y0, z1, xd1, yd0, zd1), xs);
    float xf11 = _fnlLerp(_fnlGradCoord3D(seed, x0, y1, z1, xd0, yd1, zd1), _fnlGradCoord3D(seed, x1, y1, z1, xd1, yd1, zd1), xs);

    float yf0 = _fnlLerp(xf00, xf10, ys);
    float yf1 = _fnlLerp(xf01, xf11, ys);

    return _fnlLerp(yf0, yf1, zs) * 0.964921414852142333984375f;
}


float cnoise(float3 inp)
{
    inp = float3(inp.x*_wbTestNoise,inp.y*_wbTestNoise,inp.z*_wbTestNoise);
    if(_wbUsePerlinTexture)
        return    UNITY_SAMPLE_TEX3D_SAMPLER(_wbPerlinTexture,_wbPerlinTexture, inp);
    return    cnoise2(inp);
   }

float rand(float2 co)
{
    co.x = co.x - frac(co.x);
    co.y = co.y - frac(co.y);
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float3 randomVec3(float2 seed, float seed1)
{
    float rand1 = rand(seed + seed1);
    float rand2 = rand(seed + seed1 + float2(1, 1));
    float rand3 = rand(seed + seed1 + float2(2, 2));

    return float3(rand1, rand2, rand3);
}

float Ward2(float3 L, float3 N, float3 V,float3 tangentVS)
{
    float alphaX = _wbRoughness.x;
    float alphaY =  _wbRoughness.y;
    float ro = 0.045;

    float NdotV = dot(N, V);
    float NdotL = dot(N , L);
    float3 halfV = normalize(L + V);

    // vectors T, B same as X, Y in the equation
    float3 tangent = float3(0, 0, 0);
    float3 binormal = float3(0, 0, 0);

    // we can calc tangent vector in many ways(or store in texture), it just has to be perpendicular to the normal
    // tangent = cross(N, float3(0.5, 0.0, 1.0));
    // tangent = normalize(tangent);
    // binormal = cross(N, tangent);
    // binormal = normalize(binormal);
    tangent = tangentVS;
    binormal = cross(N, tangent);

    float HdotT = dot(halfV , tangent);
    float HdotB = dot(halfV , binormal);
    float HdotN = dot(halfV, N);

    if (NdotL <= 0.0 || NdotV <= 0.0)
    {
        return 0;
    }

    float specularFactor = 0;
    float lightIntensity = 1;
    float3 diffuseFactor = lightIntensity * (N * L);

    float a = sqrt(max(0.0, ro * NdotL / NdotV));
    float b = 1 / (4 * 3.14159 * alphaX * alphaY);
    b = max(0.0, b * NdotL);

    float t1 = HdotT / alphaX;
    float t2 = HdotB / alphaY;

    float term = -2.0 *
    ((t1 * t1 + t2 * t2)
    / (1 + HdotN));
    float e = 2.71828;
    float c = pow(e, term);

    // combine to get the final spec factor
    return lightIntensity * a * b * c;
}
 

float3 glintFade(float3 n_view_dir, float noise_dense, float grid_sparkle_dense, float adjust_sparkle_size,
                 float inoise, float floorLogPlus,
                 float3 vObjPos, float3 vNormal, float3 vViewVec,
                 bool with_anisotropy,
                 float i_noise_amount,
                 float i_view_amount)
{
    // Expanding the distance range, Logarithm Distribution
    float zBuf = length(vViewVec);
    float z_exp = log2(0.3 * zBuf + 3.0f) / 0.37851162325f;
    float floorlog = floor(z_exp);
    float level_zBuf = 0.1f * pow(1.3f, floorlog) - 0.2f;
    float level = 0.12f / level_zBuf;
    grid_sparkle_dense *= level;
    noise_dense *= level;

    // Warping the view vector
    float3 w_view_dir = n_view_dir * level_zBuf;
    w_view_dir = sign(w_view_dir) * frac(abs(w_view_dir));


    float3 randomPosition = randomVec3(vObjPos.xy, inoise);

    // Consider the view direction
    float3 pos_with_view = grid_sparkle_dense * vObjPos + i_view_amount * normalize(w_view_dir+randomPosition);

    // Generate the grid
    float3 grid_index = floor(pos_with_view);
    float3 grid_offset = pos_with_view - grid_index;
    float grid_length = 1.0f / grid_sparkle_dense;
    float3 grid_center = grid_index * grid_length;
    //add random position too
    grid_center += randomPosition;

    //TODO add to cnoise also scale-better way
    // Jitter the grid center
    float jitter_noisy = i_noise_amount * cnoise(noise_dense * grid_center*_wbJitterScale);

    float3 jitter_grid = float3(jitter_noisy, jitter_noisy, jitter_noisy);
    jitter_grid = 0.5f * frac(jitter_grid + 0.5f) - float3(0.75f, 0.75f, 0.75f);
    float3 new_offset = grid_offset + jitter_grid;

    // Anisotropy
    float dotvn = dot(vViewVec, vNormal);
    float3 large_dir = n_view_dir - (dotvn * vNormal);

    if (with_anisotropy)
    {
        new_offset += (abs(dotvn) - 1.0f) * dot(new_offset, large_dir) * large_dir / dot(large_dir, large_dir);
    }

    // Compute the brightness of the sparkle according to the offset
    float l2 = dot(new_offset, new_offset);
    float m_ss = 1.0f - adjust_sparkle_size;
    float glittering = 0.0f;

    if (m_ss > l2)
    {
        float lend = ((1.0f - l2) - adjust_sparkle_size) / (1.0f - adjust_sparkle_size);
        glittering = 20.0f * lend;
    }

    return float3(glittering, glittering, glittering);
}

float3 calcGrid(float newSparkle_size, float newSparkle_density, float inoise,
                float3 vViewVec, float i_noise_density,
                float3 vObjPos, float3 vNormal, bool with_anisotropy, float i_noise_amount, float i_view_amount)
{
    float3 n_view_dir = normalize(vViewVec);

    float noise_dense = i_noise_density;
    float grid_sparkle_dense = newSparkle_density * 15.0f;
    float adjust_sparkle_size = 1.0f - 0.2f * newSparkle_size * newSparkle_density * newSparkle_density;

    // Middle level
    float level1 = 0.0f;
    // Level below
    float level0 = -1.0f;
    float level2 = 1.0f;

    /*
        float3 n_view_dir, float noise_dense, float grid_sparkle_dense, float adjust_sparkle_size,
                         float inoise, float floorLogPlus,
                         float3 vObjPos,float3 vNormal,float3 vViewVec,
        bool with_anisotropy,
         float i_noise_amount,
         float i_view_amount
    */

    float3 resultC = glintFade(n_view_dir, noise_dense, grid_sparkle_dense, adjust_sparkle_size, inoise, level0,
                               vObjPos, vNormal, vViewVec, with_anisotropy, i_noise_amount, i_view_amount) +
        glintFade(n_view_dir, noise_dense, grid_sparkle_dense, adjust_sparkle_size, inoise, level1,
                  vObjPos, vNormal, vViewVec, with_anisotropy, i_noise_amount, i_view_amount) +
        glintFade(n_view_dir, noise_dense, grid_sparkle_dense, adjust_sparkle_size, inoise, level2,
                  vObjPos, vNormal, vViewVec, with_anisotropy, i_noise_amount, i_view_amount);

    return resultC / 3.0f;
}


float3 wangGlints(float3 vObjPos, float3 vNormal, float3 lightPos, float3 vViewVec,float3 tangentVS, float4 vlarge_dir,
                  bool with_anisotropy,
                  float i_sparkle_size,
                  float i_sparkle_density,
                  float i_noise_density,
                  float i_noise_amount,
                  float i_view_amount
)
{
    // Flip the z for OpenGL
    float3 ldir = normalize(lightPos.xyz - vObjPos);
    float3 n_view_dir = normalize(vViewVec);
    // test the noise pattern
    //float test = cnoise(vObjPos);
    //return float3(test,test,test);

    float3 glittering = float3(0.0f, 0.0f, 0.0f);

    //TODO loops
    UNITY_LOOP for (int i = 1; i < _wbGridAmmount; i++)
    {
        glittering += calcGrid(i_sparkle_size, i_sparkle_density, i + i / 4.0f,
                               vViewVec, i_noise_density,
                               vObjPos, vNormal, with_anisotropy, i_noise_amount, i_view_amount);
    }

    //float3 reflectDir = reflect(ldir, vNormal);
    //float spec = pow(max(dot(n_view_dir, reflectDir), 0.0f), 1.0f);
    //TODO is it minus?
    float spec2 = Ward2(ldir,  vNormal, -n_view_dir,tangentVS);

    //float3 FragColor = base.rgb * diffuse + 0.5f * specular + glitterStrength * glittering.rrr * specular;

    return glittering*spec2;
}


#endif
