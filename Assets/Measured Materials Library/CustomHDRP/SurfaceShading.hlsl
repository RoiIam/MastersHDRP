// Continuation of LightEvaluation.hlsl.
// use #define MATERIAL_INCLUDE_TRANSMISSION to include thick transmittance evaluation
// use #define MATERIAL_INCLUDE_PRECOMPUTED_TRANSMISSION to apply pre-computed transmittance (or thin transmittance only)
// use #define OVERRIDE_SHOULD_EVALUATE_THICK_OBJECT_TRANSMISSION to provide a new version of ShouldEvaluateThickObjectTransmission
//-----------------------------------------------------------------------------
// Directional and punctual lights (infinitesimal solid angle)
//-----------------------------------------------------------------------------

#include <HLSLSupport.cginc>
#ifndef OVERRIDE_SHOULD_EVALUATE_THICK_OBJECT_TRANSMISSION
bool ShouldEvaluateThickObjectTransmission(float3 V, float3 L, PreLightData preLightData,
                                           BSDFData bsdfData, int shadowIndex)
{
#ifdef MATERIAL_INCLUDE_TRANSMISSION
    // Currently, we don't consider (NdotV < 0) as transmission.
    // TODO: ignore normal map? What about double sided-surfaces with one-sided normals?
    float NdotL = dot(bsdfData.normalWS, L);

    // If a material does not support transmission, it will never have this flag, and
    // the optimization pass of the compiler will remove all of the associated code.
    // However, this will take a lot more CPU time than doing the same thing using
    // the preprocessor.
    return HasFlag(bsdfData.materialFeatures, MATERIALFEATUREFLAGS_TRANSMISSION_MODE_THICK_OBJECT) &&
           (shadowIndex >= 0.0) && (NdotL < 0.0);
#else
    return false;
#endif
}
#endif

DirectLighting ShadeSurface_Infinitesimal(PreLightData preLightData, BSDFData bsdfData,
                                          float3 V, float3 L, float3 lightColor,
                                          float diffuseDimmer, float specularDimmer)
{
    DirectLighting lighting;
    ZERO_INITIALIZE(DirectLighting, lighting);

    if (Max3(lightColor.r, lightColor.g, lightColor.b) > 0)
    {
        CBSDF cbsdf = EvaluateBSDF(V, L, preLightData, bsdfData);

#if defined(MATERIAL_INCLUDE_TRANSMISSION) || defined(MATERIAL_INCLUDE_PRECOMPUTED_TRANSMISSION)
        float3 transmittance = bsdfData.transmittance;
#else
        float3 transmittance = float3(0.0, 0.0, 0.0);
#endif
        // If transmittance or the CBSDF's transmission components are known to be 0,
        // the optimization pass of the compiler will remove all of the associated code.
        // However, this will take a lot more CPU time than doing the same thing using
        // the preprocessor.
        lighting.diffuse  = (cbsdf.diffR + cbsdf.diffT * transmittance) * lightColor * diffuseDimmer;
        lighting.specular = (cbsdf.specR + cbsdf.specT * transmittance) * lightColor * specularDimmer;
    }

#ifdef DEBUG_DISPLAY
    if (_DebugLightingMode == DEBUGLIGHTINGMODE_LUX_METER)
    {
        // Only lighting, no BSDF.
        lighting.diffuse = lightColor * saturate(dot(bsdfData.normalWS, L));
    }
#endif

    return lighting;
}


//RCC nova metoda
DirectLighting ShadeSurface_Infinitesimal_Glints(PreLightData preLightData, BSDFData bsdfData,
                                          float3 V, float3 L, float3 lightColor,
                                          float diffuseDimmer, float specularDimmer)
{
    DirectLighting lighting;
    ZERO_INITIALIZE(DirectLighting, lighting);

    if (Max3(lightColor.r, lightColor.g, lightColor.b) > 0)
    {

        //tiez zmenene
        CBSDF cbsdf = EvaluateBSDF_Glints(V, L, preLightData, bsdfData);//spat do Lit.hlsl

        #if defined(MATERIAL_INCLUDE_TRANSMISSION) || defined(MATERIAL_INCLUDE_PRECOMPUTED_TRANSMISSION)
        float3 transmittance = bsdfData.transmittance;
        #else
        float3 transmittance = float3(0.0, 0.0, 0.0);
        #endif
        // If transmittance or the CBSDF's transmission components are known to be 0,
        // the optimization pass of the compiler will remove all of the associated code.
        // However, this will take a lot more CPU time than doing the same thing using
        // the preprocessor.
        lighting.diffuse  = (cbsdf.diffR + cbsdf.diffT * transmittance) * lightColor * diffuseDimmer;
        lighting.specular = (cbsdf.specR + cbsdf.specT * transmittance) * lightColor * specularDimmer;
    }

    #ifdef DEBUG_DISPLAY
    if (_DebugLightingMode == DEBUGLIGHTINGMODE_LUX_METER)
    {
        // Only lighting, no BSDF.
        lighting.diffuse = lightColor * saturate(dot(bsdfData.normalWS, L));
    }
    #endif

    return lighting;
}

