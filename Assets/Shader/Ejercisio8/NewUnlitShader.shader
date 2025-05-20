Shader "URP/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Ramp Texture", 2D) = "gray" {} 
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Range(0,0.1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            Name "Outline"
            Tags { "LightMode"="SRPDefaultUnlit" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _OutlineWidth;
            CBUFFER_END

            Varyings vert_outline (Attributes IN)
            {
                Varyings OUT;
                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                float3 offset = normalWS * _OutlineWidth;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS + offset);
                return OUT;
            }

            half4 frag_outline (Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ToonLit"
            Tags { "LightMode"="UniversalForward" }

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
                sampler2D _RampTex;
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

                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half lambert = max(dot(IN.normalWS, lightDir), 0.0);
                half toonShade = tex2D(_RampTex, float2(lambert, 0.5)).r;

                half3 finalColor = texColor.rgb * toonShade * mainLight.color.rgb;
                return half4(finalColor, texColor.a);
            }
            ENDHLSL
        }
    }
}

