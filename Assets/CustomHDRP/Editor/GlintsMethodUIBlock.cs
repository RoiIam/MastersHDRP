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

    private MaterialProperty chSDFDictBlock;
    private MaterialProperty matID;
    private MaterialProperty useGlints;
    private MaterialProperty wbNoiseAmmount;
    private MaterialProperty wbNoiseDensity;
    private MaterialProperty wbSparkleDensity;
    private MaterialProperty wbSparkleSize;

    private MaterialProperty wbUseAnisotropy;
    private MaterialProperty wbViewAmmount;
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
        matID = FindProperty("_MaterialID"); //big D...
        glintsMethod = FindProperty("_glintsMethod");
        useGlints = FindProperty("_UseGlints");

        //cher20
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

        //Wang15
        wbUseAnisotropy = FindProperty("_wbUseAnisotropy");
        wbSparkleSize = FindProperty("_wbSparkleSize");
        wbSparkleDensity = FindProperty("_wbSparkleDensity");
        wbNoiseDensity = FindProperty("_wbNoiseDensity");
        wbNoiseAmmount = FindProperty("_wbNoiseAmmount");
        wbViewAmmount = FindProperty("_wbViewAmmount");


        //Debug.Log(matID);
    }

    public void ShowChermainParams()
    {
        materialEditor.ShaderProperty(chSDFDictBlock, "SDF Dictionary");
    }

    public void ShowDeliotParams()
    {
        materialEditor.ShaderProperty(dbMaxNDFBlock, "max NDF");
        materialEditor.ShaderProperty(dbTargetNDFBlock, "target NDF");
    }

    public void ShowZirrParams()
    {
        //changezkRoughnessSimultaneously = EditorGUILayout.Toggle("Isometric Roughness based on X ", changezkRoughnessSimultaneously);
        materialEditor.ShaderProperty(zkRoughness, "Global Roughness");
        /*if (changezkRoughnessSimultaneously)
        {
            zkRoughness.vectorValue = new Vector4(zkRoughness.vectorValue.x,zkRoughness.vectorValue.x,0,0);//there is a better way, check in ShowAsVector2Drawer
        }*/

        //changezkMicroRoughnessSimultaneously = EditorGUILayout.Toggle("Isometric Micro Roughness based on X", changezkMicroRoughnessSimultaneously);//there is a better way, check in ShowAsVector2Drawer
        materialEditor.ShaderProperty(zkMicroRoughness, "Micro Roughness");
        /*if (changezkMicroRoughnessSimultaneously)
        {
            zkMicroRoughness.vectorValue = new Vector4(zkMicroRoughness.vectorValue.x,zkMicroRoughness.vectorValue.x,0,0);
        }*/
        materialEditor.ShaderProperty(zkSearchConeAngle, "Search Cone Angle");
        materialEditor.ShaderProperty(zkVariation, "Variation");
        materialEditor.ShaderProperty(zkDynamicRange, "Dynamic Range");
        materialEditor.ShaderProperty(zkDenisty, "Density");
    }

    public void ShowWangParams()
    {
        ShowWangModParams();
    }

    public void ShowWangModParams()
    {
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
            //doesnt work for now...
            //we should check here if its the DB23 method
            //Debug.Log((int)matID.floatValue);

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
                        ShowWangModParams();
                        break;
                }
        }
    }
}