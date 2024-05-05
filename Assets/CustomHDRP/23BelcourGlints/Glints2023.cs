using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Windows;
using Random = UnityEngine.Random;

[ExecuteInEditMode]
public class Glints2023 : MonoBehaviour
{
    [Header("Interface")] public bool resetButton = true;

    public bool generateCustomFile;
    public bool constantRefresh;

    [Header("Noise Settings")] public int noiseTexSize = 512;

    public Texture2D glintNoiseTex;
    private Material glintNoiseInitMaterial;


    private void Start()
    {
        if (constantRefresh)
            ResetEverything();
        //Debug.Log("Start glint");
    }

    private void Update()
    {
        //Debug.Log("update glint");

        if (resetButton) ResetEverything();
#if UNITY_EDITOR

        if (generateCustomFile) GenerateCustomFile();
#endif

#if UNITY_EDITOR
        Shader.SetGlobalTexture("_Glint2023NoiseMap", glintNoiseTex);
        Shader.SetGlobalInt("_Glint2023NoiseMapSize", noiseTexSize);
#endif
    }

    private void OnEnable()
    {
        if (constantRefresh)
            ResetEverything();
        //Debug.Log("onenable glint");
    }

    private void OnDisable()
    {
        //Debug.Log("ondisable glint");
    }


    //[MenuItem("GameObject/CreateNoiseCustom")] //works only if static...
    private void ResetEverything()
    {
        //Debug.Log("reset glint");

        resetButton = false;
        OnDisable();

#if UNITY_EDITOR
        glintNoiseInitMaterial = new Material(Shader.Find("Custom/Glints2023NoiseInit"));
        GenerateGlintNoiseTex();
        glintNoiseTex = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/glint2023Noise.asset");
#endif
        Shader.SetGlobalTexture("_Glint2023NoiseMap", glintNoiseTex);
        Shader.SetGlobalInt("_Glint2023NoiseMapSize", noiseTexSize);
    }

    private float InvCDF(float U, float mu, float sigma)
    {
        var x = sigma * Mathf.Sqrt(2.0f) * ErfInv(2.0f * U - 1.0f) + mu;
        return x;
    }

    private float ErfInv(float x)
    {
        float w, p;
        w = -Mathf.Log((1.0f - x) * (1.0f + x));
        if (w < 5.000000f)
        {
            w = w - 2.500000f;
            p = 2.81022636e-08f;
            p = 3.43273939e-07f + p * w;
            p = -3.5233877e-06f + p * w;
            p = -4.39150654e-06f + p * w;
            p = 0.00021858087f + p * w;
            p = -0.00125372503f + p * w;
            p = -0.00417768164f + p * w;
            p = 0.246640727f + p * w;
            p = 1.50140941f + p * w;
        }
        else
        {
            w = Mathf.Sqrt(w) - 3.000000f;
            p = -0.000200214257f;
            p = 0.000100950558f + p * w;
            p = 0.00134934322f + p * w;
            p = -0.00367342844f + p * w;
            p = 0.00573950773f + p * w;
            p = -0.0076224613f + p * w;
            p = 0.00943887047f + p * w;
            p = 1.00167406f + p * w;
            p = 2.83297682f + p * w;
        }

        return p * x;
    }

    private void GenerateGlintNoiseTex()
    {
        // Generate noise
        var renderTex = new RenderTexture(noiseTexSize, noiseTexSize, 0, RenderTextureFormat.ARGBFloat,
            RenderTextureReadWrite.Linear);
        renderTex.enableRandomWrite = true;
        renderTex.useMipMap = false;
        renderTex.autoGenerateMips = false;
        renderTex.Create();
        glintNoiseInitMaterial.SetVector("_FrameSize", new Vector4(noiseTexSize, noiseTexSize, 0, 0));
        glintNoiseInitMaterial.SetInt("_Seed", (int)(Random.value * 100));
        Graphics.Blit(null, renderTex, glintNoiseInitMaterial);

        // Apply to texture
        glintNoiseTex = new Texture2D(noiseTexSize, noiseTexSize, TextureFormat.RGBAFloat, false, true);
        glintNoiseTex.name = "NoiseMap";
        glintNoiseTex.filterMode = FilterMode.Point;
        glintNoiseTex.anisoLevel = 1;
        glintNoiseTex.wrapMode = TextureWrapMode.Repeat;
        glintNoiseTex.ReadPixels(new Rect(0, 0, noiseTexSize, noiseTexSize), 0, 0);
        glintNoiseTex.Apply(false);

        //if we ever want to export this, uncomment or use the bool
        //GenerateCustomFile();

#if UNITY_EDITOR
        AssetDatabase.CreateAsset(glintNoiseTex, "Assets/glint2023Noise.asset");
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

#endif

        RenderTexture.active = null;
        renderTex.Release();
    }
#if UNITY_EDITOR
    private void SaveToCustomFormat()
    {
        var bytesR = glintNoiseTex.GetRawTextureData();
        //tieto 2  riadky robia to iste len daju iny suffix
        File.WriteAllBytes("Assets/g1.raw", bytesR); //toto je asi tiez ok
        SaveTextureToFile(glintNoiseTex, "Assets/g1.bin"); //toto je ok to pouzivam
        //Debug.Log("Disabled Saving");
        Debug.Log(glintNoiseTex.format);
        Debug.Log(glintNoiseTex.graphicsFormat);
    }

    private void GenerateCustomFile()
    {
        Debug.Log("gen custom file");
        generateCustomFile = false;
        OnDisable();
        SaveToCustomFormat();
    }

    private void SaveTextureToFile(Texture2D texture, string filePath)
    {
        var width = texture.width;
        var height = texture.height;

        // Get the raw texture data
        var pixels = texture.GetPixels();

        // Convert R32G32B32A32_SFloat to bytes
        var data = new byte[width * height * 16]; // 4 floats = 16 bytes per pixel
        var index = 0;
        var tes = 0;
        foreach (var pixel in pixels)
        {
            // Convert each float component to bytes
            var rBytes = BitConverter.GetBytes(pixel.r);
            var gBytes = BitConverter.GetBytes(pixel.g);
            var bBytes = BitConverter.GetBytes(pixel.b);
            var aBytes = BitConverter.GetBytes(pixel.a);
            //Debug.Log($"{pixel.r}  {pixel.g} {pixel.b} {pixel.a} {tes}");
            tes++;
            // Copy bytes to the data array
            Array.Copy(rBytes, 0, data, index, 4);
            Array.Copy(gBytes, 0, data, index + 4, 4);
            Array.Copy(bBytes, 0, data, index + 8, 4);
            Array.Copy(aBytes, 0, data, index + 12, 4);

            index += 16;
        }

        // Save the data to a file
        File.WriteAllBytes(filePath, data);

        Debug.Log("Texture saved to: " + filePath);
    }
#endif
}