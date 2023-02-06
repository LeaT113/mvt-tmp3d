using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestCamera : MonoBehaviour
{
    public Transform p1;
    public Transform p2;

    private Transform _target;

    private void Awake()
    {
        _target = p1;
    }


    void Update()
    {
        transform.position = Vector3.Lerp(transform.position, _target.position, 0.5f * Time.deltaTime);

        if (Vector3.Distance(transform.position, _target.position) < 0.08f)
        {
            if (_target == p1)
                _target = p2;
            else
                _target = p1;
        }
    }
}