//-----------------------------------------------------------------------------
// Directional lights
//-----------------------------------------------------------------------------

DirectLighting ShadeSurface_Directional(LightLoopContext lightLoopContext,
                                        PositionInputs posInput, BuiltinData builtinData,
                                        PreLightData preLightData, DirectionalLightData light,
                                        BSDFData bsdfData, float3 V)
{
    DirectLighting lighting;
    ZERO_INITIALIZE(DirectLighting, lighting);

    float3 L = -light.forward;

    // Is it worth evaluating the light?
    if ((light.lightDimmer > 0) && IsNonZeroBSDF(V, L, preLightData, bsdfData))
    {
        float4 lightColor = EvaluateLight_Directional(lightLoopContext, posInput, light);
        lightColor.rgb *= lightColor.a; // Composite

#ifdef MATERIAL_INCLUDE_TRANSMISSION
        if (ShouldEvaluateThickObjectTransmission(V, L, preLightData, bsdfData, light.shadowIndex))
        {
            // Transmission through thick objects does not support shadowing
            // from directional lights. It will use the 'baked' transmittance value.
            lightColor *= _DirectionalTransmissionMultiplier;
        }
        else
#endif
        {
            SHADOW_TYPE shadow = EvaluateShadow_Directional(lightLoopContext, posInput, light, builtinData, GetNormalForShadowBias(bsdfData));
            float NdotL  = dot(bsdfData.normalWS, L); // No microshadowing when facing away from light (use for thin transmission as well)
            shadow *= NdotL >= 0.0 ? ComputeMicroShadowing(GetAmbientOcclusionForMicroShadowing(bsdfData), NdotL, _MicroShadowOpacity) : 1.0;
            lightColor.rgb *= ComputeShadowColor(shadow, light.shadowTint, light.penumbraTint);

#ifdef LIGHT_EVALUATION_SPLINE_SHADOW_VISIBILITY_SAMPLE
            if ((light.shadowIndex >= 0))
            {
                bsdfData.splineVisibility = lightLoopContext.splineVisibility;
            }
            else
            {
                bsdfData.splineVisibility = -1;
            }
#endif
        }

        // Simulate a sphere/disk light with this hack.
        // Note that it is not correct with our precomputation of PartLambdaV
        // (means if we disable the optimization it will not have the
        // same result) but we don't care as it is a hack anyway.
        ClampRoughness(preLightData, bsdfData, light.minRoughness);

        lighting = ShadeSurface_Infinitesimal(preLightData, bsdfData, V, L, lightColor.rgb,
                                              light.diffuseDimmer, light.specularDimmer);
    }

    return lighting;
}

//-----------------------------------------------------------------------------
// Punctual lights
//-----------------------------------------------------------------------------

#ifdef MATERIAL_INCLUDE_TRANSMISSION
// Must be called after checking the results of ShouldEvaluateThickObjectTransmission().
float3 EvaluateTransmittance_Punctual(LightLoopContext lightLoopContext,
                                      PositionInputs posInput, BSDFData bsdfData,
                                      LightData light, float3 L, float4 distances)
{
    // Using the shadow map, compute the distance from the light to the back face of the object.
    // TODO: SHADOW BIAS.
    float distBackFaceToLight = GetPunctualShadowClosestDistance(lightLoopContext.shadowContext, s_linear_clamp_sampler,
                                                                 posInput.positionWS, light.shadowIndex, L, light.positionRWS,
                                                                 light.lightType == GPULIGHTTYPE_POINT);

    // Our subsurface scattering models use the semi-infinite planar slab assumption.
    // Therefore, we need to find the thickness along the normal.
    // Note: based on the artist's input, dependence on the NdotL has been disabled.
    float distFrontFaceToLight   = distances.x;
    float thicknessInUnits       = (distFrontFaceToLight - distBackFaceToLight) /* * -NdotL */;
    float metersPerUnit          = _WorldScalesAndFilterRadiiAndThicknessRemaps[bsdfData.diffusionProfileIndex].x;
    float thicknessInMeters      = thicknessInUnits * metersPerUnit;
    float thicknessInMillimeters = thicknessInMeters * MILLIMETERS_PER_METER;

    // We need to make sure it's not less than the baked thickness to minimize light leaking.
    float dt = max(0, thicknessInMillimeters - bsdfData.thickness);
    float3 S = _ShapeParamsAndMaxScatterDists[bsdfData.diffusionProfileIndex].rgb;

    float3 exp_13 = exp2(((LOG2_E * (-1.0/3.0)) * dt) * S); // Exp[-S * dt / 3]

    // Approximate the decrease of transmittance by e^(-1/3 * dt * S).
    return bsdfData.transmittance * exp_13;
}
#endif


