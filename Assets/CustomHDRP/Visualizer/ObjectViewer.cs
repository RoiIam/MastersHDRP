using System;
using System.Collections;
using System.Globalization;
using Cinemachine;
using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class ObjectViewer : MonoBehaviour
{
    public enum GlintMethod
    {
        Chermain20 = 0,
        Deliot23 = 1,
        Zirr16 = 2,
        WangBowles = 3,
        WangBowlesCustom = 4
    }

    public enum ViewType
    {
        Single = 0,
        VerticalSplit = 1
    }

    private static readonly int GlintsMethod = Shader.PropertyToID("_glintsMethod");

    [SerializeField] private GameObject OptionsPanel;

    [SerializeField] private ViewType viewType = ViewType.VerticalSplit;

    [SerializeField] private Camera leftCam;

    [SerializeField] private Camera rightCam;

    [SerializeField] private Toggle splitToggle;

    [SerializeField] private GameObject splitterLine;

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
    
    
    [SerializeField] private Button changeScene;
    [SerializeField] private GameObject timelineUI;
    [SerializeField] private GameObject splitterUI;

    [SerializeField]  private int scenesCount = 2;//should be accesed from buildIndex
    private int sceneIndex = 0;
    
    [SerializeField] private string leftObjName = "LeftObj";
    [SerializeField] private string rightObjName = "RightObj";

    // Start is called before the first frame update
    private void Start()
    {
        SetupScene();
        DontDestroyOnLoad(this);
    }

    public void SetupScene()
    {
        switch (sceneIndex)
        {
            
            case 0:
                timelineUI = GameObject.Find("TimelineUI");
                splitterUI.SetActive(false);
                timelineUI.SetActive(true);
                break;
            case 1:
                //splitterUI = GameObject.Find("TimelineUI");
                splitterUI.SetActive(true);
                SetupSecondScene();
                break;
            default:
                break;
                
        }
    }
    
    public void SetupSecondScene()
    {
        if (sceneIndex == 1)
        {
            
            leftObj = GameObject.Find(leftObjName);
            rightObj = GameObject.Find(rightObjName);
            leftCam = GameObject.Find("LeftCam").GetComponent<Camera>();
            rightCam = GameObject.Find("RightCam").GetComponent<Camera>();
            

            leftMat = leftObj.GetComponent<Renderer>().material;
            rightMat = rightObj.GetComponent<Renderer>().material;
            leftObjMeshFilter = leftObj.GetComponent<MeshFilter>();
            rightObjMeshFilter = rightObj.GetComponent<MeshFilter>();

            cinemachineFreeLookLeft = leftCam.gameObject.GetComponent<CinemachineFreeLook>();
            cinemachineFreeLookRight = rightCam.gameObject.GetComponent<CinemachineFreeLook>();
            CreateRightCopies();


            StartCoroutine(WaitForFrame());
        }
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

        if (Input.GetKeyUp(KeyCode.F1)) OptionsPanel.SetActive(!OptionsPanel.activeSelf);
    }

    public void ChangeLeft(int glintGlintMethod)
    {
        leftMat.SetFloat(GlintsMethod, (float)glintGlintMethod + 1);
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
        viewType = ViewType.Single;
        leftCam.enabled = true;
        rightCam.enabled = true;
        splitToggle.isOn = false;
        CycleForward(viewType);
        SetViewParams(viewType);
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
        splitterLine.SetActive(!splitterLine.activeSelf);
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
        sceneIndex = ++sceneIndex % (scenesCount);
        StartCoroutine(LoadSceneAsync());

    }

    public IEnumerator LoadSceneAsync()
    {
        AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneIndex);

        while (!asyncLoad.isDone)
        {
            yield return null;

        }
        SetupScene();

        
    }


    private void SetViewParams(ViewType viewType)
    {
        switch (viewType)
        {
            case ViewType.Single:
                rightCam.enabled = false;
                splitterLine.SetActive(false);
                var l = leftCam.rect;
                leftCam.rect = new Rect(0, l.y, 1.0f, l.height);
                break;
            case ViewType.VerticalSplit:
                var r = leftCam.rect;
                leftCam.rect = new Rect(0, r.y, 0.5f, r.height);
                rightCam.enabled = true;
                splitterLine.SetActive(true);
                break;
        }
    }
}