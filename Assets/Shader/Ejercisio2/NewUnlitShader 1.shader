Shader "URP/LambertAmbient"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : NORMAL;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 lightColor = mainLight.color.rgb;

                float3 ambientLight = SampleSH(float4(IN.normalWS, 1.0));

                float lambert = max(dot(IN.normalWS, lightDir), 0.0);
                float3 diffuseLight = lambert * lightColor;

                float3 finalColor = _BaseColor.rgb * (diffuseLight + ambientLight);

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
