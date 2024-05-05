#ifndef __GLINTS15__
#define __GLINTS15__

#ifndef LAYERED_LIT_SHADER
#define "LitProperties.hlsl"
#endif
#include "../WBEnhanced/PerlinNoiseLite.hlsl"

float cnoise(float3 inp)
{
    //if(_wbUsePerlinTexture)
    //    return    UNITY_SAMPLE_TEX3D_SAMPLER(_wbPerlinTexture,_wbPerlinTexture, inp);
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


float3 wangGlints(float3 vObjPos, float3 vNormal, float3 lightPos, float3 vViewVec, float3 tangentVS, float4 vlarge_dir,
                  bool with_anisotropy,
                  float i_sparkle_size,
                  float i_sparkle_density,
                  float i_noise_density,
                  float i_noise_amount,
                  float i_view_amount
)
{
    float3 ldir = normalize(lightPos.xyz - vObjPos);
    float3 n_view_dir = normalize(vViewVec);

    float grid_sparkle_dense = i_sparkle_density * 15.0;
    float adjust_sparkle_size = 1.0 - 0.2 * i_sparkle_size * i_sparkle_density * i_sparkle_density;

    float zBuf = length(vViewVec);
    float z_exp = log2(0.3 * zBuf + 3.0) / 0.37851162325;
    float floorlog = floor(z_exp);
    float level_zBuf = 0.1 * pow(1.3, floorlog) - 0.2;
    float level = 0.12 / level_zBuf;
    grid_sparkle_dense *= level;
    i_noise_density *= level;

    float3 w_view_dir = n_view_dir * level_zBuf;
    w_view_dir = sign(w_view_dir) * frac(abs(w_view_dir));

    float3 pos_with_view = grid_sparkle_dense * vObjPos + i_view_amount * normalize(w_view_dir);

    float3 grid_index = floor(pos_with_view);
    float3 grid_offset = pos_with_view - grid_index;
    float grid_length = 1.0 / grid_sparkle_dense;
    float3 grid_center = grid_index * grid_length;

    float jitter_noisy = i_noise_amount * cnoise(i_noise_density * grid_center);
    float3 jitter_grid = float3(jitter_noisy, jitter_noisy, jitter_noisy);
    jitter_grid = 0.5 * frac(jitter_grid + 0.5) - float3(0.75, 0.75, 0.75);
    float3 new_offset = grid_offset + jitter_grid;

    float dotvn = dot(vViewVec, -vNormal);
    float3 large_dir = n_view_dir - (dotvn * -vNormal);

    if (with_anisotropy)
        new_offset += (abs(dotvn) - 1.0) * dot(new_offset, large_dir) * large_dir / dot(large_dir, large_dir);

    float l2 = dot(new_offset, new_offset);
    float m_ss = 1.0 - adjust_sparkle_size;
    float glittering = 0.0;
    if (m_ss > l2)
    {
        float lend = ((1.0 - l2) - adjust_sparkle_size) / (1.0 - adjust_sparkle_size);
        glittering = 20.0 * lend;
    }

    return float3(glittering, glittering, glittering);
}


#endif
