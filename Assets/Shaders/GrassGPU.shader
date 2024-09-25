// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Custom/GrassGPU" {
    Properties {
        [NoScaleOffset] _GrassTex ("Grass Texture", 2D) = "white" {}
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

            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "../Resources/TRS.cginc"
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
                float3 wPos : TEXCOORD4;
            };


            sampler2D _GrassTex;

            float _WindStrength;
            float _LODCutoff;
            float _CullingBias;
            float _OcclusionExponent;

            float _Resolution;
            float _Density;
            float _DispStrength;
            StructuredBuffer<float4x4> _Matrices;
            StructuredBuffer<float> _GrassHeights;




            Interpolators vert (MeshData v, uint instanceID : SV_InstanceID) {
                Interpolators o;


                // wind animation
                float grassHeight = _GrassHeights[instanceID];
                float localWindVariance = min(max(0.4f, randValue(instanceID)), 0.75f);
                
                float cosTime;
                if (localWindVariance > 0.6f)
                    cosTime = cos(_Time.y * (_WindStrength - (grassHeight - 1.0f)));
                else
                    cosTime = cos(_Time.y * ((_WindStrength - (grassHeight - 1.0f)) + localWindVariance * 0.1f));
                    
                
                float trigValue = ((cosTime * cosTime) * 0.65f) - localWindVariance * 0.5f;
                
                v.vertex.x += v.uv.y * trigValue * grassHeight * localWindVariance * 0.6f;
                v.vertex.z += v.uv.y * trigValue * grassHeight * 0.4f;
                

                // transformations
                unity_ObjectToWorld = _Matrices[instanceID];
                float4 wPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = mul(UNITY_MATRIX_VP, wPos);

                o.uv = v.uv;
                o.wPos = wPos.xyz;
                o.saturationLevel = 1.0 - ((grassHeight - 1.0f) / 1.5f);
                o.saturationLevel = max(o.saturationLevel, 0.5f);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                // texture color
                float4 col = tex2D(_GrassTex, i.uv);
                clip(col.a - 0.6);

                float saturation = lerp(1.0f, i.saturationLevel, pow(i.uv.y, 5.0));
                col.r /= saturation;


                float luminance = LinearRgbToLuminance(col);

                // lighting                
                float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
                float attenuation = LIGHT_ATTENUATION(i);

                float lambertDiffuse = DotClamped(float3(0,1,0), L);
                float3 light = lambertDiffuse * pow(i.uv.y, _OcclusionExponent) * _LightColor0.xyz * attenuation;

                return float4(col.xyz * light, 1);
            }
            ENDCG
        }

        Pass{
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
		    #pragma target 4.5
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "../Resources/TRS.cginc"
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
                float3 wPos : TEXCOORD4;
            };


            sampler2D _GrassTex;

            float _WindStrength;
            float _LODCutoff;
            float _CullingBias;
            float _OcclusionExponent;

            float _Resolution;
            float _Density;
            float _DispStrength;
            StructuredBuffer<float4x4> _Matrices;
            StructuredBuffer<float> _GrassHeights;




            Interpolators vert (MeshData v, uint instanceID : SV_InstanceID) {
                Interpolators o;


                // wind animation
                float grassHeight = _GrassHeights[instanceID];
                float localWindVariance = min(max(0.4f, randValue(instanceID)), 0.75f);
                
                float cosTime;
                if (localWindVariance > 0.6f)
                    cosTime = cos(_Time.y * (_WindStrength - (grassHeight - 1.0f)));
                else
                    cosTime = cos(_Time.y * ((_WindStrength - (grassHeight - 1.0f)) + localWindVariance * 0.1f));
                    
                
                float trigValue = ((cosTime * cosTime) * 0.65f) - localWindVariance * 0.5f;
                
                v.vertex.x += v.uv.y * trigValue * grassHeight * localWindVariance * 0.6f;
                v.vertex.z += v.uv.y * trigValue * grassHeight * 0.4f;
                

                // transformations
                unity_ObjectToWorld = _Matrices[instanceID];
                float4 wPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = mul(UNITY_MATRIX_VP, wPos);

                o.uv = v.uv;
                o.wPos = wPos.xyz;
                o.saturationLevel = 1.0 - ((grassHeight - 1.0f) / 1.5f);
                o.saturationLevel = max(o.saturationLevel, 0.5f);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            float4 frag (Interpolators i) : SV_Target {
                // texture color
                float4 col = tex2D(_GrassTex, i.uv);
                clip(col.a - 0.6);

                float saturation = lerp(1.0f, i.saturationLevel, pow(i.uv.y, 5.0));
                col.r /= saturation;


                float luminance = LinearRgbToLuminance(col);

                // lighting                
                float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
                float attenuation = LIGHT_ATTENUATION(i);

                float lambertDiffuse = DotClamped(float3(0,1,0), L);
                float3 light = lambertDiffuse * pow(i.uv.y, _OcclusionExponent) * _LightColor0.xyz * attenuation;

                return float4(col.xyz * light , 1);
            }
            ENDCG
        }

        /*
        Pass{
            Tags{"Lightmode"="ShadowCaster"}
            
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
        
            #pragma multi_compile_shadowcaster
            
            #include "UnityCG.cginc"
        
            struct Interpolators {
                V2F_SHADOW_CASTER;
                //float3 vec : TEXCOORD0;
            };
        
            Interpolators vert (appdata_base v) {
                Interpolators o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                //float4 opos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
                //o.vec = UnityApplyLinearShadowBias(opos);
                return o;
            }
        
        
            float4 frag (Interpolators i) : SV_Target{
                SHADOW_CASTER_FRAGMENT(i)
                //return UnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
            }
            ENDCG
        }
        */
    }
}