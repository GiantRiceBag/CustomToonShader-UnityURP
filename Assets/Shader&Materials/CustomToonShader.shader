Shader "Unlit/CustomToonShader"
{
    Properties
    {
        [Header(BaseMap)]
        [Space(10)]
        _MainTex ("BaseMap", 2D) = "white" {}
        [HDR]_Tint("Tint",Color) = (1,1,1,1)
        [Toggle] _Normal("Enable Normal Map",FLOAT) = 0
        [NoScaleOffset]_NormalMap ("Normal Map", 2D) = "white" {}
        [Toggle] _Ambient("Enable Ambient Light",FLOAT) = 1
        [Toggle] _AlphaClip("Alpha Clip",FLOAT) = 0
        _ClipThreshold("Alpha Clip Threshold",Range(0,1)) = 0.5

        [Space(30)]
        [Header(Shadow)]
        [Space(10)]
        [Toggle] _ShadowRamp("Enable Shadow Ramp",FLOAT) = 0
        [NoScaleOffset]_ShadowRampMap ("Shadow Ramp Map", 2D) = "white" {}
        [Space(10)]
        _ShadowStep("Shadow Step",Range(0,1)) = 0.5
        _ShadingFeather("Shading Feather",Range(0,1)) = 0.0001
        _ShadingMap("Shading Map",COLOR) = (0.7,0.7,0.7,1)

        [Space(30)]
        [Header(Highlight)]
        [Space(10)]
        [Toggle] _Highlight("Enable Highlight",FLOAT) = 0
        [HDR]_HighlightTint("HighLight Tint",COLOR) = (1,1,1,1)
        _HighlightStep("HighLight Step",Range(0,1)) = 0.5
        _HighlightFeather("Highlight Feather",Range(0,0.5)) = 0.0001
        [NoScaleOffset]_HighlightMask("Highlight Mask",2D) = "white"{}
        _HighlightLevel("HighLight Level",Range(0,1)) = 0.5
        _HighlightPower("Highlight Power",Range(0,300)) = 30

        [Space(30)]
        [Header(Rim Light)]
        [Space(10)]
        [Toggle] _RimLight("Enable RimLight",FLOAT) = 0
        [HDR]_RimLightTint("RimLight Tint",COLOR) = (1,1,1,1)
        _RimLightPower("RimLight Power",Range(0.001,100)) = 30

        [Space(30)]
        [Header(Outline)]
        [Space(10)]
        [Toggle] _Outline("Enable Outline",FLOAT) = 0
        [HDR]_OutlineTint("Outline Tint",COLOR) = (1,1,1,1)
        _OutlineThickness("Outline Thickness",Range(0.001,0.1)) = 0.005
    }
    SubShader
    {
        Tags{
            "RenderType" = "Opaque" 
            "Queue" = "AlphaTest+51"
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        Pass
        {
            Tags { 
                "LightMode" = "UniversalForward"
            }
            LOD 100

            Name "Main"
            Cull Back
            Zwrite On
            ZTest LEqual

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _MAIN_LIGHT_SHADOWS
            #pragma shader_feature _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma shader_feature _SHADOWS_SOFT

            #pragma shader_feature _HIGHLIGHT_ON
            #pragma shader_feature _RIMLIGHT_ON
            #pragma shader_feature _AMBIENT_ON
            #pragma shader_feature _ALPHACLIP_ON
            #pragma shader_feature _NORMAL_ON
            #pragma shader_feature _SHADOWRAMP_ON

            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            TEXTURE2D(_MainTex);
            TEXTURE2D(_NormalMap);
            TEXTURE2D(_HighlightMask);
            TEXTURE2D(_ShadowRampMap);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_NormalMap);
            SAMPLER(sampler_HighlightMask);
            SAMPLER(sampler_ShadowRampMap);

            float _ShadowStep;
            float _ShadingFeather;
            float _HighlightPower;
            float _HighlightStep;
            float _HighlightFeather;
            float _HighlightLevel;
            float _RimLightPower;
            float _ClipThreshold;

            float4 _Tint;
            float4 _ShadingMap;
            float4 _HighlightTint;
            float4 _RimLightTint;

            struct appdata{
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct vertexOutput{
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 normalOS : TEXCOORD3;
                float2 uv : TEXCOORD0;
            };

             float4 CaculateHighlight(float4 shadowMask,Light light,vertexOutput data){
                #if _HIGHLIGHT_ON
                    float3 viewDir = normalize(GetWorldSpaceViewDir(data.positionWS));
                    float3 reflectDir = normalize(reflect(-light.direction,data.normalWS));
                    float4 highlightMask = SAMPLE_TEXTURE2D(_HighlightMask,sampler_HighlightMask,data.uv);
                    return float4 (light.color,1) * shadowMask * _HighlightTint * smoothstep(_HighlightStep,_HighlightStep+_HighlightFeather,pow(saturate(dot(viewDir,reflectDir)),_HighlightPower)) * highlightMask * _HighlightLevel;
                #endif
                    return float4(0,0,0,0);
            }

            float4 CaculateRimLight(vertexOutput data){
                #if _RIMLIGHT_ON
                    float3 normal = TransformObjectToWorldNormal(data.normalOS);
                    float3 viewDir = normalize(GetWorldSpaceViewDir(data.positionWS));
                    float4 rimCol = pow(1-saturate(dot(normal,viewDir)),_RimLightPower) * _RimLightTint;
                    return rimCol;
                #endif
                    return float4(0,0,0,0);
            }

            float4 GetAmbientColor(){
                #if _AMBIENT_ON
                     return float4(_GlossyEnvironmentColor.xyz,1);
                #endif
                 return float4(1,1,1,1);
            }

            vertexOutput vert(appdata i){
                vertexOutput o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.normalOS = i.normalOS;
                o.uv = i.uv;
                return o;
            }

            float4 frag(vertexOutput i) : SV_TARGET{
                #if _NORMAL_ON
                    i.normalWS = TransformObjectToWorldNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv));
                #endif

                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light light = GetMainLight(shadowCoord,i.positionWS,1);
                float3 lightDirection = light.direction;
                float4 lightColor = float4(light.color,1);

                float shadowMask;
                #if _SHADOWRAMP_ON
                    float2 rampUV = (light.shadowAttenuation+1)/2 *  (dot(lightDirection,i.normalWS)+1)/2 * float2(1,0);
                    shadowMask = SAMPLE_TEXTURE2D(_ShadowRampMap,sampler_ShadowRampMap,rampUV).r;
                #else
                    shadowMask = smoothstep(_ShadowStep,_ShadowStep + _ShadingFeather,((dot(lightDirection,i.normalWS)+1)/2));
                    shadowMask *= smoothstep(_ShadowStep,_ShadowStep + _ShadingFeather,light.shadowAttenuation);
                #endif

                #ifdef _ADDITIONAL_LIGHTS
                        // TODO
                #endif

                               
                float4 srcCol = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _Tint * lightColor * GetAmbientColor();
                float4 highlightCol = CaculateHighlight(shadowMask,light,i);
                float4 RimLightCol = CaculateRimLight(i);

                #if _ALPHACLIP_ON
                    clip(srcCol.a - _ClipThreshold);
                #endif

                float4 extraCol = float4(0,0,0,1);
                #if _RIMLIGHT_ON
                     extraCol += RimLightCol; 
                #endif

                _ShadingMap = lerp(_ShadingMap,float4(1,1,1,1),shadowMask);
                return srcCol * _ShadingMap + highlightCol + extraCol;
            }
            ENDHLSL
        }

        Pass{
            Name "Outline"
            Tags{
                "RenderPipeline" = "UniversalPipeline"
            }

            Cull Front
            Offset 1,1
            ZWrite Off

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _OUTLINE_ON

            float _OutlineThickness;
            float4 _OutlineTint;

            struct appdata{
                float4 positionOS : POSITION;
                float4 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };
            struct vertexOutput{
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            vertexOutput vert(appdata i){
                vertexOutput o;
                #if _OUTLINE_ON
                    i.positionOS += i.normalOS * _OutlineThickness;
                #endif
                o.positionCS = TransformObjectToHClip(i.positionOS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);

                return o;
            }

            float4 frag(vertexOutput i) : SV_TARGET{
                #if !_OUTLINE_ON
                    clip(-1);
                #endif
                    return _OutlineTint;
            }
            ENDHLSL
        }
    }
}
