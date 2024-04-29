using UnityEditor.Rendering.HighDefinition;

//little hack is used, we inherit from LightingShaderGraphGUI even though it should be LitGUI but that
//was really messy, didnt work as intended. instead we just recreate MaterialUIBlockList
// https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@11.0/manual/hdrp-custom-material-inspector.html
public class CustomLitMaterialInspector : LightingShaderGraphGUI
{
    public CustomLitMaterialInspector()
    {
        // Remove the ShaderGraphUIBlock to avoid having duplicated properties in the UI.
        uiBlocks.RemoveAll(b => b is ShaderGraphUIBlock);
        // For lit GUI we don't display the heightmap nor layering options
        const LitSurfaceInputsUIBlock.Features litSurfaceFeatures = LitSurfaceInputsUIBlock.Features.All ^
                                                                    LitSurfaceInputsUIBlock.Features.HeightMap ^
                                                                    LitSurfaceInputsUIBlock.Features.LayerOptions;
        var uiBlocks2 = new MaterialUIBlockList
        {
            //new SurfaceOptionUIBlock(MaterialUIBlock.ExpandableBit.Base, features: SurfaceOptionUIBlock.Features.Lit),
            new TessellationOptionsUIBlock(MaterialUIBlock.ExpandableBit.Tessellation),
            new LitSurfaceInputsUIBlock(MaterialUIBlock.ExpandableBit.Input, features: litSurfaceFeatures),
            new DetailInputsUIBlock(MaterialUIBlock.ExpandableBit.Detail),
            // We don't want distortion in Lit
            new TransparencyUIBlock(MaterialUIBlock.ExpandableBit.Transparency,
                TransparencyUIBlock.Features.All & ~TransparencyUIBlock.Features.Distortion),
            new EmissionUIBlock(MaterialUIBlock.ExpandableBit.Emissive)
            //new AdvancedOptionsUIBlock(MaterialUIBlock.ExpandableBit.Advance, AdvancedOptionsUIBlock.Features.StandardLit),
        };
        uiBlocks.AddRange(uiBlocks2);
        uiBlocks.Add(new GlintsMethodUIBlock(MaterialUIBlock.ExpandableBit.User0));
    }
}