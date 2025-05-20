Shader "URP/LambertSpecularAmbient"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
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
                float3 viewDirWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _SpecColor;
                float _Smoothness;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.viewDirWS = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(IN.positionOS));
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // Obtener la luz principal en URP
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 lightColor = mainLight.color.rgb;

                // Obtener luz ambiental usando SH (spherical harmonics)
                float3 ambientLight = SampleSH(float4(IN.normalWS, 1.0));

                // Cálculo de iluminación difusa con Lambert
                float lambert = max(dot(IN.normalWS, lightDir), 0.0);
                float3 diffuseLight = lambert * lightColor;

                // Cálculo de componente especular con modelo Blinn-Phong
                float3 halfwayDir = normalize(lightDir + IN.viewDirWS);
                float specular = pow(max(dot(IN.normalWS, halfwayDir), 0.0), _Smoothness * 128.0);
                float3 specularLight = specular * _SpecColor.rgb * lightColor;

                // Combinar luz difusa, luz ambiental y reflejo especular
                float3 finalColor = _BaseColor.rgb * (diffuseLight + ambientLight) + specularLight;

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
