struct Interpolators {
    float4 pos : SV_POSITION;
    float3 vec : TEXCOORD0;
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


    float3 normal = normalize(BARYCENTRIC_INTERPOLATE(normalWS));
    float2 uv = BARYCENTRIC_INTERPOLATE(uv);

    float3 positionOS = BARYCENTRIC_INTERPOLATE(positionOS);
    positionOS.y += _DispStrength * (tex2Dlod(_HeightMap, float4(uv, 0, 0)).x - 0.5);
    v.pos = UnityObjectToClipPos(float4(positionOS, 1.0));
                
    float4 opos = UnityClipSpaceShadowCasterPos(positionOS, normal);
    v.vec = UnityApplyLinearShadowBias(opos);
    return v;
}

float4 frag (Interpolators i) : SV_Target{
    return UnityEncodeCubeShadowDepth ((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
}