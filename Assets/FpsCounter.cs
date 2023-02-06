using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FpsCounter : MonoBehaviour
{
    private const int his = 15;
    private Text _text;
    private Queue<int> fpsHistory = new Queue<int>(his);

    void Start()
    {
        _text = GetComponent<Text>();
    }

    // Update is called once per frame
    void Update()
    {
        fpsHistory.Enqueue((int)(1f / Time.unscaledDeltaTime));
        
        if (fpsHistory.Count < his)
            return;

        fpsHistory.Dequeue();
        
        var x = fpsHistory.ToArray();
        int sum = 0;
        foreach (var f in x)
            sum += f;
        sum /= his;
        _text.text = "FPS: " + sum;
    }
}
