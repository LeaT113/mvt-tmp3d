using System;
using System.Numerics;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UIElements;
using Matrix4x4 = UnityEngine.Matrix4x4;
using Quaternion = UnityEngine.Quaternion;
using Vector2 = UnityEngine.Vector2;
using Vector3 = UnityEngine.Vector3;
using Vector4 = UnityEngine.Vector4;

[ExecuteAlways]
public class TMP_3D : MonoBehaviour
{
    public float depth = 0.5f;
    public float skew = 0;

    public Mesh containerMesh;
    public Material cubeMaterial;
    
    [SerializeField]
    private TextMeshPro _textMeshPro;
    [SerializeField]
    public Mesh tmpMesh;
    
    private MeshFilter _meshFilter;
    private MeshRenderer _meshRenderer;

    private Action<object> _test;

    // 3D Data
    [Serializable]
    public struct LetterData
    {
        public Vector3 center;
        public float width;
        public float height;
        public Matrix4x4 transformMatrix;
        public Vector3 scale;
        public Vector4 uvST;
    }
    private LetterData[] _letters;


    void Awake()
    {
        GetReferences();
        LoadTMPData();
    }

    private void Update()
    {
        DrawMeshes();
    }


    private void DrawMeshes()
    {
        if (_letters is not null && _letters.Length > 0 && containerMesh is not null)
        {
            MaterialPropertyBlock block = new MaterialPropertyBlock();
            block.SetFloat("_Depth", depth);
            for (int i = 0; i < _letters.Length; i++)
            {
                block.SetVector("_BaseMap_ST", _letters[i].uvST);
                block.SetVector("_ObjectScale", _letters[i].scale);
                Graphics.DrawMesh(containerMesh, _letters[i].transformMatrix, cubeMaterial, 0, null, 0, block);
            }
        }
        
    }
    
    private void OnTMPTextChanged(object ob)
    {
        if (ob is not TextMeshPro)
        {
            Debug.Log("OnTMPTextChanged called with invalid argument object");
            return;
        }
        
        LoadTMPData();
    }


    private void LoadTMPData()
    {
        if (tmpMesh.IsDestroyed())
        {
            Debug.Log("TMP Mesh is now null");
            return;
        }

        
        
        int letterCount = tmpMesh.vertexCount / 4;
        _letters = new LetterData[letterCount];

        for (int lIndex = 0; lIndex < letterCount; lIndex++)
        {
            // Get indexes
            int triangleBL = tmpMesh.triangles[lIndex * 6];
            int triangleTL = tmpMesh.triangles[lIndex * 6] + 1;
            int triangleTR = tmpMesh.triangles[lIndex * 6 + 2];
            
            // Get vertices
            Vector3 vertBL = tmpMesh.vertices[triangleBL];
            Vector3 vertTL = tmpMesh.vertices[triangleTL];
            Vector3 vertTR = tmpMesh.vertices[triangleTR];
            
            // Test if letter is empty
            if (vertBL + vertTL + vertTR == Vector3.zero)
                break;

            // Center and size
            LetterData lt = new LetterData();
            lt.center = (vertTR + vertBL) / 2;
            lt.width = Math.Abs(lt.center.x - vertTR.x) * 2;
            lt.height = Math.Abs(lt.center.y - vertTR.y) * 2;
            
            // UV
            Vector2 uvBL = tmpMesh.uv[triangleBL];
            Vector2 uvTL = tmpMesh.uv[triangleTL];
            Vector2 uvTR = tmpMesh.uv[triangleTR];
            lt.uvST = new Vector4(uvTR.x - uvTL.x, uvTL.y - uvBL.y, uvBL.x, uvBL.y);
            
            // Scale
            // if(italics) - measure width differently
            lt.scale = new Vector3(lt.width, lt.height, depth);
            
            lt.transformMatrix = Matrix4x4.identity;
            
            // Scale
            Matrix4x4 opMatrix = Matrix4x4.identity;
            opMatrix.m00 = lt.scale.x;
            opMatrix.m11 = lt.scale.y;
            opMatrix.m22 = lt.scale.z;
            lt.transformMatrix = opMatrix;
            
            // Skew for italics
            opMatrix = Matrix4x4.identity;
            opMatrix.m01 = skew;
            lt.transformMatrix = opMatrix * lt.transformMatrix;
            
            // Translation and rotation
            opMatrix.SetTRS(lt.center, Quaternion.identity, Vector3.one);
            lt.transformMatrix = opMatrix * lt.transformMatrix;
            
            
            _letters[lIndex] = lt;
        }
        
        cubeMaterial.SetTexture("_BaseMap", _textMeshPro.fontMaterial.GetTexture("_MainTex"));
    }
    
    [ContextMenu("Get References")]
    private void GetReferences()
    {
        _test = OnTMPTextChanged;
        TMPro_EventManager.TEXT_CHANGED_EVENT.Add(_test);
        _textMeshPro = GetComponent<TextMeshPro>();
        tmpMesh = _textMeshPro.mesh;
    }


    public void OnDrawGizmos()
    {
        if (_letters is not null)
        {
            Gizmos.color = Color.red;
            foreach(var letter in _letters)
                Gizmos.DrawWireCube(letter.center, new Vector3(letter.width, letter.height, .5f));
        }
    }
}
