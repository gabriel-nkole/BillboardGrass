#include "UnityCG.cginc"
#include "../Resources/Random.cginc"


float _WindStrength;
float _LODCutoff;
float _CullingBias;

StructuredBuffer<float> _GrassHeights;
StructuredBuffer<float4x4> _Matrices;
        
sampler2D _GrassTex;


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
    float3 vec : TEXCOORD0;
    float2 uv : TEXCOORD1;
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
    o.pos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, v.vertex));

    
    // Shadows
    float4 opos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
    o.vec = UnityApplyLinearShadowBias(opos);


    o.uv = v.uv;
    return o;
}
        
       
       
float4 Fragment(Interpolators i) : SV_Target {
    float4 col = tex2D(_GrassTex, i.uv);
    clip(col.a - 0.6);

    return UnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
}