int1 pyramidSize(int1 level)
{
    //Dictionary.NLevels
    int1 Dictionary_NLevels = 16;
    return int1(pow(2.0, float1(Dictionary_NLevels - 1 - level)));
}

//daj linky ako v povodom
float1 hashIQ(uint1 n)
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float1(n & 0x7fffffffU) / float1(0x7fffffffU);
}

float1 erfinv(float1 x)
{
    float1 w, p;
    w = -log((1.0 - x) * (1.0 + x));
    if (w < 5.000000)
    {
        w = w - 2.500000;
        p = 2.81022636e-08;
        p = 3.43273939e-07 + p * w;
        p = -3.5233877e-06 + p * w;
        p = -4.39150654e-06 + p * w;
        p = 0.00021858087 + p * w;
        p = -0.00125372503 + p * w;
        p = -0.00417768164 + p * w;
        p = 0.246640727 + p * w;
        p = 1.50140941 + p * w;
    }
    else
    {
        w = sqrt(w) - 3.000000;
        p = -0.000200214257;
        p = 0.000100950558 + p * w;
        p = 0.00134934322 + p * w;
        p = -0.00367342844 + p * w;
        p = 0.00573950773 + p * w;
        p = -0.0076224613 + p * w;
        p = 0.00943887047 + p * w;
        p = 1.00167406 + p * w;
        p = 2.83297682 + p * w;
    }
    return p * x;
}

float1 sampleNormalDistribution(float1 U, float1 mu, float1 sigma)
{
    float1 x = sigma * 1.414213f * erfinv(2.0f * U - 1.0f) + mu;
    return x;
}

float1 p22_beckmann_anisotropic(float1 x, float1 y, float1 alpha_x, float1 alpha_y)
{
    float1 m_pi = 3.141592;
    float1  m_i_sqrt_2 = 0.707106;
    float1 x_sqr = x * x;
    float1 y_sqr = y * y;
    float1 sigma_x = alpha_x * m_i_sqrt_2;
    float1 sigma_y = alpha_y * m_i_sqrt_2;
    float1 sigma_x_sqr = sigma_x * sigma_x;
    float1 sigma_y_sqr = sigma_y * sigma_y;
    return exp(-0.5 * ((x_sqr / sigma_x_sqr) + (y_sqr / sigma_y_sqr))) / (2.0 * m_pi * sigma_x * sigma_y);
}

float1 ndf_beckmann_anisotropic(float3 omega_h, float1 alpha_x, float1 alpha_y)
{
    float1 slope_x = -(omega_h.x / omega_h.z);
    float1 slope_y = -(omega_h.y / omega_h.z);
    float1 cos_theta = omega_h.z;
    float1 cos_2_theta = cos_theta * cos_theta;
    float1 cos_4_theta = cos_2_theta * cos_2_theta;
    float1 beckmann_p22 = p22_beckmann_anisotropic(slope_x, slope_y, alpha_x, alpha_y);
    return beckmann_p22 / cos_4_theta;
}

