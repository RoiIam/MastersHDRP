//modified Method of Beibei Wang and Huw Boles from the paper "A Robust and Flexible Real-Time Sparkle Effect"

#include <HLSLSupport.cginc>
#ifndef __GLINTSWBE__
#define __GLINTSWBE__
#include "PerlinNoiseLite.hlsl"
#ifndef LAYERED_LIT_SHADER
#define "LitProperties.hlsl"
#endif


float WardAniso(float3 L, float3 N, float3 V, float3 tangentVS)
{
    float alphaX = _wbRoughness.x;
    float alphaY = _wbRoughness.y;
    float ro = 0.045; //TODO expose this

    float NdotV = dot(N, V);
    float NdotL = dot(N, L);
    float3 halfV = normalize(L + V);

    float3 binormal = cross(N, tangentVS);

    float HdotT = dot(halfV, tangentVS);
    float HdotB = dot(halfV, binormal);
    float HdotN = dot(halfV, N);

    if (NdotL <= 0.0 || NdotV <= 0.0)
    {
        return 0;
    }

    float a = sqrt(max(0.0, ro * NdotL / NdotV));
    float b = 1 / (4 * 3.14159 * alphaX * alphaY);
    b = max(0.0, b * NdotL);

    float t1 = HdotT / alphaX;
    float t2 = HdotB / alphaY;

    float term = -2.0 * ((t1 * t1 + t2 * t2)
        / (1 + HdotN));
    float e = 2.71828;
    float c = pow(e, term);

    // combine to get the final spec factor
    return a * b * c;
}

float CalculateLevelBasedOnDistance(float3 ViewVec)
{
    float zBuf = length(ViewVec);
    float z_exp = log2(0.3 * zBuf + 3.0f) / 0.37851162325f;
    float floorlog = floor(z_exp);
    return 0.1f * pow(1.3f, floorlog) - 0.2f;
}

float3 GenerateGridCenter(float3 gridIndex, float sparkleGridDensity, float3 randPos)
{
    float grid_length = 1.0f / sparkleGridDensity;
    //add random position too
    return gridIndex * grid_length + randPos;
}

float3 JitterGrid(float noiseAmount, float noise)
{
    float jitter_noisy = noiseAmount * noise;

    float3 jitter_grid = float3(jitter_noisy, jitter_noisy, jitter_noisy);
    jitter_grid = 0.5f * frac(jitter_grid + 0.5f) - float3(0.75f, 0.75f, 0.75f);

    return jitter_grid;
}

float CalculateFinalContribution(float3 newGridOffset, float newSparkleSize)
{
    // Compute the brightness of the sparkle according to the offset
    float l2 = dot(newGridOffset, newGridOffset);
    float m_ss = 1.0f - newSparkleSize;

    if (m_ss > l2)
    {
        float lend = ((1.0f - l2) - newSparkleSize) / (1.0f - newSparkleSize);
        return 20.0f * lend;
    }

    return 0;
}

float3 GlintFade(WBEStruct wbeStruct, float3 viewDir, float noiseDensity, float sparkleGridDensity,
                 float newSparkleSize,
                 float inoise, float floorLogPlus,
                 float3 objPos, float3 normal, float3 viewVec)
{
    float levelZBuffer = CalculateLevelBasedOnDistance(viewVec);
    float level = (0.12f + 0.5 * floorLogPlus) / (levelZBuffer);

    sparkleGridDensity *= level;
    noiseDensity *= level;

    // Warp the view vector
    float3 warp = viewDir * levelZBuffer;
    float3 warpedViewDir = sign(warp) * frac(abs(warp));

    float3 randomPosition = randomVec3(objPos.xy, inoise);
    float3 positionPlusView = objPos * sparkleGridDensity + wbeStruct.viewAmount * normalize(
        warpedViewDir + randomPosition);

    float3 gridIndex = floor(positionPlusView);
    float3 gridCenter = GenerateGridCenter(gridIndex, sparkleGridDensity, randomPosition);
    float3 newGridOffset = positionPlusView - gridIndex;

    // Jitter the grid center
    float noise = PerlinNoise(noiseDensity * gridCenter * _wbJitterScale);
    newGridOffset += JitterGrid(wbeStruct.noiseAmount, noise);


    float dotvn = dot(viewVec, normal);
    float3 large_dir = viewDir - (dotvn * normal);
    if (wbeStruct.useAnisotropy)
    {
        newGridOffset += (abs(dotvn) - 1.0f) * dot(newGridOffset, large_dir) * large_dir / dot(large_dir, large_dir);
    }

    float glittering = CalculateFinalContribution(newGridOffset, newSparkleSize);

    return float3(glittering, glittering, glittering);
}

float3 CalcGrid(WBEStruct wbeStruct, float3 vViewVec, float3 vObjPos, float3 vNormal, float1 inoise)
{
    float3 n_view_dir = normalize(vViewVec);

    float noiseDensity = wbeStruct.noiseDensity;
    float sparkleDensity = wbeStruct.sparkleDensity * 15.0f;
    float newSparkleSize = 1.0f - 0.2f * wbeStruct.sparkleSize * wbeStruct.sparkleDensity * wbeStruct.sparkleDensity;
    // Middle level
    float level1 = 0.0f;
    // Level below
    float level0 = -1.0f;
    float level2 = 1.0f;


    float3 resultC = GlintFade(wbeStruct, n_view_dir, noiseDensity, sparkleDensity, newSparkleSize, inoise,
                               level1,
                               vObjPos, vNormal, vViewVec);
    if (_wbUseScales)
        resultC +=
            GlintFade(wbeStruct, n_view_dir, noiseDensity, sparkleDensity, newSparkleSize, inoise,
                      level0,
                      vObjPos, vNormal, vViewVec) +
            GlintFade(wbeStruct, n_view_dir, noiseDensity, sparkleDensity, newSparkleSize, inoise,
                      level2,
                      vObjPos, vNormal, vViewVec);

    return resultC / 1.0f;
}


float3 WBEnhancedGlints(float3 vObjPos, float3 vNormal, float3 lightPos, float3 vViewVec, float3 tangentVS,
                        WBEStruct wbeStruct)

{
    float3 lightDir = normalize(lightPos.xyz - vObjPos);
    float3 n_view_dir = normalize(vViewVec);

    // test the noise pattern
    //float test = PerlinNoise(vObjPos);
    //return float3(test,test,test);

    float3 glittering = float3(0.0f, 0.0f, 0.0f);
    float specularity = WardAniso(lightDir, vNormal, -n_view_dir, tangentVS);

    //ignore calc if outside of area
    //if (spec2 > _NormalScale)
    {
        //TODO loops
        UNITY_LOOP for (int i = 1; i <= _wbGridAmount + 1; i++)
        {
            glittering += CalcGrid(wbeStruct, vViewVec, vObjPos, vNormal, i);
        }
    }

    return glittering * specularity;
}


#endif
