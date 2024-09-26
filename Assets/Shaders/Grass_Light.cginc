#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "../Resources/Random.cginc"


float _WindStrength;
float _LODCutoff;
float _CullingBias;

StructuredBuffer<float> _GrassHeights;
StructuredBuffer<float4x4> _Matrices;

sampler2D _GrassTex;
float _OcclusionExponent;


bool VertexIsBelowClipPlane(float3 p, int planeIndex, float bias) {
	float4 plane = unity_CameraWorldClipPlanes[planeIndex];
	return dot(float4(p, 1), plane) < bias;
}

bool cullVertex(float3 p, float bias) {
	return distance(_WorldSpaceCameraPos, p) > _LODCutoff ||
            VertexIsBelowClipPlane(p, 0, bias) ||
		    VertexIsBelowClipPlane(p, 1, bias) ||
		    VertexIsBelowClipPlane(p, 2, bias) ||
		    VertexIsBelowClipPlane(p, 3, bias);
}


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

Interpolators Vertex(MeshData v, uint instanceID : SV_InstanceID) {
    Interpolators o;


    // Wind Animation
    float grassHeight = _GrassHeights[instanceID];
    float localWindVariance = min(max(0.4f, randValue(instanceID)), 0.75f);
                
    float cosTime;
    float windFactor = _WindStrength - (grassHeight - 1.0f);
    if (localWindVariance > 0.6f)
        cosTime = cos(_Time.y * windFactor);
    else
        cosTime = cos(_Time.y * (windFactor + localWindVariance * 0.1f));
                    
                
    float trigValue = ((cosTime * cosTime) * 0.65f) - localWindVariance * 0.5f;
                
    v.vertex.x += v.uv.y * trigValue * grassHeight * localWindVariance * 0.6f;
    v.vertex.z += v.uv.y * trigValue * grassHeight * 0.4f;
                

    // Transformations
    unity_ObjectToWorld = _Matrices[instanceID];
    float4 wPos = mul(unity_ObjectToWorld, v.vertex);
    o.pos = mul(UNITY_MATRIX_VP, wPos);
    //if (cullVertex(wPos.xyz, -_CullingBias))
    //    o.pos = 0.0f;
    //else
    //    o.pos = mul(UNITY_MATRIX_VP, wPos);


    o.uv = v.uv;
    o.wPos = wPos.xyz;
    o.saturationLevel = 1.0 - ((grassHeight - 1.0f) / 1.5f);
    o.saturationLevel = max(o.saturationLevel, 0.5f);

    TRANSFER_VERTEX_TO_FRAGMENT(o)
    return o;
}



float4 Fragment(Interpolators i) : SV_Target {
    // Texture Color
    float4 col = tex2D(_GrassTex, i.uv);
    clip(col.a - 0.6);

    float saturation = lerp(1.0f, i.saturationLevel, pow(i.uv.y, 5.0));
    col.r /= saturation;

    //float luminance = LinearRgbToLuminance(col);


    // Diffuse Lighting                
    float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
    float attenuation = LIGHT_ATTENUATION(i);

    float lambertDiffuse = DotClamped(float3(0,1,0), L);
    col.xyz *= lambertDiffuse * pow(i.uv.y, _OcclusionExponent) * _LightColor0.xyz * attenuation;


    return float4(col.xyz, 1);
}