//-------------------------------------------------------------------------------------
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
    bool with_anisotropy;
    float1 i_sparkle_size;
    float1 i_sparkle_density;
    float1 i_noise_density;
    float1 i_noise_amount;
    float1 i_view_amount;
};
