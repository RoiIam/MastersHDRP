using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.HighDefinition;
using UnityEngine;

// Include material common properties names to acces MaterialId
//using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties; // cannot acces internal MaterialId.LitSSS anyways....


namespace CustomHDRP.Visualizer
{
    public class GlintsMethodUIBlock : MaterialUIBlock
    {
        private readonly ExpandableBit foldoutBit;

        public List<MaterialPropertyType> activeGlintProperties = new();
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
            activeGlintProperties.Clear();
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

        public void ShaderProperty2(MaterialProperty m, string name,
            MaterialPropertyData.GlintsType t, bool matches, bool include = true)
        {
            if (matches)
                materialEditor.ShaderProperty(m, name);
            if (include)
                activeGlintProperties.Add(new MaterialPropertyType(m, t));
        }

        public void ShowChermainParams(MaterialPropertyData.GlintsType t)
        {
            var type = MaterialPropertyData.GlintsType.Cher;
            var matches = t == type ? true : false;
            ShaderProperty2(chMaterial_Alpha, "Material Alpha", type, matches);
            ShaderProperty2(chLogMicrofacetDensity, "Log Microfacet Density", type, matches);
            ShaderProperty2(chDictionary_NLevels, "Dictionary N Levels", type, matches);
            ShaderProperty2(chMaxAnisotropy, "Max Anisotropy", type, matches);
            ShaderProperty2(chMicrofacetRelativeArea, "Microfacet Relative Area", type, matches);
            ShaderProperty2(chDictionary_Alpha, "Dictionary Alpha", type, matches);
            ShaderProperty2(chDictionary_N, "Dictionary_ N", type, matches, false);
            ShaderProperty2(chSDFDictBlock, "SDF Dict Texture Array", type, matches, false);
        }

        public void ShowDeliotParams(MaterialPropertyData.GlintsType t)
        {
            var type = MaterialPropertyData.GlintsType.De;
            var matches = t == type ? true : false;

            ShaderProperty2(dbMaxNDFBlock, "Max NDF", type, matches);
            ShaderProperty2(dbTargetNDFBlock, "Target NDF", type, matches);
            ShaderProperty2(dbDensityRandomization, "Density Randomization", type, matches);
            ShaderProperty2(dbLogMicrofacetDensity, "Log Microfacet Density", type, matches);
            ShaderProperty2(dbMicrofacetRoughness, "Microfacet Roughness", type, matches);
            ShaderProperty2(dbScreenSpaceScale, "Screen Space Scale", type, matches);
            ShaderProperty2(Glint2023NoiseMap, "Glint2023NoiseMap", type, matches, false);
            ShaderProperty2(Glint2023NoiseMapSize, "Glint2023NoiseMapSize", type, matches, false);
        }

        public void ShowZirrParams(MaterialPropertyData.GlintsType t)
        {
            var type = MaterialPropertyData.GlintsType.Zirr;
            var matches = t == type ? true : false;
            ShaderProperty2(zkRoughness, "Global Roughness", type, matches);
            ShaderProperty2(zkMicroRoughness, "Micro Roughness", type, matches);
            ShaderProperty2(zkSearchConeAngle, "Search Cone Angle", type, matches);
            ShaderProperty2(zkVariation, "Variation", type, matches);
            ShaderProperty2(zkDynamicRange, "Dynamic Range", type, matches);
            ShaderProperty2(zkDensity, "Density", type, matches);
        }

        public void ShowWangParams(MaterialPropertyData.GlintsType t)
        {
            var include = MaterialPropertyData.GlintsType.Wb == t || t == MaterialPropertyData.GlintsType.Wbe;
            var type = MaterialPropertyData.GlintsType.Wb;
            var matches = t == type
                          || t == MaterialPropertyData.GlintsType.Wbe;

            ShaderProperty2(wbGlitterStrength, "Glitter Strength", type, matches, include);
            ShaderProperty2(wbUseAnisotropy, "Use Anisotropy", type, matches, include);
            ShaderProperty2(wbSparkleSize, "Sparkle Size", type, matches, include);
            ShaderProperty2(wbSparkleDensity, "Sparkle Density", type, matches, include);
            ShaderProperty2(wbNoiseDensity, "Noise Density", type, matches, include);
            ShaderProperty2(wbNoiseAmount, "Noise Amount", type, matches, include);
            ShaderProperty2(wbViewAmount, "View Amount jitter", type, matches, include);
        }

