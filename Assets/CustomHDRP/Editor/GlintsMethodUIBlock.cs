using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.HighDefinition;

//Modified to remove dependencies

public class GlintsMethodUIBlock : MaterialUIBlock
{
    
    public enum GlintsType
    {
        No,
        Cher,
        De,
        Zirr,
        Wb,
        Wbe
    }
    
    private readonly ExpandableBit foldoutBit;

    private MaterialProperty dbDensityRandomization;
    private MaterialProperty dbLogMicrofacetDensity;


    private MaterialProperty dbMaxNDFBlock;
    private MaterialProperty dbMicrofacetRoughness;
    private MaterialProperty dbScreenSpaceScale;
    private MaterialProperty dbTargetNDFBlock;
    private MaterialProperty Glint2023NoiseMap;
    private MaterialProperty Glint2023NoiseMapSize;


    private MaterialProperty glintsMethod;
    private MaterialProperty chDictionary_Alpha;
    private MaterialProperty chDictionary_N;
    private MaterialProperty chDictionary_NLevels;
    private MaterialProperty chLogMicrofacetDensity;

    private MaterialProperty chMaterial_Alpha;
    private MaterialProperty chMaxAnisotropy;
    private MaterialProperty chMicrofacetRelativeArea;
    private MaterialProperty chSDFDictBlock;

    private MaterialProperty useGlints;
    private MaterialProperty wbGlitterStrength;
    private MaterialProperty wbGridAmount;
    private MaterialProperty wbJitterScale;

    private MaterialProperty wbNoiseAmount;
    private MaterialProperty wbNoiseDensity;
    private MaterialProperty wbPerlinTexture;


    private MaterialProperty wbRoughness;
    private MaterialProperty wbSparkleDensity;
    private MaterialProperty wbSparkleSize;
    private MaterialProperty wbUseAnisotropy;
    private MaterialProperty wbUsePerlinTexture;
    private MaterialProperty wbUseScales;
    private MaterialProperty wbViewAmount;

    private MaterialProperty zkDensity;
    private MaterialProperty zkDynamicRange;
    private MaterialProperty zkMicroRoughness;

    private MaterialProperty zkRoughness;
    private MaterialProperty zkSearchConeAngle;
    private MaterialProperty zkVariation;

    public GlintsMethodUIBlock(ExpandableBit expandableBit)
    {
        foldoutBit = expandableBit;
    }


    public override void LoadMaterialProperties()
    {
        //use FindProperty for all that we will show in ui
        glintsMethod = FindProperty("_glintsMethod");
        useGlints = FindProperty("_UseGlints");

        //cher20
        chMaterial_Alpha = FindProperty("_chMaterial_Alpha");
        chLogMicrofacetDensity = FindProperty("_chLogMicrofacetDensity");
        chDictionary_NLevels = FindProperty("_chDictionary_NLevels");
        chMaxAnisotropy = FindProperty("_chMaxAnisotropy");
        chMicrofacetRelativeArea = FindProperty("_chMicrofacetRelativeArea");
        chDictionary_Alpha = FindProperty("_chDictionary_Alpha");
        chDictionary_N = FindProperty("_chDictionary_N");
        chSDFDictBlock = FindProperty("_chSDFDict");


        //Deliot23
        dbMaxNDFBlock = FindProperty("_dbMaxNDF");
        dbTargetNDFBlock = FindProperty("_dbTargetNDF");

        dbScreenSpaceScale = FindProperty("_dbScreenSpaceScale");
        dbLogMicrofacetDensity = FindProperty("_dbLogMicrofacetDensity");
        dbMicrofacetRoughness = FindProperty("_dbMicrofacetRoughness");
        dbDensityRandomization = FindProperty("_dbDensityRandomization");
        Glint2023NoiseMap = FindProperty("_Glint2023NoiseMap");
        Glint2023NoiseMapSize = FindProperty("_Glint2023NoiseMapSize");

        //zirr16
        zkRoughness = FindProperty("_zkRoughness");
        zkMicroRoughness = FindProperty("_zkMicroRoughness");
        zkSearchConeAngle = FindProperty("_zkSearchConeAngle");
        zkVariation = FindProperty("_zkVariation");
        zkDynamicRange = FindProperty("_zkDynamicRange");
        zkDensity = FindProperty("_zkDensity");

        //Wang15 and Enhanced
        wbGlitterStrength = FindProperty("_wbGlitterStrength");
        wbUseAnisotropy = FindProperty("_wbUseAnisotropy");
        wbSparkleSize = FindProperty("_wbSparkleSize");
        wbSparkleDensity = FindProperty("_wbSparkleDensity");
        wbNoiseDensity = FindProperty("_wbNoiseDensity");
        wbNoiseAmount = FindProperty("_wbNoiseAmount");
        wbViewAmount = FindProperty("_wbViewAmount");

        wbRoughness = FindProperty("_wbRoughness");
        wbPerlinTexture = FindProperty("_wbPerlinTexture");
        wbUsePerlinTexture = FindProperty("_wbUsePerlinTexture");
        wbGridAmount = FindProperty("_wbGridAmount");
        wbJitterScale = FindProperty("_wbJitterScale");
        wbUseScales = FindProperty("_wbUseScales");
    }


