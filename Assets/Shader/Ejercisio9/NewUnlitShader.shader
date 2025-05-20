Shader "URP/MultiTextureMasked"
{
    Properties
    {
        _MainTex ("Texture 1", 2D) = "white" {}    // Textura base
        _SecondTex ("Texture 2", 2D) = "black" {}  // Textura secundaria
        _MaskTex ("Mask Texture", 2D) = "gray" {}  // Máscara de mezcla
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
                sampler2D _SecondTex;
                sampler2D _MaskTex;
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
                // Cargar las texturas
                half4 tex1 = tex2D(_MainTex, IN.uv);
                half4 tex2 = tex2D(_SecondTex, IN.uv);
                half mask = tex2D(_MaskTex, IN.uv).r; // Solo canal rojo (escala de grises)

                // Combinar texturas con máscara
                half4 blendedTex = lerp(tex1, tex2, mask);

                // **Luz ambiental**
                half3 ambientLight = SampleSH(float4(IN.normalWS, 1.0)) * _AmbientIntensity;

                // **Luz difusa (Lambert)**
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color.rgb;
                half lambert = max(dot(IN.normalWS, lightDir), 0.0);
                half3 diffuseLight = lambert * lightColor;

                // **Reflejo especular con Blinn-Phong**
                half3 halfwayDir = normalize(lightDir + IN.viewDirWS);
                half specular = pow(max(dot(IN.normalWS, halfwayDir), 0.0), _Smoothness * 128.0);
                half3 specularLight = specular * _SpecColor.rgb * lightColor;

                // **Combinar iluminación con la textura final**
                half3 finalColor = blendedTex.rgb * (diffuseLight + ambientLight) + specularLight;
                return half4(finalColor, blendedTex.a);
            }
            ENDHLSL
        }
    }
}
