Shader "Custom/Terrain" {
    Properties {
        _TessellationEdgeLength ("Tessellation Edge Length", Range(1,100)) = 100
        _DispStrength ("Displacement Strength", Range(0,200)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "white" {}
        _Brightness ("Brightness", Range(0, 1)) = 0.7
        [NoScaleOffset] _AlbedoMap ("Terrain Texture", 2D) = "white" {}
        _NormalStrength ("Normal Strength", Range(0,10)) = 0.53
        [NoScaleOffset] _NormalMap ("Normal Map", 2D) = "white" {}
        _Ambient ("Ambient Light", Color) = (0.08679241, 0.08679241, 0.08679241, 1)
    }

    SubShader {
        Tags { 
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }
        Cull Off

        Pass {
            Tags {"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain   
            #pragma fragment Fragment
            #pragma target 4.5

            #pragma multi_compile_fwdbase
            
            #include "Terrain_Tessellation.cginc"
            #define IS_IN_BASE_PASS
            #include "Terrain_Light.cginc"
            ENDCG
        }

        Pass {
            Tags {"LightMode"="ForwardAdd"}
            Blend One One
            
            CGPROGRAM
            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain addshadow
            #pragma fragment Fragment
            #pragma target 4.5

            #pragma multi_compile_fwdadd_fullshadows
            
            #include "Terrain_Tessellation.cginc"
            #include "Terrain_Light.cginc"
            ENDCG
        }

        Pass {
            Tags {"LightMode"="ShadowCaster"}
            
            CGPROGRAM
            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain
            #pragma fragment Fragment
            #pragma target 4.5

            #pragma multi_compile_shadowcaster
            
            #include "Terrain_Tessellation.cginc"
            #include "Terrain_Shadow.cginc"
            ENDCG
        }
    }
}