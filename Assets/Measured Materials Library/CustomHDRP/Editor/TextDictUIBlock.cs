using UnityEditor.Rendering.HighDefinition;
using UnityEditor;

class TextDictUIBlock : MaterialUIBlock
{
    MaterialProperty dictBlock;

    public override void LoadMaterialProperties()
    {
        dictBlock = FindProperty("_testDict");
    }

    public override void OnGUI()
    {
        materialEditor.ShaderProperty(dictBlock, "Test Dict");
    }
}