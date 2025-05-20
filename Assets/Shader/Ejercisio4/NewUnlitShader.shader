Shader "URP/TextureAmbient"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                float _AmbientIntensity;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 texColor = tex2D(_MainTex, IN.uv);

                // Obtener luz ambiental y aumentar su intensidad
                half3 ambientLight = SampleSH(float4(IN.normalWS, 1.0)) * _AmbientIntensity;

                // Obtener luz difusa (mínima) para mejorar visibilidad
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color.rgb;
                half lambert = max(dot(IN.normalWS, lightDir), 0.1); // Valor mínimo para que no se vea completamente plano
                half3 diffuseLight = lambert * lightColor;

                // Combinar textura, luz ambiental y luz difusa
                half3 finalColor = texColor.rgb * (ambientLight + diffuseLight);
                return half4(finalColor, texColor.a);
            }
            ENDHLSL
        }
    }
}
