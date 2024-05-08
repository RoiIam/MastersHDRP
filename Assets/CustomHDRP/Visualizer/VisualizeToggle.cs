using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CustomHDRP.Visualizer
{
    public abstract class VisualizeUI : MonoBehaviour
    {
        public abstract void Init(ObjectViewer demo, MaterialPropertyData.SerializedGlintsMaterialProperty p);
        public abstract void StartValues();
        public abstract Material GetMatToChange();
    }

    public class VisualizeToggle : VisualizeUI
    {
        public ObjectViewer objectViewer;
        public TextMeshProUGUI label;
        public Toggle toggle;
        public bool isFloat;
        public MaterialPropertyData.SerializedGlintsMaterialProperty property;
        private readonly float tolerance = 0.005f;

        public override void Init(ObjectViewer demo, MaterialPropertyData.SerializedGlintsMaterialProperty p)
        {
            objectViewer = demo;
            property = p;
            toggle = GetComponentInChildren<Toggle>();
            label = GetComponentInChildren<TextMeshProUGUI>();
            StartValues();
            isFloat = (int)property.intValue == -9999;
        }

        public override Material GetMatToChange()
        {
            return objectViewer.matToChange;
        }

        public override void StartValues()
        {
            label.text = property.displayName;
            if (isFloat)
                toggle.isOn = Math.Abs(GetMatToChange().GetFloat(property.name) - 1.0) < tolerance;
            else
                toggle.isOn = GetMatToChange().GetInt(property.name) == 1;
            toggle.onValueChanged.AddListener(ChangeVal);
        }

        public void ChangeVal(bool isOn)
        {
            //Debug.Log("Toggle state changed: " + isOn);
            float val = 0;
            if (isOn) val = 1.0f;
            if (isFloat)
                GetMatToChange().SetFloat(property.name, val);
            else
                GetMatToChange().SetInt(property.name, Mathf.FloorToInt(val));
        }
    }
}