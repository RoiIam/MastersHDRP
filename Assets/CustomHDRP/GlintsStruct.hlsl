﻿//-------------------------------------------------------------------------------------
// GlintsStruct
// This structure gather all possible varying/interpolator for this shader.
//-------------------------------------------------------------------------------------


struct ChermainStruct
{
    float2 Material_Alpha;
    float1 LogMicrofacetDensity;
    float1 Dictionary_NLevels;
    float1 MaxAnisotropy;
    float1 MicrofacetRelativeArea;
    float1 Dictionary_Alpha;
    int1 Dictionary_N;
};

//maybe add other structs later
struct WBEStruct
{
    bool useAnisotropy;
    float1 sparkleSize;
    float1 sparkleDensity;
    float1 noiseDensity;
    float1 noiseAmount;
    float1 viewAmount;
};
