using Cinemachine;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CinemachineFreeLook))]
public class FreeLookAddon : MonoBehaviour
{
    [Range(0f, 10f)] public float LookSpeed = 1f;
    [Range(0f, 50f)] public float zoomSpeed = 10f;
    public bool InvertscrollY = true;
    public bool isRMB;
    public bool isLMB;

    [SerializeField] private float minRadTop, maxRadTop, minRadMid, maxRadMid, minRadBot, maxRadBot;

    private CinemachineFreeLook _freeLookComponent;

    public void Start()
    {
        _freeLookComponent = GetComponent<CinemachineFreeLook>();
    }

    public void OnLook(InputAction.CallbackContext context)
    {
        var lookMovement = context.ReadValue<Vector2>().normalized;

        lookMovement.x = lookMovement.x * 180f;
        if (isRMB)
            _freeLookComponent.m_XAxis.Value += lookMovement.x * LookSpeed * Time.deltaTime;

        if (isLMB)
        {
            var scrollVal = context.ReadValue<Vector2>().normalized;
            scrollVal.y = InvertscrollY ? -scrollVal.y : scrollVal.y;
            _freeLookComponent.m_YAxis.Value += scrollVal.y * LookSpeed * Time.deltaTime;
        }
    }

    public void OnZoom(InputAction.CallbackContext context)
    {
        var scrollVal = context.ReadValue<Vector2>().normalized;
        scrollVal.y = InvertscrollY ? -scrollVal.y : scrollVal.y;

        var desiredSpeed = scrollVal.y * zoomSpeed * Time.deltaTime;
        var radTop = _freeLookComponent.m_Orbits[0].m_Radius + desiredSpeed;
        var radMid = _freeLookComponent.m_Orbits[1].m_Radius + desiredSpeed;
        var radBot = _freeLookComponent.m_Orbits[2].m_Radius + desiredSpeed;

        radTop = Mathf.Clamp(radTop, minRadTop, maxRadTop);
        radMid = Mathf.Clamp(radMid, minRadMid, maxRadMid);
        radBot = Mathf.Clamp(radBot, minRadBot, maxRadBot);

        _freeLookComponent.m_Orbits[0].m_Radius = radTop;
        _freeLookComponent.m_Orbits[1].m_Radius = radMid;
        _freeLookComponent.m_Orbits[2].m_Radius = radBot;
    }

    public void OnRMB(InputAction.CallbackContext context)
    {
        isRMB = context.ReadValue<float>() > 0.8 ? true : false;
    }

    public void OnLMB(InputAction.CallbackContext context)
    {
        if (!EventSystem.current.IsPointerOverGameObject())
            isLMB = context.ReadValue<float>() > 0.8 ? true : false;
    }
}