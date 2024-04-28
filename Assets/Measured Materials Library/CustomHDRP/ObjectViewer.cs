using System;
using System.Collections;
using System.Collections.Generic;
using Cinemachine;
using UnityEngine;
using UnityEngine.UI;

public class ObjectViewer : MonoBehaviour
{
    public enum ViewType
    {
      Single =0, VerticalSplit = 1  
    }
    
    [SerializeField]
    private ViewType viewType = ViewType.VerticalSplit;
    [SerializeField]
    private Camera leftCam;
    [SerializeField]
    private Camera rightCam;

    [SerializeField]
    private Toggle splitToggle;
    [SerializeField]
    private GameObject splitterLine;
    
    
    [SerializeField]
    private GameObject objectToBeRendered;
    private GameObject objectToBeRenderedClone;
    
    private Light light;
    private Vector3 lightColor;
    private Vector3 lightPosition;//not for directional
    private Vector3 lightDirection;
    private float lightIntensity;

    
    
    // Start is called before the first frame update
    void Start()
    {
        CreateRightCopies();
        leftCam.gameObject.GetComponent<CinemachineBrain>().enabled = true;
        rightCam.gameObject.GetComponent<CinemachineBrain>().enabled = true;
    }
    
    public void CreateRightCopies()
    {
        //create copies of objects and lights in scene
        //set its layer to left View (main Cam)
        viewType = ViewType.Single;
        leftCam.enabled = true;
        rightCam.enabled = true;
        splitToggle.isOn = false;
        splitterLine.SetActive(false);
        CycleForward(viewType);
        SetViewParams(viewType);
        
    }

    // Update is called once per frame
    void Update()
    {
        switch (viewType)
        {
            case ViewType.Single:
                break;
            case ViewType.VerticalSplit:
                RenderObjectsCopy();
                break;
            default:
                break;
        }
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

    public void CycleForward(ViewType val)
    {
        int currentIndex = (int)val;
        int nextIndex = (currentIndex + 1) % Enum.GetValues(typeof(ViewType)).Length;
        viewType= (ViewType)nextIndex;
    }
        private void SetViewParams(ViewType viewType)
    {
        switch (viewType)
        {
            case ViewType.Single:
                rightCam.enabled = false;
                splitterLine.SetActive(false);
                Rect l = leftCam.rect;
                leftCam.rect = new Rect(0, l.y, l.width, l.height);
                break;
            case ViewType.VerticalSplit:
                Rect r = leftCam.rect;
                leftCam.rect = new Rect(-0.5f, r.y, r.width, r.height);
                rightCam.enabled = true;
                splitterLine.SetActive(true);
                break;
            default:
                break;
        }
    }
}
