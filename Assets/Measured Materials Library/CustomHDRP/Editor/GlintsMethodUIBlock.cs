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

        maxNDFBlock = FindProperty("_maxNDF");
        targetNDFBlock = FindProperty("_targetNDF");
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
    }

    public void ShowWangModParams()
    {
    }

    //TODO remove magic numbers
    public override void OnGUI()
    {
        materialEditor.ShaderProperty(useGlints, "Use Glints");

        if (useGlints.floatValue == 1.0)


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