float1 P22_theta_alpha(float2 slope_h, int1 l, int1 s0, int1 t0)
{

    float1 MicrofacetRelativeArea = 1.0;
    float1 LogMicrofacetDensity = 27.0;
    int1 Dictionary_NLevels = 16;
    float1 Dictionary_Alpha=0.5;
    int1 Dictionary_N = 192;
    float1 Material_Alpha_x =0.5f;
    float1 Material_Alpha_y =0.5f;
    // Coherent index
    // Eq. 8, Alg. 3, line 1
    int1 twoToTheL = int1(pow(2.0, float1(l)));
    s0 *= twoToTheL;
    t0 *= twoToTheL;

    // Seed pseudo random generator
    // Alg. 3, line 2
    uint1 rngSeed = s0 + 1549 * t0; //exituje tu uint? radsej uint1

    // Alg.3, line 3
    float1 uMicrofacetRelativeArea = hashIQ(rngSeed * 13U);
    // Discard cells by using microfacet relative area
    // Alg.3, line 4
    if (uMicrofacetRelativeArea > MicrofacetRelativeArea)
        return 0.0f;

    // Number of microfacets in a cell
    // Alg. 3, line 5
    float1 n = pow(2.0, float1(2 * l - (2 * (Dictionary_NLevels - 1))));
    n *= exp(LogMicrofacetDensity); //Material.LogMicrofacetDensity

    // Corresponding continuous distribution LOD
    // Alg. 3, line 6
    float1 l_dist = log(n) / 1.38629;// 2.0 * log(2) = 1.38629

    // Alg. 3, line 7
    float1 uDensityRandomisation = hashIQ(rngSeed * 2171U);

    // Fix density randomisation to 2 to have better appearance
    // Notation in the paper: \zeta
    float1 densityRandomisation = 2.0;

    // Sample a Gaussian to randomise the distribution LOD around the distribution level l_dist
    // Alg. 3, line 8
    l_dist = sampleNormalDistribution(uDensityRandomisation, l_dist, densityRandomisation);

    // Alg. 3, line 9
    l_dist = clamp(uint(round(l_dist)), 0, Dictionary_NLevels);

    // Alg. 3, line 10
    if (l_dist == Dictionary_NLevels)
        return p22_beckmann_anisotropic(slope_h.x, slope_h.y, Material_Alpha_x, Material_Alpha_y);

    // Alg. 3, line 13
    float1 uTheta = hashIQ(rngSeed);
    float1 theta = 2.0 * 3.141592 * uTheta; //*m_pi*

    // Uncomment to remove random distribution rotation
    // Lead to glint alignments
    //theta = 0.0;

    float1 cosTheta = cos(theta);
    float1 sinTheta = sin(theta);

    float2 scaleFactor = float2(Material_Alpha_x / Dictionary_Alpha,
    Material_Alpha_y / Dictionary_Alpha);

    // Rotate and scale slope
    // Alg. 3, line 16
    slope_h = float2(slope_h.x * cosTheta / scaleFactor.x + slope_h.y * sinTheta / scaleFactor.y,
    -slope_h.x * sinTheta / scaleFactor.x + slope_h.y * cosTheta / scaleFactor.y);

    float2 abs_slope_h = float2(abs(slope_h.x), abs(slope_h.y));

    int distPerChannel = Dictionary_N / 3;
    float1 alpha_dist_isqrt2_4 = Dictionary_Alpha * 0.707106 * 4.0f; //m_i_sqrt_2  0.707106

    if (abs_slope_h.x > alpha_dist_isqrt2_4 || abs_slope_h.y > alpha_dist_isqrt2_4)
        return 0.0f;

    // Alg. 3, line 17
    float1 u1 = hashIQ(rngSeed * 16807U);
    float1 u2 = hashIQ(rngSeed * 48271U);

    // Alg. 3, line 18
    int i = int1(u1 * float1(Dictionary_N));
    int j = int1(u2 * float1(Dictionary_N));

    // 3 distributions values in one texel
    int distIdxXOver3 = i / 3;
    int distIdxYOver3 = j / 3;

    float1 texCoordX = abs_slope_h.x / alpha_dist_isqrt2_4;
    float1 texCoordY = abs_slope_h.y / alpha_dist_isqrt2_4;

    //TODO vsetko zakomentovane mozme vymazat
    //ref:
    //float3 P_i = textureLod(DictionaryTex, vec2(texCoordX, l_dist * Dictionary.N / 3 + distIdxXOver3), 0).rgb;
    //float3 P_j = textureLod(DictionaryTex, vec2(texCoordY, l_dist * Dictionary.N / 3 + distIdxYOver3), 0).rgb;
    
    //no lod
    //float3 P_i = SAMPLE_TEXTURE2D_ARRAY(_testDict, sampler_testDict, float2(texCoordX,0),l_dist * Dictionary_N / 3 + distIdxXOver3).rgb;//RCC frag riadok 258
    //float3 P_j = SAMPLE_TEXTURE2D_ARRAY(_testDict, sampler_testDict, float2(texCoordY,0),l_dist * Dictionary_N / 3 + distIdxYOver3).rgb;//RCC frag riadok 258

    //flip the sampling?
    //float3 P_i = SAMPLE_TEXTURE2D_ARRAY(_testDict, sampler_testDict, float2(texCoordX,l_dist * Dictionary_N / 3 + distIdxXOver3),0).rgb;//RCC frag riadok 258
    //float3 P_j = SAMPLE_TEXTURE2D_ARRAY(_testDict, sampler_testDict, float2(texCoordY,l_dist * Dictionary_N / 3 + distIdxYOver3),0).rgb;//RCC frag riadok 258

    //new
    float3 P_i = SAMPLE_TEXTURE2D_ARRAY_LOD(_testDict, sampler_testDict, float2(texCoordX,0),l_dist * Dictionary_N / 3 + distIdxYOver3,0).rgb;//RCC frag riadok 258
    float3 P_j = SAMPLE_TEXTURE2D_ARRAY_LOD(_testDict, sampler_testDict, float2(texCoordY,0),l_dist * Dictionary_N / 3 + distIdxYOver3,0).rgb;//RCC frag riadok 258

    //just a test
    //float3 P_i= SAMPLE_TEXTURE2D(_BaseColorMap, sampler_BaseColorMap,float2(texCoordX,texCoordY)).rgb;
    //float3 P_j= SAMPLE_TEXTURE2D(_BaseColorMap, sampler_BaseColorMap,float2(texCoordX,texCoordX)).rgb;

    
    //new flip change ?
    //float3 P_i = SAMPLE_TEXTURE2D_ARRAY_LOD(_testDict, sampler_testDict, float2(texCoordX,l_dist * Dictionary_N / 3 + distIdxYOver3),0,0).rgb;//RCC frag riadok 258
    //float3 P_j = SAMPLE_TEXTURE2D_ARRAY_LOD(_testDict, sampler_testDict, float2(texCoordY,l_dist * Dictionary_N / 3 + distIdxYOver3),0,0).rgb;//RCC frag riadok 258
    
    
    // Alg. 3, line 19
    return P_i[uint(i% 3)] * P_j[uint(j% 3)] / (scaleFactor.x * scaleFactor.y);
    //fmod sa sprava inac ked su zaporne? ej to tu mozne? a co s %
    //https://stackoverflow.com/questions/7610631/glsl-mod-vs-hlsl-fmod 
}

