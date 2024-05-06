using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;

[ExecuteInEditMode]
public class MatChanger : MonoBehaviour
{
    private static readonly int GlintsMethod = Shader.PropertyToID("_glintsMethod");
    [Header("tools")] public bool repopulate;
    public bool assignCustom;
    public bool reset;
    public bool moveMats;
    public List<Material> autoAddedMaterials = new();
    public List<Material> manuallyAddedMaterials = new();
    public string targetFolderPath = "Assets/CustomHDRP/Visualizer/Materials";

    [SerializeField] private Shader custom;

    [SerializeField] private Shader def;

    public void ChangeMethod(int i)
    {
        foreach (var material in autoAddedMaterials) material.SetFloat(GlintsMethod, i);
        
        }
#if UNITY_EDITOR

    private void OnEnable()
    {
        //ResetEverything();
        if (custom == null) custom = Shader.Find("HDRP/CustomLit");
        if (def == null) def = Shader.Find("HDRP/Lit");
    }

    private void OnDisable()
    {
    }


    private void MoveMats()
    {
        moveMats = false;

        if (!AssetDatabase.IsValidFolder(targetFolderPath)) AssetDatabase.CreateFolder("Assets", "MyMaterials");

        foreach (var material in autoAddedMaterials)
        {
            var materialPath = AssetDatabase.GetAssetPath(material);
            var newMaterialPath = targetFolderPath + "/" + material.name + ".mat";
            AssetDatabase.MoveAsset(materialPath, newMaterialPath);
        }
    }

    private void Reassign()
    {
        reset = false;
        ChangeShaderForAllMaterials(def);
    }

    private void AssignCustom()
    {
        assignCustom = false;
        ChangeShaderForAllMaterials(custom);
    }

    public void ChangeShaderForAllMaterials(Shader s)
    {
        foreach (var mat in autoAddedMaterials)
        {
            ChangeShader(mat, s);
            HDMaterial.ValidateMaterial(mat);
        }

        foreach (var mat in manuallyAddedMaterials)
        {
            ChangeShader(mat, s);
            HDMaterial.ValidateMaterial(mat);
        }
    }


    private void ResetEverything()
    {
        repopulate = false;
        AssignMaterialsInChildren();
        OnDisable();
    }

    private void Update()
    {
        if (repopulate) ResetEverything();
        if (reset) Reassign();
        if (assignCustom) AssignCustom();
        if (moveMats) MoveMats();
    }

    private void ChangeShader(Material material, Shader s)
    {
        material.shader = s;
    }


    public void AssignMaterialsInChildren()
    {
        var renderers = GetComponentsInChildren<Renderer>();

        autoAddedMaterials.Clear();

        foreach (var renderer in renderers)
        foreach (var material in renderer.sharedMaterials)
            if (!autoAddedMaterials.Contains(material))
                autoAddedMaterials.Add(material);
    }
#endif
}