#ifndef __16GLINTS__
#define __16GLINTS__

// Copyright (c) 2016, NVIDIA CORPORATION.  All rights reserved.
// Created by Tobias Zirr (KIT, NVIDIA) and Anton Kaplanyan (NVIDIA)
// License Creative Commons Attribution 3.0 Unported License.

// For a working self-contained example, find shadertoy at:
// https://www.shadertoy.com/view/ldVGRh

// Example code for the paper "Real-time Rendering of Procedural Multiscale Materials",
// Tobias Zirr (NVIDIA / KIT), Anton Kaplanyan (NVIDIA),
// in ACM SIGGRAPH Symposium on Interactive 3D Graphics and Games, February 2016.
// More info on https://research.nvidia.com/publication/real-time-rendering-procedural-multiscale-materials

//----------------------------------------------------------------------
// math
float compMax(float2 v) { return max(v.x, v.y); }
float maxNrm(float2 v) { return compMax(abs(v)); }
//tu moze byt problem s mod vs fmod
//float hash( float n ) { return fract(sin(mod(n, 3.14))*753.5453123); }
//vec2 hash2( float n ) { return vec2(hash(n), hash(1.1 + n)); }
float hash( float n ) { return frac(sin(fmod(n, 3.14))*753.5453123); }
float2 hash2( float n ) { return float2(hash(n), hash(1.1 + n)); }
float2x2 inverse2(float2x2 m)
{
    return float2x2(m[1][1], -m[0][1], -m[1][0], m[0][0]) / (m[0][0] * m[1][1] - m[0][1] * m[1][0]);
    /*float det = m[0][0]* m[1][1] - m[0][1] * m[1][0];
    float2x2 inverseMatrix;
    inverseMatrix[0][0] = m[1][1] / det;
    inverseMatrix[0][1] = -m[0][1] / det;
    inverseMatrix[1][0] = -m[1][0] / det;
    inverseMatrix[1][1]= m[0][0] / det;

    return inverseMatrix;*/
}

// some microfacet BSDF geometry factors
// (divided by NoL * NoV b/c cancelled out w/ microfacet BSDF)
float geometryFactor(float NoL, float NoV, float2 roughness)
{
    float a2 = roughness.x * roughness.y;
    NoL = abs(NoL);
    NoV = abs(NoV);

    float G_V = NoV + sqrt((NoV - NoV * a2) * NoV + a2);
    float G_L = NoL + sqrt((NoL - NoL * a2) * NoL + a2);
    return 1.0 / (G_V * G_L);
}

//was ifloat ifloat2 multilevelGridIdx(ifloat2  idx) i mean ivec
int2 multilevelGridIdx(int2 idx)
{
    //probably firstbitlow is the hlsl equivalent of findLSB
    //    return idx >> findLSB(idx);
    //idx = firstbitlow(idx);
    return (idx >> firstbitlow(idx));
    //return (idx >> firstbithigh(idx));
}

//----------------------------------------------------------------------

// stable binomial 'random' numbers: interpolate between result for
// two closest binomial distributions where log_{.9}(p_i) integers
float binomial_interp(float u, float N, float p)
{
    if (p >= 1.0)
        return N;
    else if (p <= 1e-30)
        return 0.0;

    // convert to distribution on ints while retaining expected value
    float cN = ceil(N);
    int iN = int(cN);
    p = p * (N / cN);
    N = cN;

    // round p to nearest powers of .9 (more stability)
    float pQ = 0.9;
    float pQef = log2(p) / log2(pQ);
    float p2 = exp2(floor(pQef) * log2(pQ));
    float p1 = p2 * pQ;
    float2 ps = float2(p1, p2);

    // compute the two corresponding binomials in parallel
    float2 pm = pow(1.0 - ps, float2(N,N));
    float2 cp = pm;
    float2 r = float2(N,N);

    float i = 0.0;
    // this should actually be < N, no dynamic loops in ShaderToy right now
    for (int ii = 0; ii <= 17; ++ii)
    {
        if (u < cp.x)
            r.x = min(i, r.x);
        if (u < cp.y)
        {
            r.y = i;
            break;
        }
        // fast path
        if (ii > 16)
        {
            float C = 1.0 / (1.0 - pow(p, N - i - 1.0));
            float2 U = (u - cp) / (1.0 - cp);
            float2 A = (i + 1.0 + log2(1.0 - U / C) / log2(p));
            r = min(A, r);
            break;
        }

        i += 1.0;
        pm /= 1.0 - ps;
        pm *= (N + 1.0 - i) / i;
        pm *= ps;
        cp += pm;
    }

    // interpolate between the two binomials according to log p (akin to mip interpolation)
    return lerp(r.y, r.x, frac(pQef)); //was lerp-mix and fract
}

// resort to gaussian distribution for larger N*p
float approx_binomial(float u, float N, float p)
{
    if (p * N > 5.0)
    {
        float e = N * p;
        float v = N * p * max(1.0 - p, 0.0);
        float std = sqrt(v);
        float k = e + erfinv(lerp(-.999999, 0.999999, u)) * std;//was mix
        return min(max(k, 0.0), N);
    }
    else
        return binomial_interp(u, N, p);
}

