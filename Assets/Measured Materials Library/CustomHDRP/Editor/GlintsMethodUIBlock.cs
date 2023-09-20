using UnityEditor.Rendering.HighDefinition;
using UnityEditor;
using UnityEngine;

// Include material common properties names to acces MaterialId
//using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties; // cannot acces internal MaterialId.LitSSS anyways....
public class GlintsMethodUIBlock : MaterialUIBlock
{
    MaterialProperty glintsBlock;
    MaterialProperty matID;

    
    public override void LoadMaterialProperties()
    {
        glintsBlock = FindProperty("_glintsMethod");
        matID = FindProperty("_MaterialID"); //big D...

        //Debug.Log(matID);
    }

    public override void OnGUI()
    {
        if ((int)matID.floatValue == 6)  //if glints //be sure the enum is int doesnt work, nah cast this to int bcs its inconsistent in HDRP...
        {
            materialEditor.ShaderProperty(glintsBlock, "Glints Method");

        }
    }
}
