using System;
using System.Globalization;
using TMPro;
using UnityEngine;

namespace CustomHDRP.Visualizer
{
    public class VisualizeFloat : VisualizeUI
    {
        public ObjectViewer objectViewer;
        public TextMeshProUGUI label;
        public MaterialPropertyData.SerializedGlintsMaterialProperty property;
        public TMP_InputField valueText;
        public float value;

        public override void Init(ObjectViewer demo, MaterialPropertyData.SerializedGlintsMaterialProperty p)
        {
            objectViewer = demo;
            property = p;
            valueText = GetComponentInChildren<TMP_InputField>();
            label = GetComponentInChildren<TextMeshProUGUI>();
            StartValues();
        }

        public override Material GetMatToChange()
        {
            return objectViewer.matToChange;
        }

        public override void StartValues()
        {
            label.text = property.name;
            value = GetMatToChange().GetFloat(property.name);
            valueText.text = value.ToString();
            valueText.onValueChanged.AddListener(ChangeVal);
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

        public void ChangeVal(string a)
        {
            var num = TestNum(valueText.text);
            //Debug.Log("float Val changed " + num);
            GetMatToChange().SetFloat(property.name, num);
        }
    }
}