//----------------------------------------------------------------------

float3 glints(float2 texCO, float2 duvdx, float2 duvdy,
    float3x3 ctf, float3 lig, float3 nor, float3 view,
    float2 roughness, float2 microRoughness,
    float searchConeAngle, float variation, float dynamicRange, float density)
{
    float3 col = float3(0,0,0);

    // Compute pixel footprint in texture space, step size w.r.t. anisotropy of the footprint
    float2x2 uvToPx = inverse2(float2x2(duvdx, duvdy));
    float2 uvPP = 1.0 / float2(maxNrm(uvToPx[0]), maxNrm(uvToPx[1]));

    // material
    float2 mesoRoughness = sqrt(max(roughness * roughness - microRoughness * microRoughness,
        float2(1.e-12,1.e-12)));
    // optimizer fail, max 0 removed

    // Anisotropic compression of the grid
    float2 texAnisotropy = float2(min(mesoRoughness.x / mesoRoughness.y, 1.0)
                                  , min(mesoRoughness.y / mesoRoughness.x, 1.0));

    // Compute half vector (w.r.t. dir light)
    //normalize((vertPos-lightPos) + (vertPos-camPos))
    float3 hvW = normalize(lig + view);
    
    //float3 hv = normalize(mul(hvW,ctf)); //was just *
    float3 hv = normalize(mul(ctf,hvW)); 
    float2 h = hv.xy / hv.z;
    float2 h2 = 0.75 * hv.xy / (hv.z + 1.0);
    // Anisotropic compression of the slope-domain grid
    h2 *= texAnisotropy;

    // Compute the Gaussian probability of encountering a glint within a given finite cone
    float2 hppRScaled = h / roughness;
    float pmf = (microRoughness.x * microRoughness.y) / (roughness.x * roughness.y)
        * exp(-dot(hppRScaled, hppRScaled)); // planeplane h
    pmf /= hv.z * hv.z * hv.z * hv.z; // projected h
    //  pmf /= dot(lig, nor) * dot(view, nor); // projected area, cancelled out by parts of G, ...
    float pmfToBRDF = 1.0 / (3.14159 * microRoughness.x * microRoughness.y);
    pmfToBRDF /= 4.0; // solid angle o
    pmfToBRDF *= geometryFactor(dot(lig, nor), dot(view, nor), roughness); // ... see "geometryFactor"
    // phenomenological: larger cones flatten distribution
    float searchAreaProj = searchConeAngle * searchConeAngle / (4.0 * dot(lig, hvW) * hv.z); // * PI
    pmf = lerp(pmf, 1.0, clamp(searchAreaProj, 0.0, 1.0)); // searchAreaProj / PI //lerp no mix
    pmf = min(pmf, 1.0);

    // noise coordinate (decorrelate interleaved grid)
    texCO += float2(100.0,100.0);
    // apply anisotropy _after_ footprint estimation
    texCO *= texAnisotropy;

    // Compute AABB of pixel in texture space
    float2 uvAACB = max(abs(duvdx), abs(duvdy)) * texAnisotropy; // border center box
    float2 uvb = texCO - 0.5 * uvAACB;
    float2 uve = texCO + 0.5 * uvAACB;

    float2 uvLongAxis = uvAACB.x > uvAACB.y ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 uvShortAxis = 1.0 - uvLongAxis;

    // Compute skew correction to snap axis-aligned line sampling back to longer anisotropic pixel axis in texture space
    // float2 skewCorr2 = -mul(uvToPx , uvLongAxis) / mul(uvToPx , uvShortAxis);
    // float skewCorr =( abs(mul(uvToPx,uvShortAxis).x) > abs(mul(uvToPx,uvShortAxis).y) )?
    //                       skewCorr2.x : skewCorr2.y;
    
    float2 skewCorr2 = -mul(uvLongAxis,uvToPx) / mul(uvShortAxis,uvToPx);
    float skewCorr = abs(mul(uvShortAxis,uvToPx).x) > abs(mul(uvShortAxis,uvToPx).y) ?
                         skewCorr2.x : skewCorr2.y;
    
    skewCorr *= dot(texAnisotropy, uvShortAxis) / dot(texAnisotropy, uvLongAxis);

    float isoUVPP = dot(uvPP, uvShortAxis);
    // limit anisotropy
    isoUVPP = max(isoUVPP, dot(uvAACB, uvLongAxis) / 16.0);

    // Two virtual grid mips: current and next
    float fracMip = log2(isoUVPP);
    float lowerMip = floor(fracMip);
    float uvPerLowerC = exp2(lowerMip);

    // Current mip level and cell size
    float uvPC = uvPerLowerC;
    float mip = lowerMip;

    int iter = 0;
    int iterThreshold = 150;

    for (int i = 0; i < 2; ++i)
    {
        float mipWeight = 1.0 - abs(mip - fracMip);

        float2 uvbg = min(uvb + 0.5 * uvPC, texCO);
        float2 uveg = max(uve - 0.5 * uvPC, texCO);

        // Snapped uvs of the cell centers
        float2 uvbi = floor(uvbg / uvPC);
        float2 uvbs = uvbi * uvPC;
        float2 uveo = uveg + uvPC - uvbs;

        // Resulting compositing values for a current layer
        float weight = 0.0;
        float3 reflection = float3(0.0,0.0,0.0);

        // March along the long axis
        float2 uvo = float2(0.0,0.0), uv = uvbs, uvio = float2(0.0,0.0), uvi = uvbi;
        for (int iter1 = 0; iter1 < 18; ++iter1) // horrible WebGL-compatible static for loop
        {
            // for cond:
            if (dot(uvo, uvLongAxis) < dot(uveo, uvLongAxis) && iter < iterThreshold)
            {
                
            }
            else
                break;

            // Snap samples to long anisotropic pixel axis
            float uvShortCenter = dot(texCO, uvShortAxis) + skewCorr * dot(uv - texCO, uvLongAxis);

            // Snapped uvs of the cell center
            uvi += (floor(uvShortCenter / uvPC) - dot(uvi, uvShortAxis)) * uvShortAxis;
            uv = uvi * uvPC;
            float uvShortEnd = uvShortCenter + uvPC;

            float2 uvb2 = uvbg * uvLongAxis + uvShortCenter * uvShortAxis;
            float2 uve2 = uveg * uvLongAxis + uvShortCenter * uvShortAxis;

            // March along the shorter axis
            for (int iter2 = 0; iter2 < 4; ++iter2) // horrible WebGL-compatible static for loop
            {
                // for cond:
                if (dot(uv, uvShortAxis) < uvShortEnd && iter < iterThreshold)
                {
                    
                }
                else
                    break;

                // Compute interleaved cell index
                //ifloat2 cellIdx = ifloat2(uvi + float2(.5));
                int2 cellIdx = int2(uvi + float2(0.5,0.5));
                cellIdx = multilevelGridIdx(cellIdx);

                // Randomize a glint based on a texture-space id of current grid cell
                float2 u2 = hash2(float((cellIdx.x + 1549 * cellIdx.y)));
                // Compute index of the cone
                float2 hg = h2 / (microRoughness + searchConeAngle);
                float2 hs = floor(hg + u2) + u2 * 533.0; // discrete cone index in paraboloid hv grid
                //ifloat2 coneIdx = ifloat2(hs);
                int2 coneIdx = int2(hs);

                // Randomize glint sizes within this layer
                float var_u = hash(float((cellIdx.x + cellIdx.y * 763 + coneIdx.x + coneIdx.y * 577)));
                float mls = 1.0 + variation * erfinv(lerp(-0.999, 0.999, var_u)); //was lerp
                if (mls <= 0.0) mls = frac(mls) / (1.0 - mls);//was fract
                mls = max(mls, 1.e-12);

                // Bilinear interpolation using coverage made by areas of two rects
                float2 mino = max(1.0 - max((uvb2 - uv) / uvPC, 0.0), 0.0);
                float2 maxo = max(1.0 - max((uv - uve2) / uvPC, 0.0), 0.0);
                float2 multo = mino * maxo;
                float coverageWeight = multo.x * multo.y;

                float cellArea = uvPC * uvPC;
                // Expected number of glints 
                float eN = density * cellArea;
                float sN = max(eN * mls, min(1.0, eN));
                eN = eN * mls;

                // Sample actually found number of glints
                float u = hash(float(coneIdx.x + coneIdx.y * 697));
                float lN = approx_binomial(u, sN, pmf);
                #if 0
                // Colored glints
                if (false) {
                    float3 glintColor = hue_colormap(frac(u + u2.y)); //was fract
                    glintColor = lerp(float3(1.0,1.0,1.0), glintColor, 1.0 / sqrt(max(lN, 1.0)));//was mix
                }
                #endif
                // Ratio of glinting vs. expected number of microfacets
                float ratio = lN / eN;

                // limit dynamic range (snow more or less unlimited)
                ratio = min(ratio, dynamicRange * pmf);

                // convert to reflectance
                ratio *= pmfToBRDF;
                #if 0
                // Grid
                reflection += float3(u,u,u);
                weight += coverageWeight;
                #else
                // Accumulate results
                reflection += coverageWeight * ratio;
                weight += coverageWeight;
                #endif

                // for incr:
                uv += uvPC * uvShortAxis, uvi += uvShortAxis, ++iter;
            }

            // for incr:
            uvo += uvPC * uvLongAxis, uv = uvbs + uvo,
            uvio += uvLongAxis, uvi = uvbi + uvio;
        }

        #ifdef DEBUG
        // Normalization
        if (weight < 1.e-15) {
            col = float3(0.0, 1.0, 1.0);
            break;
        }
        #endif

        reflection = reflection / weight;

        // Compositing of two layers
        col += mipWeight * reflection;

        // for incr:
        uvPC *= 2.0, mip += 1.0;
    }

    return col;
}


#endif
