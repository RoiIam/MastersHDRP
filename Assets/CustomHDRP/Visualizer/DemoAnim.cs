using System;
using UnityEngine;
using UnityEngine.UI;

public class DemoAnim : MonoBehaviour
{
    [SerializeField] private Animator camAnimator;

    [SerializeField] private Slider timeSlider;

    [SerializeField] private Button playPause;

    [SerializeField] private Image buttonSprite;

    [SerializeField] private Sprite play;

    [SerializeField] private Sprite pause;

    [SerializeField] private bool isHolding = false;


    public bool isPlaying = true;

    private AnimatorClipInfo[] currentClipInfo;
    private float len;

    private void Start()
    {
        buttonSprite.sprite = pause;
        isHolding = false;
        currentClipInfo = camAnimator.GetCurrentAnimatorClipInfo(0);
        len = currentClipInfo[0].clip.length;
    }

    private void Update()
    {
        if (Input.GetKeyUp(KeyCode.Space))
        {
            OnPlayPause();
        }
        if(!isHolding)
            timeSlider.value = camAnimator.GetCurrentAnimatorStateInfo(0).normalizedTime % 1;

    }

    public void OnHandleGrab()
    {
        isHolding = true;
    }
    public void OnHandleDrop()
    {
        float dropVal = timeSlider.value;
        camAnimator.Play(currentClipInfo[0].clip.name, 0, dropVal);
        isHolding = false;
    }
    public void OnPlayPause()
    {
        isPlaying = !isPlaying;

        if (isPlaying)
        {
            camAnimator.speed = 1;
            buttonSprite.sprite = pause;
        }
        else
        {
            camAnimator.speed = 0;
            buttonSprite.sprite = play;
        }
    }
}