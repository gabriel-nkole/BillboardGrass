// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Custom/Grass" {
    Properties {
        _WindStrength ("Wind Strength", Range(0,2)) = 0.75
        _LODCutoff ("LOD Cutoff", Range(10,500)) = 500
        _CullingBias ("Culling Bias", Range(0.1, 2)) = 0.1
        [NoScaleOffset] _GrassTex ("Grass Texture", 2D) = "white" {}
        _OcclusionExponent ("Occlusion Exponent", Range(0, 1)) = 0.25
    }

    SubShader {
        Cull Off
        ZWrite On

        Pass {
            Tags {"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
		    #pragma target 4.5

            #pragma multi_compile_fwdbase

            #include "Grass_Light.cginc"
            ENDCG
        }

        Pass {
            Tags {"LightMode"="ForwardAdd"}
            Blend One One

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
		    #pragma target 4.5

            #pragma multi_compile_fwdadd

            #include "Grass_Light.cginc"
            ENDCG
        }

        Pass {
            Tags {"Lightmode"="ShadowCaster"}
            
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma target 4.5

            #pragma multi_compile_shadowcaster
            
            #include "Grass_Shadow.cginc"
            ENDCG
        }
    }
}