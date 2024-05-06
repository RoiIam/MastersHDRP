using System;
using System.Collections.Generic;
using UnityEngine;

namespace CustomHDRP.Visualizer
{
    [Serializable]
    public class MaterialPropertyData : ScriptableObject
    {
        public enum GlintsType
        {
            No,
            Cher,
            De,
            Zirr,
            Wb,
            Wbe
        }

        public enum Type
        {
            Range,
            Float,
            Int,
            Vec
        }

        [SerializeField] public List<SerializedGlintsMaterialProperty> list = new();

        [Serializable]
        public class SerializedGlintsMaterialProperty
        {
            public Type propertyType = Type.Float;
            public GlintsType glintsType = GlintsType.No;
            public string name = "noNameProvidedUSingDefaultSomethingIsWrong";
            public string displayName = "noDisplayNameProvidedUSingDefaultSomethingIsWrong";
            public Vector2 range = new(-9999, -9999);
            public float floatValue = -9999;
            public float intValue = -9999;
            public bool isToggle;
            public Vector4 vecValue = new(-9999, -9999, 0, 0);
        }
    }
}