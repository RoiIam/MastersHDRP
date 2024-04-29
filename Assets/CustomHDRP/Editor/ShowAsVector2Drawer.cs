using UnityEngine;
using UnityEditor;

//adapted from https://stackoverflow.com/questions/60899301/expose-float2-vector2-property-from-shader-to-unity-material-inspector
//might extend to float 3
//might add constrain with toggle to change all values at once
/// <summary>
/// Draws a vector2 field for vector properties.
/// Usage: [ShowAsVector2] _Vector2("Vector 2", Vector) = (0,0,0,0)
/// </summary>
public class ShowAsVector2Drawer : MaterialPropertyDrawer
{
    bool changeSimultaneously = true;

    // quick but dangerous way to compute needed height
    public override float GetPropertyHeight (MaterialProperty prop, string s, MaterialEditor editor) {
        
        return 40;
    }
    
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        if (prop.type == MaterialProperty.PropType.Vector)
        {
            position.height = 80;
            // Calculate the position for the toggle and the Vector2 field
            Rect toggleRect = new Rect(position.x, position.y+20, position.width+20, 20);
            Rect vector2Rect = new Rect(position.x, position.y, position.width, 20);
            EditorGUI.BeginChangeCheck();
            Vector2 vec = EditorGUI.Vector2Field(vector2Rect, label, prop.vectorValue);
            changeSimultaneously = EditorGUI.Toggle(toggleRect, "\tConstrain X and Y", changeSimultaneously);
            if (EditorGUI.EndChangeCheck())
            {
                if (changeSimultaneously)
                {
                    prop.vectorValue = new Vector4(vec.x, vec.x, prop.vectorValue.z, prop.vectorValue.w);
                }
                else
                {
                    prop.vectorValue = new Vector4(vec.x, vec.y, prop.vectorValue.z, prop.vectorValue.w);
                }
            }
        }
        else
        {
            editor.DefaultShaderProperty(prop, label.text);
        }
    }
}