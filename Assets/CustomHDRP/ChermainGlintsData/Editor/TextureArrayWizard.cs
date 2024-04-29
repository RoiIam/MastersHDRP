using UnityEditor;
using UnityEngine;

public class TextureArrayWizard : ScriptableWizard
{
    public Texture2D[] textures;


    private void OnWizardCreate()
    {
        if (textures.Length == 0) return;

        EditorUtility.SaveFilePanelInProject(
            "Save Texture 2DArray", "Texture2DArray", "asset", "Save Texture 2DArray"
        );
        var path = EditorUtility.SaveFilePanelInProject(
            "Save Texture Array", "Texture Array", "asset", "Save Texture Array"
        );
        if (path.Length == 0) return;

        var t = textures[0];
        var textureArray = new Texture2DArray(
            t.width, t.height, textures.Length, t.format, t.mipmapCount > 1
        );
        textureArray.anisoLevel = t.anisoLevel;
        textureArray.filterMode = t.filterMode;
        textureArray.wrapMode = t.wrapMode;

        for (var i = 0; i < textures.Length; i++)
        for (var m = 0; m < t.mipmapCount; m++)
            Graphics.CopyTexture(textures[i], 0, m, textureArray, i, m);
        AssetDatabase.CreateAsset(textureArray, path);
    }

    [MenuItem("Assets/Create/Texture 2DArray")]
    private static void CreateWizard()
    {
        DisplayWizard<TextureArrayWizard>(
            "Create 2D Texture Array", "Create"
        );
    }
}