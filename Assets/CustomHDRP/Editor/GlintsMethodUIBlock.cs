using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.HighDefinition;

// Include material common properties names to acces MaterialId
//using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties; // cannot acces internal MaterialId.LitSSS anyways....
public class GlintsMethodUIBlock : MaterialUIBlock
{
    private readonly ExpandableBit foldoutBit;


    private MaterialProperty dbMaxNDFBlock;
    private MaterialProperty dbTargetNDFBlock;


    private MaterialProperty glintsMethod;
    public bool changezkMicroRoughnessSimultaneously = true;
    public bool changezkRoughnessSimultaneously = true;
    private MaterialProperty chDictionary_Alpha;
    private MaterialProperty chDictionary_N;
    private MaterialProperty chDictionary_NLevels;
    private MaterialProperty chLogMicrofacetDensity;

    private MaterialProperty chMaterial_Alpha;
    private MaterialProperty chMaxAnisotropy;
    private MaterialProperty chMicrofacetRelativeArea;
    private MaterialProperty chSDFDictBlock;

    private MaterialProperty matID;
    private MaterialProperty useGlints;


    private MaterialProperty wbRoughness;
    private MaterialProperty wbGlitterStrength;
    private MaterialProperty wbNoiseAmmount;
    private MaterialProperty wbNoiseDensity;
    private MaterialProperty wbSparkleDensity;
    private MaterialProperty wbSparkleSize;
    private MaterialProperty wbUseAnisotropy;
    private MaterialProperty wbViewAmmount;
    private MaterialProperty wbPerlinTexture;
    private MaterialProperty wbUsePerlinTexture;
    private MaterialProperty wbGridAmmount;
    private MaterialProperty wbJitterScale;

    private MaterialProperty zkDenisty;
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
        matID = FindProperty("_MaterialID");
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
        //zirr16
        zkRoughness = FindProperty("_zkRoughness");
        zkMicroRoughness = FindProperty("_zkMicroRoughness");
        zkSearchConeAngle = FindProperty("_zkSearchConeAngle");
        zkVariation = FindProperty("_zkVariation");
        zkDynamicRange = FindProperty("_zkDynamicRange");
        zkDenisty = FindProperty("_zkDenisty");

        //Wang15 and Enhanced
        wbGlitterStrength = FindProperty("_wbGlitterStrength");
        wbUseAnisotropy = FindProperty("_wbUseAnisotropy");
        wbSparkleSize = FindProperty("_wbSparkleSize");
        wbSparkleDensity = FindProperty("_wbSparkleDensity");
        wbNoiseDensity = FindProperty("_wbNoiseDensity");
        wbNoiseAmmount = FindProperty("_wbNoiseAmmount");
        wbViewAmmount = FindProperty("_wbViewAmmount");
        
        wbRoughness = FindProperty("_wbRoughness");
        wbPerlinTexture = FindProperty("_wbPerlinTexture");
        wbUsePerlinTexture = FindProperty("_wbUsePerlinTexture");
        wbGridAmmount = FindProperty("_wbGridAmmount");
        wbJitterScale = FindProperty("_wbJitterScale");
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
        materialEditor.ShaderProperty(dbMaxNDFBlock, "max NDF");
        materialEditor.ShaderProperty(dbTargetNDFBlock, "target NDF");
    }

    public void ShowZirrParams()
    {
        materialEditor.ShaderProperty(zkRoughness, "Global Roughness");
        materialEditor.ShaderProperty(zkMicroRoughness, "Micro Roughness");
        materialEditor.ShaderProperty(zkSearchConeAngle, "Search Cone Angle");
        materialEditor.ShaderProperty(zkVariation, "Variation");
        materialEditor.ShaderProperty(zkDynamicRange, "Dynamic Range");
        materialEditor.ShaderProperty(zkDenisty, "Density");
    }

    public void ShowWangParams()
    {
        materialEditor.ShaderProperty(wbRoughness, "Global roughness");
        materialEditor.ShaderProperty(wbPerlinTexture, "3d Perlin Texture");
        materialEditor.ShaderProperty(wbUsePerlinTexture, "Use Perlin Texture");
        materialEditor.ShaderProperty(wbGridAmmount, "Grid loops ammount");
        materialEditor.ShaderProperty(wbJitterScale, "Jitter grid scale");
    }

    public void ShowWBEnhancedParams()
    {
        ShowWangParams();
        materialEditor.ShaderProperty(wbGlitterStrength, "Glitter Strength");
        materialEditor.ShaderProperty(wbUseAnisotropy, "UseAnisotropy");
        materialEditor.ShaderProperty(wbSparkleSize, "SparkleSize");
        materialEditor.ShaderProperty(wbSparkleDensity, "SparkleDensity");
        materialEditor.ShaderProperty(wbNoiseDensity, "NoiseDensity");
        materialEditor.ShaderProperty(wbNoiseAmmount, "NoiseAmmount");
        materialEditor.ShaderProperty(wbViewAmmount, "ViewAmmount");
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
                switch ((int)glintsMethod.floatValue)
                {
                    case 1:
                        ShowChermainParams();
                        break;
                    case 2:
                        ShowDeliotParams();
                        break;
                    case 3:
                        ShowZirrParams();
                        break;
                    case 4:
                        ShowWangParams();
                        break;
                    case 5:
                        ShowWBEnhancedParams();
                        break;
                }
        }
    }
}