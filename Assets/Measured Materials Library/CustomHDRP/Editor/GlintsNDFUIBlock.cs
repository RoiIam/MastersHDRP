using UnityEditor.Rendering.HighDefinition;
using UnityEditor;
using UnityEngine;

// Include material common properties names to acces MaterialId
//using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties; // cannot acces internal MaterialId.LitSSS anyways....
public class GlintsNDFUIBlock : MaterialUIBlock
{
    MaterialProperty maxNDFBlock;
    MaterialProperty targetNDFBlock;
    
    MaterialProperty matID;


    public override void LoadMaterialProperties()
    {
        maxNDFBlock = FindProperty("_maxNDF");
        targetNDFBlock = FindProperty("_targetNDF");


        //Debug.Log(matID);
    }

    public override void OnGUI()
    {
        //we should check here if its the DB23 method
        if ((int)matID.floatValue == 6)  //if glints //be sure the enum is int doesnt work, nah cast this to int bcs its inconsistent in HDRP...
        {
            materialEditor.ShaderProperty(maxNDFBlock, "max NDF");
            materialEditor.ShaderProperty(targetNDFBlock, "target NDF");

        }
    }
}