float1 P22__P_(int1 l, float2 slope_h, float2 st, float2 dst0, float2 dst1)
{
    // Convert surface coordinates to appropriate scale for level
    float1 pyrSize = pyramidSize(l);
    st[0] = st[0] * pyrSize - 0.5f;
    st[1] = st[1] * pyrSize - 0.5f;
    dst0[0] *= pyrSize;
    dst0[1] *= pyrSize;
    dst1[0] *= pyrSize;
    dst1[1] *= pyrSize;

    // Compute ellipse coefficients to bound filter region
    float1 A = dst0[1] * dst0[1] + dst1[1] * dst1[1] + 1.0;
    float1 B = -2.0 * (dst0[0] * dst0[1] + dst1[0] * dst1[1]);
    float1 C = dst0[0] * dst0[0] + dst1[0] * dst1[0] + 1.0;
    float1 invF = 1.0 / (A * C - B * B * 0.25f);
    A *= invF;
    B *= invF;
    C *= invF;

    // Compute the ellipse's bounding box in texture space
    float1 det = -B * B + 4 * A * C;
    float1 invDet = 1 / det;
    float1 uSqrt = sqrt(det * C), vSqrt = sqrt(A * det);
    uint1 s0 = uint1(ceil(st[0] - 2.0 * invDet * uSqrt));
    uint1 s1 = uint1(floor(st[0] + 2.0 * invDet * uSqrt));
    uint1 t0 = uint1(ceil(st[1] - 2.0 * invDet * vSqrt));
    uint1 t1 = uint1(floor(st[1] + 2.0 * invDet * vSqrt));

    // Scan over ellipse bound and compute quadratic equation
    float1 sum = 0.0f;
    float1 sumWts = 0;
    uint1 nbrOfIter = 0;
    
    UNITY_LOOP for (uint1 it = t0; it <= t1; ++it)
    {
        float1 tt = it - st[1];
        UNITY_LOOP for (uint1 is = s0; is <= s1; ++is)
        {
            float1 ss = is - st[0];
            // Compute squared radius and filter SDF if inside ellipse
            float1 r2 = A * ss * ss + B * ss * tt + C * tt * tt;
            if (r2 < 1)
            {
                // Weighting function used in pbrt-v3 EWA function
                float1 alpha = 2;
                float1 W_P = exp(-alpha * r2) - exp(-alpha);
                // Alg. 2, line 3
                sum += P22_theta_alpha(slope_h, l, is, it) * W_P;
                sumWts += W_P;
            }
            nbrOfIter++;
            // Guardrail (Extremely rare case.)
            if (nbrOfIter > 100)//bolo 100
                break;
        }
        // Guardrail (Extremely rare case.)
        if (nbrOfIter > 100)//bolo 100
            break;
    }
    return sum / sumWts;
}

