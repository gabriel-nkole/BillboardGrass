Shader "Custom/Terrain" {
    Properties {
        _Brightness ("Brightness", Range(0, 1)) = 1
        _Ambient ("Ambient", Color) = (0, 0, 0, 1)
        [NoScaleOffset] _MainTex ("Terrain Texture", 2D) = "white" {}
        [NoScaleOffset] _NormalMap ("Normal Map", 2D) = "white" {}
        _TessellationEdgeLength ("Tessellation Edge Length", Range(1,100)) = 100
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "white" {}
        _DispStrength ("Displacement Strength", Range(0,200)) = 100
        _NormalStrength ("Normal Strength", Range(0,10)) = 5
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
            #pragma target 5.0
            #pragma vertex vert
            #pragma hull Hull
            #pragma domain Domain   
            #pragma fragment frag

            #pragma multi_compile_fwdbase
            
            #include "Tessellation.cginc"
            #define IS_IN_BASE_PASS
            #include "Light.cginc"
            ENDCG
        }

        Pass {
            Tags {"LightMode"="ForwardAdd"}
            Blend One One
            
            CGPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma hull Hull
            #pragma domain Domain addshadow
            #pragma fragment frag

            #pragma multi_compile_fwdadd_fullshadows
            
            #include "Tessellation.cginc"
            #include "Light.cginc"
            ENDCG
        }

        Pass {
            Tags {"LightMode"="ShadowCaster"}
            
            CGPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma hull Hull
            #pragma domain Domain
            #pragma fragment frag

            #pragma multi_compile_shadowcaster
            
            #include "Tessellation.cginc"
            #include "Shadow.cginc"
            ENDCG
        }
    }
}