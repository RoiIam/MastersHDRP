using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using Cinemachine;
using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace CustomHDRP.Visualizer
{
    public enum GlintMethod
    {
        Chermain20 = 0,
        Deliot23 = 1,
        Zirr16 = 2,
        WangBowles = 3,
        WangBowlesCustom = 4
    }

    public class ObjectViewer : MonoBehaviour
    {
        public enum ViewType
        {
            Single = 0,
            VerticalSplit = 1
        }

        private static readonly int glintsMethodName = Shader.PropertyToID("_glintsMethod");
        private static ObjectViewer objectViewerInstance;

        [SerializeField] private GameObject OptionsPanel;

        [SerializeField] private ViewType viewType = ViewType.VerticalSplit;

        [SerializeField] private Camera leftCam;

        [SerializeField] private Camera rightCam;

        [SerializeField] private Toggle splitToggle;

        [SerializeField] private GameObject splitterLine;

        [SerializeField] private Toggle splitLineToggle;


        [SerializeField] private GameObject leftObj;

        [SerializeField] private GameObject rightObj;

        [SerializeField] private GameObject objectToBeRendered;

        [SerializeField] private MeshListContainer meshListContainer;

        public bool isRMB;

        [SerializeField] private Slider camSpeedSlider;

        [SerializeField] private Slider lightSpeedSlider;

        [SerializeField] private float rotationSpeed = 2;

        [SerializeField] private TMP_InputField RotXField;

        [SerializeField] private TMP_InputField RotYField;

        [SerializeField] private TMP_InputField RotZField;


        [SerializeField] private TMP_InputField ScaleXField;

        [SerializeField] private TMP_InputField ScaleYField;

        [SerializeField] private TMP_InputField ScaleZField;


        [SerializeField] private Button changeScene;
        [SerializeField] private GameObject timelineUI;
        [SerializeField] private GameObject OptionsPanelUI;
        [SerializeField] private GameObject FPSHolder;

        [SerializeField] private int scenesCount = 2; //should be accesed from buildIndex

        [SerializeField] private string leftObjName = "LeftObj";

        [SerializeField] private PlayerInput playerInput;
        [SerializeField] private Texture2DArray dict;

        [SerializeField] private GameObject changeAllButtonsHolder;

        //UI for glints parameters
        public Material matToChange;
        public MaterialPropertyData materialPropertyData;
        public GameObject cher;
        public GameObject del;
        public GameObject zirr;
        public GameObject wang;
        public GameObject wbe;

        public GameObject uiRange;
        public GameObject uiFloat;
        public GameObject uiInt;
        public GameObject uiVec;
        public GameObject uiToggle;

        public GameObject leftEditButton;
        public GameObject rightEditButton;

        public List<VisualizeUI> visualizeUI = new();


        private bool animateCam;
        private bool animateLight;

        private CinemachineFreeLook cinemachineFreeLookLeft;
        private CinemachineFreeLook cinemachineFreeLookRight;


        private Light customLight;


        private Material leftMat;

        private MeshFilter leftObjMeshFilter;
        private Vector3 lightColor;
        private Vector3 lightDirection;
        private float lightIntensity;
        private Vector3 lightPosition; //not for directional
        private int meshListContainerIndex;
        private GameObject objectToBeRenderedClone;
        private Material rightMat;
        private MeshFilter rightObjMeshFilter;
        private int sceneIndex;

        private void Awake()
        {
            DontDestroyOnLoad(this);
            CycleScene();
            SetAllActive(false);
        }

        private void Start()
        {
            if (playerInput == null)
                playerInput = GetComponentInChildren<PlayerInput>();

            //SetupScene();
        }

        // Update is called once per frame
        private void Update()
        {
            switch (viewType)
            {
                case ViewType.Single:
                    break;
                case ViewType.VerticalSplit:
                    RenderObjectsCopy();
                    break;
            }

            if (animateCam && !isRMB)
            {
                cinemachineFreeLookLeft.m_XAxis.Value += rotationSpeed * camSpeedSlider.value * Time.deltaTime;
                cinemachineFreeLookRight.m_XAxis.Value += rotationSpeed * camSpeedSlider.value * Time.deltaTime;
            }

            if (Input.GetKeyUp(KeyCode.F1))
            {
                var active = !OptionsPanel.activeSelf;
                OptionsPanel.SetActive(active);
                FPSHolder.SetActive(active);
            }
        }

        public void DisableParticles()
        {
            if (timelineUI)
                timelineUI.GetComponent<DemoAnim>().OnParticlesAnim();
        }

        public void SetupScene()
        {
            switch (sceneIndex)
            {
                case 1:
                    playerInput.gameObject.SetActive(false);
                    timelineUI = GameObject.Find("TimelineUI");
                    OptionsPanelUI.SetActive(false);
                    timelineUI.SetActive(true);
                    changeAllButtonsHolder.SetActive(true);

                    break;
                case 2:
                    playerInput.gameObject.SetActive(true);
                    leftCam.gameObject.SetActive(true);
                    rightCam.gameObject.SetActive(true);
                    changeAllButtonsHolder.SetActive(false);
                    OptionsPanelUI.SetActive(true);
                    SetupSecondScene();
                    break;
            }
        }

        public void SetupSecondScene()
        {
            if (sceneIndex == 2)
            {
                leftObj = GameObject.Find(leftObjName);

                leftMat = leftObj.GetComponent<Renderer>().material;
                leftObjMeshFilter = leftObj.GetComponent<MeshFilter>();

                cinemachineFreeLookLeft = leftCam.gameObject.GetComponent<CinemachineFreeLook>();
                cinemachineFreeLookLeft.LookAt = leftObj.transform;
                cinemachineFreeLookLeft.Follow = leftObj.transform;

                CreateRightCopies();
                EditLeftMat();
                CreateParamsUI();
                StartCoroutine(WaitForFrame());
            }
        }

        public void CreateParamsUI()
        {
            foreach (var m in materialPropertyData.list)
                //if(m.glintsType == (MaterialPropertyData.GlintsType)matToChange.GetFloat(glintsMethodName))
            {
                GameObject parent;
                switch (m.glintsType)
                {
                    case MaterialPropertyData.GlintsType.Cher:
                        parent = cher;
                        break;
                    case MaterialPropertyData.GlintsType.De:
                        parent = del;
                        break;
                    case MaterialPropertyData.GlintsType.Zirr:
                        parent = zirr;
                        break;
                    case MaterialPropertyData.GlintsType.Wb:
                        parent = wang;
                        break;
                    case MaterialPropertyData.GlintsType.Wbe:
                        parent = wbe;
                        break;
                    default:
                        parent = cher;
                        break;
                }

                AddToGameObject(m, parent);
            }
        }

        public void AddToGameObject(MaterialPropertyData.SerializedGlintsMaterialProperty m, GameObject parent)
        {
            GameObject g;
            var t = m.propertyType;
            switch (t)
            {
                case MaterialPropertyData.Type.Range:
                    g = Instantiate(uiRange, parent.transform);
                    break;
                case MaterialPropertyData.Type.Float:
                    if (m.isToggle)
                        g = Instantiate(uiToggle, parent.transform);
                    else
                        g = Instantiate(uiFloat, parent.transform);

                    break;
                case MaterialPropertyData.Type.Int:
                    if (m.isToggle)
                        g = Instantiate(uiToggle, parent.transform);
                    else
                        g = Instantiate(uiInt, parent.transform);
                    break;
                case MaterialPropertyData.Type.Vec:
                    g = Instantiate(uiVec, parent.transform);
                    break;
                default:
                    g = Instantiate(uiRange, parent.transform);
                    Debug.Log("unknown MaterialPropertyData type");
                    break;
            }

            var v = g.GetComponent<VisualizeUI>();
            v.Init(this, m);
            visualizeUI.Add(v);
        }

        public void ChangeLeft(int glintGlintMethod)
        {
            if (matToChange == leftMat)
            {
                leftMat.SetFloat(glintsMethodName, (float)glintGlintMethod + 1);
                ChangeUI(true);
            }
            else
            {
                rightMat.SetFloat(glintsMethodName, (float)glintGlintMethod + 1);
                ChangeUI(false);
            }
        }

        private void EnableControls()
        {
            RotXField.gameObject.transform.parent.gameObject.SetActive(true);
            ScaleXField.gameObject.transform.parent.gameObject.SetActive(true);

            RotXField.text = leftObj.transform.localEulerAngles.x.ToString();
            RotYField.text = leftObj.transform.localEulerAngles.y.ToString();
            RotZField.text = leftObj.transform.localEulerAngles.z.ToString();

            ScaleXField.text = "1";
            ScaleYField.text = "1";
            ScaleZField.text = "1";
        }

        private IEnumerator WaitForFrame()
        {
            yield return 0;
            leftCam.gameObject.GetComponent<CinemachineBrain>().enabled = true;
            rightCam.gameObject.GetComponent<CinemachineBrain>().enabled = true;
            EnableControls();
        }

        public void CycleMeshes()
        {
            //meshListContainerIndex += 1;
            meshListContainerIndex = ++meshListContainerIndex % meshListContainer.GetMeshes().Count;

            leftObjMeshFilter.mesh = meshListContainer.GetMeshes()[meshListContainerIndex];
            rightObjMeshFilter.mesh = meshListContainer.GetMeshes()[meshListContainerIndex];
        }

        public void CreateRightCopies()
        {
            //create copies of objects and lights in scene
            //set its layer to left View (main Cam)

            // Duplicate the original object
            rightObj = Instantiate(leftObj, leftObj.transform.position, leftObj.transform.rotation);
            rightObj.layer = LayerMask.NameToLayer("RightView");
            // Get the Renderer component of the duplicate object
            var renderer = rightObj.GetComponent<Renderer>();

            // Check if the Renderer component exists and if a material is assigned
            if (renderer != null && renderer.sharedMaterial != null)
            {
                // Create a new material instance based on the specified material
                rightMat = new Material(leftMat);

                // Assign the new material instance to the duplicate object
                renderer.material = rightMat;


                viewType = ViewType.Single;
                leftCam.enabled = true;
                rightCam.enabled = true;
                splitToggle.isOn = false;
                CycleForward(viewType);
                SetViewParams(viewType);
            }

            rightObjMeshFilter = rightObj.GetComponent<MeshFilter>();
            cinemachineFreeLookRight = rightCam.gameObject.GetComponent<CinemachineFreeLook>();
            cinemachineFreeLookRight.LookAt = rightObj.transform;
            cinemachineFreeLookRight.Follow = rightObj.transform;
        }

        public void RenderObjectsCopy()
        {
            //duplicate changes made in the first view to the second 
        }

        public void OnChangeView()
        {
            CycleForward(viewType);
            SetViewParams(viewType);
        }

        public void OnSplitLineChange()
        {
            splitterLine.SetActive(splitLineToggle.isOn);
        }

        public void OnRotateCam()
        {
            animateCam = !animateCam;
        }

        public void OnRotateLight()
        {
            animateLight = !animateLight;
        }

        public void OnRMB(InputAction.CallbackContext context)
        {
            isRMB = context.ReadValue<float>() > 0.8 ? true : false;
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

        public void OnRotationChange()
        {
            var x = TestNum(RotXField.text);
            var y = TestNum(RotYField.text);
            var z = TestNum(RotZField.text);

            leftObj.transform.localEulerAngles = new Vector3(x, y, z);
            rightObj.transform.localEulerAngles = leftObj.transform.localEulerAngles;
        }

        public void OnScaleChange()
        {
            var x = TestNum(ScaleXField.text);
            var y = TestNum(ScaleYField.text);
            var z = TestNum(ScaleZField.text);

            leftObj.transform.localScale = new Vector3(x, y, z);
            rightObj.transform.localScale = leftObj.transform.localScale;
        }

        public void CycleForward(ViewType val)
        {
            var currentIndex = (int)val;
            var nextIndex = (currentIndex + 1) % Enum.GetValues(typeof(ViewType)).Length;
            viewType = (ViewType)nextIndex;
        }

        public void CycleScene()
        {
            sceneIndex = sceneIndex % scenesCount;
            sceneIndex++;
            StartCoroutine(LoadSceneAsync());
            //Debug.Log(sceneIndex);
        }

        public IEnumerator LoadSceneAsync()
        {
            var asyncLoad = SceneManager.LoadSceneAsync(sceneIndex);

            while (!asyncLoad.isDone) yield return null;
            SetupScene();
        }

        public void OnMatChange(int m)
        {
            timelineUI.GetComponent<DemoAnim>().ChangeMat(m + 1);
        }

        private void SetViewParams(ViewType viewType)
        {
            switch (viewType)
            {
                case ViewType.Single:
                    rightCam.enabled = false;
                    splitLineToggle.gameObject.SetActive(false);
                    splitLineToggle.isOn = false;
                    splitterLine.SetActive(false);
                    EditLeftMat();
                    rightEditButton.SetActive(false);
                    var l = leftCam.rect;
                    leftCam.rect = new Rect(0, l.y, 1.0f, l.height);
                    break;
                case ViewType.VerticalSplit:
                    var r = leftCam.rect;
                    leftCam.rect = new Rect(0, r.y, 0.5f, r.height);
                    rightCam.enabled = true;
                    splitLineToggle.gameObject.SetActive(true);
                    splitLineToggle.isOn = true;
                    splitterLine.SetActive(true);
                    rightEditButton.SetActive(true);
                    break;
            }
        }

        public void OnLeftChange()
        {
            matToChange = leftMat;
            ChangeUI(true);
        }

        public void OnRightChange()
        {
            matToChange = rightMat;
            ChangeUI(false);
        }

        public void ChangeUI(bool isLeft)
        {
            MaterialPropertyData.GlintsType glintsType;
            if (isLeft)
                glintsType = (MaterialPropertyData.GlintsType)leftMat.GetFloat(glintsMethodName);
            else
                glintsType = (MaterialPropertyData.GlintsType)rightMat.GetFloat(glintsMethodName);
            SetAllActive(false);
            switch (glintsType)
            {
                case MaterialPropertyData.GlintsType.No:
                    break;
                case MaterialPropertyData.GlintsType.Cher:
                    cher.SetActive(true);
                    break;
                case MaterialPropertyData.GlintsType.De:
                    del.SetActive(true);
                    break;
                case MaterialPropertyData.GlintsType.Zirr:
                    zirr.SetActive(true);
                    break;
                case MaterialPropertyData.GlintsType.Wb:
                    wang.SetActive(true);
                    break;
                case MaterialPropertyData.GlintsType.Wbe:
                    wang.SetActive(true);
                    wbe.SetActive(true);
                    break;
                default:
                    Debug.Log("unknown type");
                    break;
            }
        }

        public void SetAllActive(bool active)
        {
            cher.SetActive(active);
            del.SetActive(active);
            zirr.SetActive(active);
            wang.SetActive(active);
            wbe.SetActive(active);
        }

        public void RecalcUI()
        {
            foreach (var v in visualizeUI)
                if (v.isActiveAndEnabled)
                    v.StartValues();
        }

        public void EditLeftMat()
        {
            matToChange = leftMat;
            leftEditButton.GetComponent<Button>().image.color = Color.green;
            rightEditButton.GetComponent<Button>().image.color = Color.white;
            leftEditButton.GetComponent<Button>().enabled = false;
            rightEditButton.GetComponent<Button>().enabled = true;
            ChangeUI(true);
            RecalcUI();
        }

        public void EditRightMat()
        {
            matToChange = rightMat;
            rightEditButton.GetComponent<Button>().image.color = Color.green;
            leftEditButton.GetComponent<Button>().image.color = Color.white;
            rightEditButton.GetComponent<Button>().enabled = false;
            leftEditButton.GetComponent<Button>().enabled = true;
            ChangeUI(false);
            RecalcUI();
        }
    }
}