    public void ShowChermainParams()
    {
        materialEditor.ShaderProperty(chMaterial_Alpha, "Material Alpha");
        materialEditor.ShaderProperty(chLogMicrofacetDensity, "Log Microfacet Density");
        materialEditor.ShaderProperty(chDictionary_NLevels, "Dictionary N Levels");
        materialEditor.ShaderProperty(chMaxAnisotropy, "Max Anisotropy");
        materialEditor.ShaderProperty(chMicrofacetRelativeArea, "Microfacet Relative Area");
        materialEditor.ShaderProperty(chDictionary_Alpha, "Dictionary Alpha");
        materialEditor.ShaderProperty(chDictionary_N, "Dictionary_ N");
        materialEditor.ShaderProperty(chSDFDictBlock, "SDF Dict Texture Array");
    }

    public void ShowDeliotParams()
    {
        materialEditor.ShaderProperty(dbMaxNDFBlock, "Max NDF");
        materialEditor.ShaderProperty(dbTargetNDFBlock, "Target NDF");
        materialEditor.ShaderProperty(dbDensityRandomization, "Density Randomization");
        materialEditor.ShaderProperty(dbLogMicrofacetDensity, "Log Microfacet Density");
        materialEditor.ShaderProperty(dbMicrofacetRoughness, "Microfacet Roughness");
        materialEditor.ShaderProperty(dbScreenSpaceScale, "Screen Space Scale");
        materialEditor.ShaderProperty(Glint2023NoiseMap, "Glint2023NoiseMap");
        materialEditor.ShaderProperty(Glint2023NoiseMapSize, "Glint2023NoiseMapSize");
    }

    public void ShowZirrParams()
    {
        materialEditor.ShaderProperty(zkRoughness, "Global Roughness");
        materialEditor.ShaderProperty(zkMicroRoughness, "Micro Roughness");
        materialEditor.ShaderProperty(zkSearchConeAngle, "Search Cone Angle");
        materialEditor.ShaderProperty(zkVariation, "Variation");
        materialEditor.ShaderProperty(zkDynamicRange, "Dynamic Range");
        materialEditor.ShaderProperty(zkDensity, "Density");
    }

    public void ShowWangParams()
    {
        materialEditor.ShaderProperty(wbGlitterStrength, "Glitter Strength");
        materialEditor.ShaderProperty(wbUseAnisotropy, "Use Anisotropy");
        materialEditor.ShaderProperty(wbSparkleSize, "Sparkle Size");
        materialEditor.ShaderProperty(wbSparkleDensity, "Sparkle Density");
        materialEditor.ShaderProperty(wbNoiseDensity, "Noise Density");
        materialEditor.ShaderProperty(wbNoiseAmount, "Noise Amount");
        materialEditor.ShaderProperty(wbViewAmount, "View Amount jitter");
    }

    public void ShowWBEnhancedParams()
    {
        materialEditor.ShaderProperty(wbRoughness, "Global roughness");
        //materialEditor.ShaderProperty(wbPerlinTexture, "3d Perlin Texture",type,matches,false);
        //materialEditor.ShaderProperty(wbUsePerlinTexture, "Use Perlin Texture", false);
        materialEditor.ShaderProperty(wbGridAmount, "Grid loops amount");
        materialEditor.ShaderProperty(wbJitterScale, "Perlin Jitter Scale");
        materialEditor.ShaderProperty(wbUseScales, "Toggle to use scales");
    }


    //TODO remove magic numbers
    public override void OnGUI()
    {
        materialEditor.ShaderProperty(useGlints, "Use Glints");

        if (useGlints.floatValue != 1.0)
            return;

        materialEditor.ShaderProperty(glintsMethod, "Glints Method");

        using (var header = new MaterialHeaderScope("Glints Options", (uint)foldoutBit, materialEditor))
        {
            if (header.expanded)
            {
                GlintsType g = (GlintsType)glintsMethod.floatValue;
                switch (g)
                {
                    case GlintsType.Cher:
                        ShowChermainParams();
                        break;
                    
                    case GlintsType.De:
                        ShowDeliotParams();
                        break;
                    
                    case GlintsType.Zirr:
                        ShowZirrParams();
                        break;
                    
                    case GlintsType.Wb:
                        ShowWangParams();
                        break;
                    
                    case GlintsType.Wbe:
                        ShowWangParams();
                        ShowWBEnhancedParams();
                        break;
                }

            }
        }
    }
}