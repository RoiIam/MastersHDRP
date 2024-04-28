// Continuation of LightEvaluation.hlsl.
// use #define MATERIAL_INCLUDE_TRANSMISSION to include thick transmittance evaluation
// use #define MATERIAL_INCLUDE_PRECOMPUTED_TRANSMISSION to apply pre-computed transmittance (or thin transmittance only)
// use #define OVERRIDE_SHOULD_EVALUATE_THICK_OBJECT_TRANSMISSION to provide a new version of ShouldEvaluateThickObjectTransmission
//-----------------------------------------------------------------------------
// Directional and punctual lights (infinitesimal solid angle)
//-----------------------------------------------------------------------------

#include <HLSLSupport.cginc>

#include "23BelcourGlints/Glints2023.hlsl" //so we have float erfinv(float x) just once // not working
#include "16ZirrKaplanyan/16ZKGLints.hlsl"
float3 glintsColor = float3(0.0, 0.0, 0.0);
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
DirectLighting ShadeSurface_Infinitesimal_Glints(PreLightData preLightData, BSDFData bsdfData, FragInputs fragInputs,
                                          float3 V, float3 L, float3 lightColor,
                                          float diffuseDimmer, float specularDimmer, float3x3 toLocal,
                                          float3 wo,float3 wi, float3 cameraPos,float3 vertPos,float3 lightPos
                                          ) 
{
    DirectLighting lighting;
    ZERO_INITIALIZE(DirectLighting, lighting);

    if (Max3(lightColor.r, lightColor.g, lightColor.b) > 0)
    {
        CBSDF cbsdf;
        //RCC tiez zmenene
        if((int)_glintsMethod==2)//else we do DB23 
        {
            cbsdf = EvaluateBSDF_GlintsDB23(V, L, preLightData, bsdfData,fragInputs);//spat do Lit.hlsl
        }
        else//the rest
        {
            cbsdf = EvaluateBSDF(V, L, preLightData, bsdfData);//spat do Lit.hlsl
        }
        
        
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
        //if((int)_glintsMethod==1)//Chermain20
            //lighting.specular = (testCol + cbsdf.specT * transmittance) * lightColor * specularDimmer;
        //else
        if((int)_glintsMethod==3 || (int)_glintsMethod==1 || (int)_glintsMethod==4)//ZK +CHE + WB
            lighting.specular = (glintsColor + cbsdf.specT * transmittance) * lightColor * specularDimmer;
        else
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


#include "20Chermain/20ChermainGlints.hlsl"
#include "15WangBowles/15WangGlints.hlsl"
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
    float3x3 ctf = float3x3(tangentWS, bitangentWS, normalWS);
    
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
    
        if((int)_glintsMethod==0 || !_UseGlints)
        {
            //render normally
            lighting = ShadeSurface_Infinitesimal(preLightData, bsdfData, V, L, lightColor.rgb,light.diffuseDimmer, light.specularDimmer);
        }
        else
        {
             
            if((int)_glintsMethod==1)//we chose chermain20
                glintsColor = f_P(wo, wi, cameraPos, vertPos,lightPos,normalWS,input);
            
            else if((int)_glintsMethod==3)//we chose ZK16 //TODO
            {
            

                float2 texCoord = input.texCoord0; //float2(input.texCoord0.x,input.texCoord0.y);
                float2 roughness = float2(0.6f,0.6f);
                float2 microRoughness = roughness * 0.024;
                float searchConeAngle = 0.01;
                float variation = 100.0;
                float dynamicRange = 50000.0;
                float density = 5.e8;
                glintsColor = float3(1,1,1);
                glintsColor = glints( texCoord,  ddx(texCoord), ddy(texCoord),
                    toLocal,    normalize(vertPos-light.positionRWS),  normalWS,  normalize(vertPos-cameraPos),
                    _zkRoughness,  _zkMicroRoughness,
                    _zkSearchConeAngle,  _zkVariation,  _zkDynamicRange,_zkDenisty);
            }
            else if((int)_glintsMethod==4)//we chose WB
            {
                float3 vViewVec = vertPos - cameraPos; // vo world space
                float dotvn = dot(vViewVec, -normalWS);
                float4 vlarge_dir = float4(vViewVec - dotvn * -normalWS, dotvn);

                glintsColor = float3(1,1,1);
                glintsColor =wangGlints(vertPos,normalWS,lightPos, vViewVec, vlarge_dir,
_wbUseAnisotropy,
 _wbSparkleSize,
 _wbSparkleDensity,
 _wbNoiseDensity,
 _wbNoiseAmmount,
 _wbViewAmmount 
 );
            }
            
            //apply final lighting
            lighting = ShadeSurface_Infinitesimal_Glints(preLightData, bsdfData, input,V, L, lightColor.rgb, light.diffuseDimmer, light.specularDimmer, toLocal,
                        wo,wi, cameraPos,vertPos,lightPos);
        }
    }
    return lighting;
}

