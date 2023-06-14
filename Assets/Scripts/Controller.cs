using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Controller : MonoBehaviour
{
    [Header("References")]
    public GameObject LightObj;
    public GameObject CharacterObj;
    public GameObject cameraObj;

    [Header("Setting")]
    public float rotationSpeed_Light = 30;
    public float rotationSpeed_Character = 30;
    public float rotationSpeed_Camera = 30;

    bool rotateLightt;
    bool rotateCharacter;
    bool rotateCamera;
    bool closeUp;
    bool cameraPingpong = true;

    float pingpongT = 0;
    void Update()
    {
        if (rotateLightt)
        {
            LightObj.transform.RotateAround(LightObj.transform.position,LightObj.transform.right, Time.deltaTime * rotationSpeed_Light);
        }
        if (rotateCharacter)
        {
            CharacterObj.transform.RotateAround(CharacterObj.transform.position, Vector3.up, Time.deltaTime * rotationSpeed_Character);
        }
        if (rotateCamera)
        {
            cameraObj.transform.RotateAround(CharacterObj.transform.position, cameraObj.transform.up, Time.deltaTime * rotationSpeed_Camera);
        }
        if (closeUp)
        {
            if (cameraPingpong)
            {
                Vector3 pos = cameraObj.transform.position;
                pos.y = Mathf.PingPong(pingpongT, 2);
                cameraObj.transform.position = pos;
                pingpongT += Time.deltaTime * 0.2f; 
            }
        }
    }

    private void OnGUI()
    {
        if (GUILayout.Button("Rotate Light"))
        {
            rotateLightt = !rotateLightt;
        }
        if (GUILayout.Button("Rotate Character"))
        {
            rotateCharacter = !rotateCharacter;
        }
        if (GUILayout.Button("Rotate Camera"))
        {
            rotateCamera = !rotateCamera;
        }
        if (GUILayout.Button("Close Up"))
        {
            closeUp = !closeUp;
            cameraObj.GetComponent<Camera>().fieldOfView = closeUp? 10 : 60;
            Vector3 pos = cameraObj.transform.position;
            if (!closeUp)
            {
                pos.y = 1.2f;
                cameraObj.transform.position = pos;
            }
            else
            {
                pingpongT = pos.y;
            }
        }
        if (closeUp)
        {
            if (GUILayout.Button("Pause Pingpong"))
            {
                cameraPingpong = !cameraPingpong;
            }
        }
    }
}
