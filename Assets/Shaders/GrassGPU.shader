// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Custom/GrassGPU" {
    Properties {
        [NoScaleOffset] _GrassTex ("Grass Texture", 2D) = "white" {}
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "white" {}
        _DispStrength ("Displacement Strength", Range(0, 200)) = 100
        _WindStrength ("Wind Strength", Range(0,2)) = 1
        _LODCutoff ("LOD Cutoff", Range(10,500)) = 100
        _CullingBias ("Culling Bias", Range(0.1, 1)) = 0.5
        _OcclusionExponent ("Occlusion Exponent", Range(0, 1)) = 0.2
    }
    SubShader {
        Cull Off
        ZWrite On

        Pass{
            Tags {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
		    #pragma target 4.5
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "../Resources/TRS.cginc"
            #include "../Resources/Simplex.compute"
            #include "../Resources/Random.cginc"


            struct MeshData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct Interpolators {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float saturationLevel : TEXCOORD1;
                LIGHTING_COORDS(2,3)
            };


            sampler2D _GrassTex;
            sampler2D _HeightMap;

            float _Resolution;
            float _Density;
            float4x4 _ParentToWorld;
            float _Angle;

            float _DispStrength;

            float _WindStrength;

            float _LODCutoff;
            float _CullingBias;

            float _OcclusionExponent;


            bool VertexIsBelowClipPlane (float3 p, int planeIndex, float bias){
	            float4 plane = unity_CameraWorldClipPlanes[planeIndex];
	            return dot(float4(p, 1), plane) < bias;
            }

            bool cullVertex (float3 p, float bias){
	            return distance(_WorldSpaceCameraPos, p) > _LODCutoff ||
                       VertexIsBelowClipPlane(p, 0, bias) ||
		               VertexIsBelowClipPlane(p, 1, bias) ||
		               VertexIsBelowClipPlane(p, 2, bias) ||
		               VertexIsBelowClipPlane(p, 3, -max(1.0, _DispStrength));
            }


            Interpolators vert (MeshData v, uint instanceID : SV_InstanceID) {
                Interpolators o;
                //xz position
                uint2 id = uint2(instanceID % (uint)_Resolution, instanceID / (uint)_Resolution);
                float2 posXZ = (id - 0.5 * (_Resolution - 1.0))/_Density;

                //grass height
                float noise = abs(snoise(float3(posXZ, 0) * 0.2));
                float grassHeight = lerp(0.6, 2, noise);


                //wind animation
                float localWindVariance = min(max(0.4f, randValue(instanceID)), 0.75f);
                
                float cosTime;
                if (localWindVariance > 0.6f)
                    cosTime = cos(_Time.y * (_WindStrength - (grassHeight - 1.0f)));
                else
                    cosTime = cos(_Time.y * ((_WindStrength - (grassHeight - 1.0f)) + localWindVariance * 0.1f));
                    
                
                float trigValue = ((cosTime * cosTime) * 0.65f) - localWindVariance * 0.5f;
                
                v.vertex.x += v.uv.y * trigValue * grassHeight * localWindVariance * 0.6f;
                v.vertex.z += v.uv.y * trigValue * grassHeight * 0.4f;


                //vertical displacement
                //(wPos.x - left edge)/(Resolution/Density)      (wPos.z - bottom edge)/(Resolution/Density)
                float2 uv = (posXZ + 0.5*_Resolution/_Density) * (_Density/_Resolution);
                float vertDisp = tex2Dlod(_HeightMap, float4(uv, 0, 0)).x * _DispStrength;

                float3 translation = float3(posXZ.x, vertDisp + 0.5*grassHeight, posXZ.y);
                translation.x += snoise(float3(posXZ, 0.0) * 3.0) * 0.4;
                translation.z += snoise(float3(posXZ, 0.0) * 4.0) * 0.4;


                //transformations
	            float4x4 TRS = mul(Translate(translation), mul(Rotate(_Angle), Scale(float3(1,grassHeight,1))));
                unity_ObjectToWorld = mul(_ParentToWorld, TRS);
                float4 wPos = mul(unity_ObjectToWorld, v.vertex);
                

                if (cullVertex(wPos.xyz, -_CullingBias * max(1.0, _DispStrength)))
                    o.pos = 0.0f;
                else
                    o.pos = mul(UNITY_MATRIX_VP, wPos);

                o.uv = v.uv;
                o.saturationLevel = 1.0 - ((grassHeight - 1.0f) / 1.5f);
                o.saturationLevel = max(o.saturationLevel, 0.5f);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                //texture color
                float4 col = tex2D(_GrassTex, i.uv);
                clip(col.a - 0.6);

                float luminance = LinearRgbToLuminance(col);

                float saturation = lerp(1.0f, i.saturationLevel, pow(i.uv.y, 5.0));
                col.r /= saturation;


                //lighting                
                float3 L = _WorldSpaceLightPos0.xyz;
                //float attenuation = LIGHT_ATTENUATION(i);
                float3 lambert = DotClamped(L, float3(0,1,0));
                float3 light = lambert * pow(i.uv.y, _OcclusionExponent) * _LightColor0.xyz; // * attenuation;

                return float4(col.xyz * light , 1);
            }
            ENDCG
        }

        //Pass{
        //    Tags{"Lightmode"="ShadowCaster"}
        //    
        //    CGPROGRAM
        //    #pragma target 5.0
        //    #pragma vertex vert
        //    #pragma fragment frag
        //
        //    #pragma multi_compile_shadowcaster
        //    
        //    #include "UnityCG.cginc"
        //
        //    struct Interpolators {
        //        V2F_SHADOW_CASTER;
        //        //float3 vec : TEXCOORD0;
        //    };
        //
        //    Interpolators vert (appdata_base v) {
        //        Interpolators o;
        //        TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
        //        //float4 opos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
        //        //o.vec = UnityApplyLinearShadowBias(opos);
        //        return o;
        //    }
        //
        //
        //    float4 frag (Interpolators i) : SV_Target{
        //        SHADOW_CASTER_FRAGMENT(i)
        //        //return UnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
        //    }
        //    ENDCG
        //}
    }
}
