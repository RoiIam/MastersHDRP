using System;
using System.Globalization;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CustomHDRP.Visualizer
{
    public class VisualizeRange : VisualizeUI
    {
        public ObjectViewer objectViewer;
        public TextMeshProUGUI label;
        public MaterialPropertyData.SerializedGlintsMaterialProperty property;
        public Slider slider;
        public float value;
        public bool isFloat;

        public override void Init(ObjectViewer demo, MaterialPropertyData.SerializedGlintsMaterialProperty p)
        {
            objectViewer = demo;
            property = p;
            label = GetComponentInChildren<TextMeshProUGUI>();
            slider = GetComponentInChildren<Slider>();
            StartValues();
        }

        public override Material GetMatToChange()
        {
            return objectViewer.matToChange;
        }

        public override void StartValues()
        {
            label.text = property.name;

            isFloat = (int)property.intValue == -9999;
            if (isFloat)
                value = GetMatToChange().GetFloat(property.name);
            else
                value = GetMatToChange().GetInt(property.name);

            slider.onValueChanged.AddListener(ChangeVal);
            if (isFloat)
                slider.minValue = property.range.x;
            slider.maxValue = property.range.y;
            slider.value = value;
        }

        private float TestNum(string s)
        {
            float f = 1;
            try
            {
                var nfi = new NumberFormatInfo();
                nfi.NumberDecimalSeparator = ",";
                float.TryParse(s, NumberStyles.Any, nfi, out f);
            }
            catch (Exception e)
            {
                Debug.Log(e);
                return 1;
            }

            return f;
        }

        public void ChangeVal(float f)
        {
            var val = slider.value;
            Debug.Log("range state changed: " + val);

            if (isFloat)
                GetMatToChange().SetFloat(property.name, val);
            else
                GetMatToChange().SetInt(property.name, Mathf.FloorToInt(val));
        }
    }
}