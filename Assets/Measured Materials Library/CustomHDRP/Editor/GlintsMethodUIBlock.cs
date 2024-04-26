using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.HighDefinition;

// Include material common properties names to acces MaterialId
//using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties; // cannot acces internal MaterialId.LitSSS anyways....
public class GlintsMethodUIBlock : MaterialUIBlock
{
    private readonly ExpandableBit foldoutBit;

    private MaterialProperty dictBlock;
    private MaterialProperty glintsMethod;
    private MaterialProperty useGlints;
    private MaterialProperty matID;


    private MaterialProperty maxNDFBlock;
    private MaterialProperty targetNDFBlock;

    MaterialProperty UseAnisotropy;
    MaterialProperty SparkleSize; 
    MaterialProperty SparkleDensity;
    MaterialProperty NoiseDensity;
    MaterialProperty NoiseAmmount;
    MaterialProperty ViewAmmount;


    public GlintsMethodUIBlock(ExpandableBit expandableBit)
    {
        foldoutBit = expandableBit;
    }

    public override void LoadMaterialProperties()
    {
        matID = FindProperty("_MaterialID"); //big D...
        glintsMethod = FindProperty("_glintsMethod");
        useGlints = FindProperty("_UseGlints");

        dictBlock = FindProperty("_testDict");
        //Deliot23
        maxNDFBlock = FindProperty("_maxNDF");
        targetNDFBlock = FindProperty("_targetNDF");
        //Wang15
        UseAnisotropy = FindProperty("_UseAnisotropy");
        SparkleSize = FindProperty("_SparkleSize");
        SparkleDensity = FindProperty("_SparkleDensity");
        NoiseDensity = FindProperty("_NoiseDensity");
        NoiseAmmount = FindProperty("_NoiseAmmount");
        ViewAmmount = FindProperty("_ViewAmmount");
        
        
        //Debug.Log(matID);
    }

    public void ShowChermainParams()
    {
        materialEditor.ShaderProperty(dictBlock, "Test Dict");
    }

    public void ShowDeliotParams()
    {
        materialEditor.ShaderProperty(maxNDFBlock, "max NDF");
        materialEditor.ShaderProperty(targetNDFBlock, "target NDF");
    }

    public void ShowZirrParams()
    {
    }

    public void ShowWangParams()
    {
        ShowWangModParams();
    }

    public void ShowWangModParams()
    {
        
        materialEditor.ShaderProperty(UseAnisotropy, "UseAnisotropy");
        materialEditor.ShaderProperty(SparkleSize, "SparkleSize");
        materialEditor.ShaderProperty(SparkleDensity, "SparkleDensity");
        materialEditor.ShaderProperty(NoiseDensity, "NoiseDensity");
        materialEditor.ShaderProperty(NoiseAmmount, "NoiseAmmount");
        materialEditor.ShaderProperty(ViewAmmount, "ViewAmmount");
    }

    //TODO remove magic numbers
    public override void OnGUI()
    {
        materialEditor.ShaderProperty(useGlints, "Use Glints");

        if (useGlints.floatValue == 1.0)

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