        public void ShowWBEnhancedParams(MaterialPropertyData.GlintsType t)
        {
            var type = MaterialPropertyData.GlintsType.Wbe;
            var matches = t == type ? true : false;

            ShaderProperty2(wbRoughness, "Global roughness", type, matches);
            //ShaderProperty2(wbPerlinTexture, "3d Perlin Texture",type,matches,false);
            //ShaderProperty2(wbUsePerlinTexture, "Use Perlin Texture", type, matches, false);
            ShaderProperty2(wbGridAmount, "Grid loops amount", type, matches);
            ShaderProperty2(wbJitterScale, "Perlin Jitter Scale", type, matches);
            ShaderProperty2(wbUseScales, "Toggle to use scales", type, matches);
        }


        //TODO remove magic numbers
        public override void OnGUI()
        {
            materialEditor.ShaderProperty(useGlints, "Use Glints");

            if (useGlints.floatValue != 1.0)
                return;
            //Debug.Log("type for blockui",type);
            //Debug.Log(activeGlintProperties.Count);
            materialEditor.ShaderProperty(glintsMethod, "Glints Method");

            using (var header = new MaterialHeaderScope("Glints Options", (uint)foldoutBit, materialEditor))
            {
                if (header.expanded)
                {
                    var type = (MaterialPropertyData.GlintsType)glintsMethod.floatValue;
                    ShowChermainParams(type);
                    ShowDeliotParams(type);
                    ShowZirrParams(type);
                    ShowWangParams(type);
                    ShowWBEnhancedParams(type);

                    if (materialEditor.HelpBoxWithButton(new GUIContent("params generated"),
                            new GUIContent("press to gen params")))
                    {
                        var newData = ScriptableObject.CreateInstance<MaterialPropertyData>();

                        foreach (var m in activeGlintProperties)
                        {
                            var p = m.materialProperty;
                            Debug.Log(p.type);
                            //newData.list.Add();
                            var dataToAdd = new MaterialPropertyData.SerializedGlintsMaterialProperty();
                            dataToAdd.name = p.name;
                            dataToAdd.displayName = p.displayName;
                            dataToAdd.glintsType = m.glintsType;
                            switch (p.type)
                            {
                                case MaterialProperty.PropType.Range:
                                    dataToAdd.range = p.rangeLimits;
                                    dataToAdd.floatValue = p.floatValue;
                                    dataToAdd.propertyType = MaterialPropertyData.Type.Range;
                                    break;
                                case MaterialProperty.PropType.Float:
                                    dataToAdd.floatValue = p.floatValue;
                                    dataToAdd.propertyType = MaterialPropertyData.Type.Float;

                                    break;
                                case MaterialProperty.PropType.Int:
                                    dataToAdd.floatValue = p.intValue;
                                    dataToAdd.propertyType = MaterialPropertyData.Type.Int;

                                    break;
                                case MaterialProperty.PropType.Vector:
                                    dataToAdd.vecValue = p.vectorValue;
                                    dataToAdd.propertyType = MaterialPropertyData.Type.Vec;
                                    break;
                                default:
                                    Debug.Log("unknown type" + p.type);
                                    break;
                            }

                            newData.list.Add(dataToAdd);
                        }

                        // Create an instance of your ScriptableObject
                        //newData.list.Add(new MaterialProperty.MyClass());
                        //save the ScriptableObject asset
                        var path = "Assets/CustomHDRP/Visualizer/MatPropData.asset";
                        AssetDatabase.CreateAsset(newData, path);
                        AssetDatabase.SaveAssets();
                        AssetDatabase.Refresh();
                    }
                }
            }
        }


        [Serializable]
        public class MaterialPropertyType
        {
            public MaterialPropertyData.GlintsType glintsType = MaterialPropertyData.GlintsType.No;

            [SerializeField] public MaterialProperty materialProperty;

            public MaterialPropertyType(MaterialProperty m, MaterialPropertyData.GlintsType g)
            {
                materialProperty = m;
                glintsType = g;
            }
        }
    }
}