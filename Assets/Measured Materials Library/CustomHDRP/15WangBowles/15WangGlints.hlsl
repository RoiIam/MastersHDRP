#ifndef __GLINTS15__
#define __GLINTS15__

#ifndef LAYERED_LIT_SHADER
#define "LitProperties.hlsl"
#endif

//same as ZK is used
/*float hash(float n)
{
    return frac(sin(fmod(n, 3.14)) * 753.5453123);
}*/

float cnoise(float3 inp)
{
    return 0.0;
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
                 float3 vObjPos,float3 vNormal,float3 vViewVec,
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

    float3 jitter_grid = float3(jitter_noisy,jitter_noisy,jitter_noisy);
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

    return float3(glittering,glittering, 1.0f);
}

float3 calcGrid(float newSparkle_size, float newSparkle_density, float inoise,
    float3 vViewVec,float i_noise_density,
    float3 vObjPos,float3 vNormal,bool with_anisotropy,float i_noise_amount,float i_view_amount)
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
    vObjPos, vNormal, vViewVec,with_anisotropy,i_noise_amount,i_view_amount) +
                     glintFade(n_view_dir, noise_dense, grid_sparkle_dense, adjust_sparkle_size, inoise, level1,
                          vObjPos, vNormal, vViewVec,with_anisotropy,i_noise_amount,i_view_amount) +
                     glintFade(n_view_dir, noise_dense, grid_sparkle_dense, adjust_sparkle_size, inoise, level2,
                          vObjPos, vNormal, vViewVec,with_anisotropy,i_noise_amount,i_view_amount);
                     
    return resultC / 3.0f;
}



float3 wangGlints(float3 vObjPos,float3 vNormal,float3 lightPos,float3 vViewVec,float4 vlarge_dir,
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

    
    float3 glittering = float3(0.0f, 0.0f, 1.0f);

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