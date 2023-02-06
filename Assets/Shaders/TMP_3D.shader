Shader "TMP_3D Shader"
{


    Properties
    {
        _BaseMap ("Font Texture", 2D) = "white" {}
        _DistScale ("Dist scale", float) = 1
        _Weight("Weight", float) = 0.5
        
        _FaceColor("Face Color", color) = (1,1,1)
        _SideColor("Face Color", color) = (.7, .7, .7)
        
        _TestSlice("Test Slice", float) = 0
        _Depth("Depth", float) = 0.5

    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100
        Cull Back
        BLend Off
        ZWrite Off // TODO work out


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include <HLSLSupport.cginc>
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Defines
            #define MAX_RAYMARCH_STEPS 120
            #define RAYMARCH_EPSILON 0.01
            #define AO_RAYMARCH_STEPS 2

            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerObject)
                float4 _BaseMap_ST;
                float3 _ObjectScale; // For correction to world scale
                float _Depth; // Depth of letters

                float _DistScale;
                float _Weight;
                float _TestSlice;
                half3 _FaceColor;
                half3 _SideColor;
            CBUFFER_END

            
            // Functions
            float2 GetUVAtPos(float3 pos)
            {
                float2 uvPos = pos.xy + float2(0.5, 0.5); 
                return uvPos * _BaseMap_ST.xy + _BaseMap_ST.zw;
            }
            
            // Returns distance to scene from point in unit scale local space
            float GetSceneDistance(float3 pos)
            {
                float2 uv = GetUVAtPos(pos);
                float texA = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap, uv).a;
                
                return saturate(texA - _Weight);
            }

            // Rendering
            float3 NormalVector(float3 uniScalePosLS)
            {
                float epsilon = 0.02f;
                
                float centerDistance = GetSceneDistance(uniScalePosLS);
                float xDistance = GetSceneDistance(uniScalePosLS + float3(epsilon, 0, 0));
                float yDistance = GetSceneDistance(uniScalePosLS + float3(0, epsilon, 0));
                float zDistance = GetSceneDistance(uniScalePosLS + float3(0, 0, epsilon));
                
                float3 normal = (float3(xDistance, yDistance, zDistance) - centerDistance) / epsilon;
                
                return normalize(normal);
            }
            float AmbientOcclusion(float3 uniScalePosLS, float3 normal)
            {
                float sum = 0;
                float maxSum = 0;
                
                float aoStepSize = 0.3 / AO_RAYMARCH_STEPS;
                for (int i = 0; i < AO_RAYMARCH_STEPS; i ++)
                {
                    float3 p = uniScalePosLS + normal * (i+1) * aoStepSize;
                    
                    sum    += 1.0 / pow(2.0, i) * clamp(GetSceneDistance(p), 0, 1);
                    maxSum += 1.0 / pow(2.0, i) * (i+1) * aoStepSize;
                }
                
                return saturate(sum / maxSum);
            }


            
            struct Attributes
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varying
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 posLS    : TEXCOORD1;
                float3 viewDirLS : TEXCOORD2;

                UNITY_VERTEX_OUTPUT_STEREO
            };


            Varying vert(Attributes IN)
            {
                Varying OUT;

                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_OUTPUT(Varying, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.vertex = TransformObjectToHClip(IN.vertex);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                OUT.posLS = IN.vertex;
                float3 viewDirWS = -(_WorldSpaceCameraPos - TransformObjectToWorld(IN.vertex)).xyz;
                OUT.viewDirLS = TransformWorldToObjectDir(viewDirWS, false).xyz;

                return OUT;
            }


            half4 frag(Varying IN) : SV_Target
            {
                // Raymarching in scale-unified local space
                const float3 viewDirUniScaleLS = IN.viewDirLS;// * _ObjectScale;
                const float3 rayOrig = IN.posLS;;
                const float3 rayDir = normalize(viewDirUniScaleLS);

                float rayLen = 0.001;
                half hit = 0;
                float3 rayPos;
                for (int s = 0; s < MAX_RAYMARCH_STEPS; s++)
				{
                    rayPos = rayOrig + rayDir * rayLen;
                    float dist = 1 - GetSceneDistance(rayPos) * _DistScale;
                    rayLen += 0.01;

                    // Hit letter
                    if(dist < RAYMARCH_EPSILON)
                    {
                        hit = 1;
                        break;
                    }
                    

                    // Out of letter bounds
                    float maxAxisPos = max(rayPos.x, rayPos.y);
                    float minAxisPos = min(rayPos.x, rayPos.y);
                    if(maxAxisPos > 0.5 || minAxisPos < -0.5)
                        break;

                    // Depth reached
                    if(abs(rayPos.z) > 0.5)
                        break;
                    
                    //if(abs(rayDir.z * rayLen) > 0.5)
                    //    return half4(1, 0, 0, 1);
				}
                clip(hit - 0.5);

                half3 normal = NormalVector(rayPos) ;
                float aoTerm = AmbientOcclusion(rayPos, normal);

                //return aoTerm;
                //return half4(normal, 1);
                
                half4 baseColor = half4(abs(rayPos.z) > 0.48 ? _FaceColor : _SideColor, 1);
                return baseColor;

                return aoTerm;
                
                return half4((rayPos.zzz + 0.5)*(rayPos.zzz + 0.5), 1);
                
                return half4(1, 0.25, 0.5, 1);
            }


            
            
            ENDHLSL
        }
    }
}