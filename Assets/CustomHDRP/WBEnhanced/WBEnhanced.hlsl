#include <HLSLSupport.cginc>
#ifndef __GLINTSWBE__
#define __GLINTSWBE__
#include "PerlinNoiseLite.hlsl"
#ifndef LAYERED_LIT_SHADER
#define "LitProperties.hlsl"
#endif


/*float cnoise(float3 inp)
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
*/
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


float3 WBEnhancedGlints(float3 vObjPos, float3 vNormal, float3 lightPos, float3 vViewVec,float3 tangentVS, float4 vlarge_dir,
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
