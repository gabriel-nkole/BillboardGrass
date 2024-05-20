struct Interpolators {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 wPos : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float3 tangent : TEXCOORD3;
    float3 bitangent : TEXCOORD4;
    LIGHTING_COORDS(5,6)
    float4 vertex : TEXCOORD7;
};

[domain("tri")]
Interpolators Domain(
	TessellationFactors factors,
	OutputPatch<TessellationControlPoint, 3> patch,
	float3 barycentricCoordinates : SV_DomainLocation
){
    Interpolators v;
    UNITY_SETUP_INSTANCE_ID(patch[0]);
	UNITY_TRANSFER_INSTANCE_ID(patch[0], v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(v);


    float2 uv = BARYCENTRIC_INTERPOLATE(uv); 
    float3 normal = normalize(BARYCENTRIC_INTERPOLATE(normalWS));
    
    float3 positionOS = BARYCENTRIC_INTERPOLATE(positionOS);
    positionOS += _DispStrength * tex2Dlod(_HeightMap, float4(uv, 0, 0)).x * normal;
    v.pos = UnityObjectToClipPos(float4(positionOS, 1.0));
    v.vertex = float4(positionOS, 1);
    v.uv = uv;
                
    v.wPos = BARYCENTRIC_INTERPOLATE(positionWS);
    v.normal = normal;
    float4 tangent = BARYCENTRIC_INTERPOLATE(tangent);
    v.tangent = UnityObjectToWorldDir(tangent.xyz);
    v.bitangent = cross(v.normal, v.tangent) * tangent.w * unity_WorldTransformParams.w;

    TRANSFER_VERTEX_TO_FRAGMENT(v)
    return v;
}

float4 frag (Interpolators i) : SV_Target{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


    float3 tangentSpaceNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
    tangentSpaceNormal = normalize(lerp(float3(0, 0, 1), tangentSpaceNormal, _NormalStrength));

    float3x3 mtxTangToWorld = {
        i.tangent.x, i.bitangent.x, i.normal.x,
        i.tangent.y, i.bitangent.y, i.normal.y,
        i.tangent.z, i.bitangent.z, i.normal.z,
    };

    float3 N = mul(mtxTangToWorld, tangentSpaceNormal);
                
                
    float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
    float attenuation = LIGHT_ATTENUATION(i);



    float3 col = 0;
                
    //lambert
    col += saturate(dot(N, L));
    float3 surfColor = tex2D(_MainTex, i.uv) * _Albedo;
    col *= surfColor * _LightColor0.xyz * attenuation;


    #ifdef IS_IN_BASE_PASS
        col += _Ambient.xyz;
    #endif

    return float4(col, 1);
}