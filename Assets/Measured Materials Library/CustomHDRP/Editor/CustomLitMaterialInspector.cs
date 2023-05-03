using UnityEditor.Rendering.HighDefinition;
using UnityEngine;

// https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@11.0/manual/hdrp-custom-material-inspector.html
public class CustomLitMaterialInspector : LightingShaderGraphGUI
{
    public CustomLitMaterialInspector()
    {
        // Remove the ShaderGraphUIBlock to avoid having duplicated properties in the UI.
        //uiBlocks.RemoveAll(b => b is ShaderGraphUIBlock);
        
        
        //uiBlocks.Insert(1,new  TextDictUIBlock("myColor", "test zmeny baseColor v LitDataindividualLayer.hlsl"));//RCC gui text
        uiBlocks.Insert(1, new TextDictUIBlock());//RCC gui text

    }
}