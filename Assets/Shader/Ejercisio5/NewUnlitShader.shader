Shader "URP/TextureLambertSpecularAmbient"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        _AmbientIntensity ("Ambient Intensity", Range(0,2)) = 1.0
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
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 viewDirWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float4 _SpecColor;
                float _Smoothness;
                float _AmbientIntensity;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.viewDirWS = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(IN.positionOS));
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 texColor = tex2D(_MainTex, IN.uv);

                // Obtener luz ambiental correctamente
                half3 ambientLight = SampleSH(float4(IN.normalWS, 1.0)) * _AmbientIntensity;

                // Obtener luz difusa (Lambert)
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color.rgb;
                half lambert = max(dot(IN.normalWS, lightDir), 0.0);
                half3 diffuseLight = lambert * lightColor;

                // Reflexión especular con modelo Blinn-Phong
                half3 halfwayDir = normalize(lightDir + IN.viewDirWS);
                half specular = pow(max(dot(IN.normalWS, halfwayDir), 0.0), _Smoothness * 128.0);
                half3 specularLight = specular * _SpecColor.rgb * lightColor;

                // Combinar iluminación
                half3 finalColor = texColor.rgb * (diffuseLight + ambientLight) + specularLight;
                return half4(finalColor, texColor.a);
            }
            ENDHLSL
        }
    }
}