float3 f_P(float3 wo, float3 wi,float3 camPos, float3 vertPos,float3 lightPos, FragInputs input)
{
    //later user defined
    float1 Material_Alpha_x =0.5f;
    float1 Material_Alpha_y =0.5f;
    
    if (wo.z <= 0.0)
        return float3(0,0,0); //to je na zatienenej strane 
        //return float3(1,0,0); //test
    if (wi.z <= 0.0)
        return float3(0,0,0); // to je na pravej diagonale-cudne
        //return float3(0,1,0); // test

    // Alg. 1, line 1
    float3 wh = normalize(wo + wi);
    if (wh.z <= 0.0)
        return float3(0.0, 0.0, 0.0);//totosa nenaslo 

    // Local masking shadowing
    if (dot(wo, wh) <= 0.0 || dot(wi, wh) <= 0.0)
        return float3(0,0,0);
        //return float3(0,0,1); //test

    // Eq. 1, Alg. 1, line 2
    float2 slope_h = float2(-wh.x / wh.z, -wh.y / wh.z);

    //float2 texCoord = float2(0.5,0.5);//RCC TexCoord nevyrieseny, temp
    //float2 texCoord = float2(0.5*slope_h.x,0.5*slope_h.y);//RCC TexCoord nevyrieseny, temp
    float2 texCoord = float2(input.texCoord0.x,input.texCoord0.y);
    //rozne params
    float1 Dictionary_NLevels = 16;
    float1 MaxAnisotropy = 8;

    // Uncomment for anisotropic glints
    //texCoord *= float2(1000.0, 1.0);

    float1 D_P = 0.0;
    float1 P22_P = 0.0;

    // Alg. 1, line 3
    float2 dst0 = ddx(texCoord);  //zistit toto ako pocitat -ddx hlsl a glsl dFdx
    float2 dst1 = ddy(texCoord); //ddy  hlsl a glsl dFdy
    // Compute ellipse minor and major axes 
    float1 dst0LengthSquared = dst0.x*dst0.x + dst0.y*dst0.y;
    float1 dst1LengthSquared = dst1.x*dst1.x + dst1.y*dst1.y;
    
    if (dst0LengthSquared < dst1LengthSquared)
    {
        // Swap dst0 and dst1
        float2 tmp = dst0;
        float1 tmpF = dst0LengthSquared;

        dst0 = dst1;
        dst1 = tmp;

        dst0LengthSquared = dst1LengthSquared;
        dst1LengthSquared = tmpF;
    }
    float1 majorLength = sqrt(dst0LengthSquared);
    // Alg. 1, line 5
    float1 minorLength = sqrt(dst1LengthSquared);
    // Clamp ellipse eccentricity if too large
    // Alg. 1, line 4
    if ((minorLength * MaxAnisotropy < majorLength) && (minorLength > 0.0))
    {
        float1 scale = majorLength / (minorLength * MaxAnisotropy);
        dst1 *= scale;
        minorLength *= scale;
    }
    // ------------------------------------------------------------------------------------------------------

    // Without footprint, we evaluate the Cook Torrance BRDF
    if (minorLength == 0)
    {
        D_P = ndf_beckmann_anisotropic(wh, Material_Alpha_x, Material_Alpha_y);//Material.Alpha_x, Material.Alpha_y
    }
    else
    {
        // Choose LOD
        // Alg. 1, line 6
        float1 l = max(0.0, Dictionary_NLevels - 1.0 + log2(minorLength)); //Dictionary.NLevels
        int1 il = int1(floor(l));

        // Alg. 1, line 7
        float1 w = l - float1(il);

        // Alg. 1, line 8, lerp namiesto mix
        P22_P = lerp(P22__P_(il, slope_h, texCoord, dst0, dst1),
        P22__P_(il + 1, slope_h, texCoord, dst0, dst1),
        w);

        // Eq. 6, Alg. 1, line 10
        D_P = P22_P / (wh.z * wh.z * wh.z * wh.z);
    }

    // V-cavity masking shadowing
    float1 G1wowh = min(1.0, 2.0 * wh.z * wo.z / dot(wo, wh));
    float1 G1wiwh = min(1.0, 2.0 * wh.z * wi.z / dot(wi, wh));
    float1 G = G1wowh * G1wiwh;

    //TODO Fresnel is just 1...
    // Fresnel is set to one for simplicity here
    // but feel free to use "real" Fresnel term
    float3 F = float3(1.0, 1.0, 1.0);
    
    //angle is nDotH
    float3 halfV = normalize((vertPos-lightPos) + (vertPos-camPos));
    //my own impl. based on CG2
    //zatial pockaj F = float3(FresnelSchlick(dot(VertexNorm,halfV),0.2));

    // Eq. 14, Alg. 1, line 14
    // (wi dot wg) is cancelled by
    // the cosine weight in the rendering equation
    return (F * G * D_P) / (4.0 * wo.z);
    //return float3(0,0,1);//test
}


