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

    //Shader error in 'HDRP/CustomLit': 'tex3D': no matching 2 parameter intrinsic function;
    //Possible intrinsic functions are: tex3D(sampler3D, float3|half3|min10float3|min16float3) tex3D(sampler3D, float3|half3|min10float3|min16float3, float3|half3|min10float3|min16float3, float3|half3|min10float3|min16float3) at Assets/CustomHDRP/15WangBowles/15WangGlints.hlsl(16) (on d3d11)
}
//neopoznam cnoise
//nepoznam vViewVec, vObjPos, vNormal, lightPos, color, glitterStrength
/*
uniform bool with_anisotropy;//with the anisotropy or not
uniform float i_sparkle_size; //sparkle size
uniform float i_sparkle_density;//sparkle density
uniform float i_noise_density;//the noise density

uniform float i_noise_amount;
uniform float i_view_amount;
*/

float3 glintFade(float3 n_view_dir, float noise_dense, float grid_sparkle_dense, float adjust_sparkle_size,
                 float inoise, float floorLogPlus,
                 float3 vObjPos, float3 vNormal, float3 vViewVec,
                 bool with_anisotropy,
                 float i_noise_amount,
                 float i_view_amount)
{
    // Expanding the distance range, Logarithm Distribution
    float zBuf = length(vViewVec);
    float z_exp = log2(0.3 * zBuf + 2.0f) / 0.37851162325f;
    float floorlog = floor(z_exp);
    float level_zBuf = 0.1f * pow(1.3f, floorlog + floorLogPlus) - 0.2f;
    float level = 0.12f / level_zBuf;
    grid_sparkle_dense *= level;
    noise_dense *= level;

    // Warping the view vector
    float3 w_view_dir = n_view_dir * level_zBuf;
    w_view_dir = sign(w_view_dir) * frac(abs(w_view_dir));

    float3 a = frac(vObjPos * inoise);
    float3 vObjPos2 = float3(vObjPos.x + a.x, vObjPos.y + a.y, vObjPos.z + a.z);

    // Consider the view direction
    float3 pos_with_view = grid_sparkle_dense * vObjPos2 + i_view_amount * normalize(w_view_dir);

    // Generate the grid
    float3 grid_index = floor(pos_with_view);
    float3 grid_offset = pos_with_view - grid_index;
    float grid_length = 1.0f / grid_sparkle_dense;
    float3 grid_center = grid_index * grid_length;

    // Jitter the grid center
    float jitter_noisy = i_noise_amount * cnoise(noise_dense * grid_center);

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


float3 wangGlints(float3 vObjPos, float3 vNormal, float3 lightPos, float3 vViewVec, float4 vlarge_dir,
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
    float test = cnoise(vObjPos);
    return float3(test,test,test);

    float3 glittering = float3(0.0f, 0.0f, 0.0f);

    for (int i = 1; i < 3; i++)
    {
        glittering += calcGrid(i_sparkle_size, i_sparkle_density, i + i / 4.0f,
                               vViewVec, i_noise_density,
                               vObjPos, vNormal, with_anisotropy, i_noise_amount, i_view_amount);
    }

    //float3 reflectDir = reflect(ldir, vNormal);
    //float spec = pow(max(dot(n_view_dir, reflectDir), 0.0f), 1.0f);

    //float3 FragColor = base.rgb * diffuse + 0.5f * specular + glitterStrength * glittering.rrr * specular;

    return glittering;
}


#endif
