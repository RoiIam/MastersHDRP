using Cinemachine;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CinemachineFreeLook))]
public class FreeLookAddon : MonoBehaviour
{
    [Range(0f, 10f)] public float LookSpeed = 1f;
    public bool InvertscrollY = true;
    public bool isRMB;
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
    }

    public void OnZoom(InputAction.CallbackContext context)
    {
        var scrollVal = context.ReadValue<Vector2>().normalized;
        scrollVal.y = InvertscrollY ? -scrollVal.y : scrollVal.y;
        _freeLookComponent.m_YAxis.Value += scrollVal.y * LookSpeed * Time.deltaTime;
    }

    public void OnRMB(InputAction.CallbackContext context)
    {
        isRMB = context.ReadValue<float>() > 0.8 ? true : false;
    }
}