DirectLighting ShadeSurface_Punctual(LightLoopContext lightLoopContext,
                                    FragInputs input,SurfaceData surfaceData,
                                     PositionInputs posInput, BuiltinData builtinData,
                                     PreLightData preLightData, LightData light,
                                     BSDFData bsdfData, float3 V)
{
    DirectLighting lighting;
    ZERO_INITIALIZE(DirectLighting, lighting);

    float3 L;
    float4 distances; // {d, d^2, 1/d, d_proj}
    GetPunctualLightVectors(posInput.positionWS, light, L, distances);

    //RCC
    //vsetko je cam relative
    //GetAbsolutePositionWS(PositionInputs.positionWS) //zo ShaderVariablesFunctions
    //https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Camera-Relative-Rendering.html
    //my sme vypli CameraRelativeRendering a hdrp config package je teraz local package  

    float3 tangentWS = GetAbsolutePositionWS(surfaceData.tangentWS);
    float3 normalWS = GetAbsolutePositionWS(surfaceData.normalWS);

    tangentWS =surfaceData.tangentWS;
    normalWS = surfaceData.normalWS;
    
    
    tangentWS = normalize(tangentWS);
    normalWS = normalize(normalWS);
    float3 binormal = cross(normalWS, tangentWS);
    float3 bitangentWS = normalize(binormal);

    
    float3x3 toLocal = float3x3(
            tangentWS.x,tangentWS.y ,tangentWS.z,
            bitangentWS.x, bitangentWS.y,bitangentWS.z,
            normalWS.x, normalWS.y,normalWS.z);
    
    float3 cameraPos = _WorldSpaceCameraPos.xyz;//GetAbsolutePositionWS(float3(0, 0, 0)); //rovnake 
    //float3 lightPos = GetCameraRelativePositionWS(light.positionRWS);
    float3 lightPos = GetAbsolutePositionWS(light.positionRWS);
    float3 vertPos = GetAbsolutePositionWS(posInput.positionWS);

    //teoreticky uz netreba  GetAbsolutePositionWS
    //cameraPos =float3(0, 0, 0); 
    lightPos = light.positionRWS;
    vertPos = posInput.positionWS;
    
    //float3 wi = mul(normalize(lightPos-vertPos),toLocal);
    float3 wi = mul(toLocal,normalize(lightPos-vertPos));
    wi = normalize(wi);
    //float3 wo = mul(normalize(cameraPos -vertPos),toLocal);
    float3 wo = mul(toLocal,normalize(cameraPos -vertPos));
    wo = normalize(wo);

    float3 radiance_specular = float3(0,0,0);
    radiance_specular = f_P(wo, wi, cameraPos, vertPos,lightPos,input);
    
    // Is it worth evaluating the light?
    if ((light.lightDimmer > 0) && IsNonZeroBSDF(V, L, preLightData, bsdfData))
    {
        float4 lightColor = EvaluateLight_Punctual(lightLoopContext, posInput, light, L, distances);
        lightColor.rgb *= lightColor.a; // Composite

        #ifdef MATERIAL_INCLUDE_TRANSMISSION
        if (ShouldEvaluateThickObjectTransmission(V, L, preLightData, bsdfData, light.shadowIndex))
        {
            // Replace the 'baked' value using 'thickness from shadow'.
            bsdfData.transmittance = EvaluateTransmittance_Punctual(lightLoopContext, posInput,
                                                                    bsdfData, light, L, distances);
        }
        else
            #endif
        {
            PositionInputs shadowPositionInputs = posInput;

            #ifdef LIGHT_EVALUATION_SPLINE_SHADOW_BIAS
            shadowPositionInputs.positionWS += L * GetSplineOffsetForShadowBias(bsdfData);
            #endif
            // This code works for both surface reflection and thin object transmission.
            SHADOW_TYPE shadow = EvaluateShadow_Punctual(lightLoopContext, shadowPositionInputs, light, builtinData, GetNormalForShadowBias(bsdfData), L, distances);
            lightColor.rgb *= ComputeShadowColor(shadow, light.shadowTint, light.penumbraTint);

            #ifdef LIGHT_EVALUATION_SPLINE_SHADOW_VISIBILITY_SAMPLE
            if ((light.shadowIndex >= 0) && (light.shadowDimmer > 0))
            {
                // Evaluate the shadow map a second time (this time unbiased for the spline).
                bsdfData.splineVisibility = EvaluateShadow_Punctual(lightLoopContext, posInput, light, builtinData, GetNormalForShadowBias(bsdfData), L, distances).x;
            }
            else
            {
                bsdfData.splineVisibility = -1;
            }
            #endif

            #ifdef DEBUG_DISPLAY
            // The step with the attenuation is required to avoid seeing the screen tiles at the end of lights because the attenuation always falls to 0 before the tile ends.
            // Note: g_DebugShadowAttenuation have been setup in EvaluateShadow_Punctual
            if (_DebugShadowMapMode == SHADOWMAPDEBUGMODE_SINGLE_SHADOW && light.shadowIndex == _DebugSingleShadowIndex)
                g_DebugShadowAttenuation *= step(FLT_EPS, lightColor.a);
            #endif
        }

        // Simulate a sphere/disk light with this hack.
        // Note that it is not correct with our precomputation of PartLambdaV
        // (means if we disable the optimization it will not have the
        // same result) but we don't care as it is a hack anyway.
        ClampRoughness(preLightData, bsdfData, light.minRoughness);
        //if(_materialID)
        
        //tu bude zmena, nova funkcia
        //glints = HasFlag(surfaceData.materialFeatures, MATERIALFEATUREFLAGS_LIT_GLINTS);
        //bool glints = (int)surfaceData.glintsMethod == 1;
        //_glintsMethod = 0;
        if((int)_glintsMethod==0 || _MaterialID !=6)
        {
            //render normally
            lighting = ShadeSurface_Infinitesimal(preLightData, bsdfData, V, L, lightColor.rgb,light.diffuseDimmer, light.specularDimmer);
        }
        else if((int)_glintsMethod==1)//we chose chermain20
         {
             lighting = ShadeSurface_Infinitesimal_Glints(preLightData, bsdfData, V, L, lightColor.rgb, light.diffuseDimmer, light.specularDimmer);
             lighting.specular= radiance_specular;//*bsdfData.coatMask*10+ lighting.specular;//RCC toto zahodme? (cbsdf.specR + cbsdf.specT * transmittance) * lightColor * specularDimmer;

         }
        else if((int)_glintsMethod==2)//we chose DB23 //TODO
            {
            lighting = ShadeSurface_Infinitesimal_Glints(preLightData, bsdfData, V, L, lightColor.rgb, light.diffuseDimmer, light.specularDimmer);
            lighting.specular= radiance_specular;//*bsdfData.coatMask*10+ lighting.specular;//RCC toto zahodme? (cbsdf.specR + cbsdf.specT * transmittance) * lightColor * specularDimmer;

            }
        
    }
    // add glints light moved to upper if
    //lighting.specular= radiance_specular;//*bsdfData.coatMask*10+ lighting.specular;//RCC toto zahodme? (cbsdf.specR + cbsdf.specT * transmittance) * lightColor * specularDimmer;
    //lighting.diffuse= float3(0,0,0);//*bsdfData.coatMask*10+ lighting.specular;//RCC toto zahodme? (cbsdf.specR + cbsdf.specT * transmittance) * lightColor * specularDimmer;

    return lighting;
}

