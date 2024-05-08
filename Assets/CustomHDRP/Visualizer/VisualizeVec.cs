using System;
using System.Globalization;
using TMPro;
using UnityEngine;

namespace CustomHDRP.Visualizer
{
    public class VisualizeVec : VisualizeUI
    {
        public ObjectViewer objectViewer;
        public TextMeshProUGUI label;
        public MaterialPropertyData.SerializedGlintsMaterialProperty property;
        public TMP_InputField[] valueText;

        public override void Init(ObjectViewer demo, MaterialPropertyData.SerializedGlintsMaterialProperty p)
        {
            objectViewer = demo;
            property = p;
            label = GetComponentInChildren<TextMeshProUGUI>();
            valueText = GetComponentsInChildren<TMP_InputField>();
            StartValues();
        }

        public override Material GetMatToChange()
        {
            return objectViewer.matToChange;
        }

        public override void StartValues()
        {
            label.text = property.displayName;
            var init = GetMatToChange().GetVector(property.name);
            foreach (var v in valueText) v.onValueChanged.AddListener(ChangeVal);
            valueText[0].text = init.x.ToString();
            valueText[1].text = init.y.ToString();
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

        public void ChangeVal(string s)
        {
            //Debug.Log("vec state changed: " + s);
            Vector4 val;
            val.x = TestNum(valueText[0].text);
            val.y = TestNum(valueText[1].text);
            val.z = 0;
            val.w = 0;

            GetMatToChange().SetVector(property.name, val);
        }
    }
}