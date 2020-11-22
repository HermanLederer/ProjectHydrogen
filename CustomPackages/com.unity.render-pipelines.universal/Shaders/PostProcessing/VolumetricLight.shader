Shader "Hidden/Universal Render Pipeline/VolumetricLights"
{
    HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
        //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        TEXTURE2D_X(_BlitTex);
        float3 _FrustumCorners[4];
        float4x4 _MatrixHClipToWorld;
        //float3 _CameraPosition;

        struct Interpolators
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 ray : TEXCOORD1;
        };

        struct VertexData {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        Interpolators VertMy(VertexData input)
        {
            Interpolators output;

            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = input.uv;
            output.ray = _FrustumCorners[input.uv.x + 2 * input.uv.y];

            return output;
        }

        inline half3 TransformUVToWorldPos(half2 uv, float depth)
        {
            #ifndef SHADER_API_GLCORE
                half4 positionCS = half4(uv * 2 - 1, depth, 1) * LinearEyeDepth(depth, _ZBufferParams);
            #else
                half4 positionCS = half4(uv * 2 - 1, depth * 2 - 1, 1) * LinearEyeDepth(depth, _ZBufferParams);
            #endif
            return mul(_MatrixHClipToWorld, positionCS).xyz;
        }

        inline half3 GetCameraRay(half2 uv)
        {
            #ifndef SHADER_API_GLCORE
                half4 positionCS = half4(uv * 2 - 1, 1, 1);
            #else
                half4 positionCS = half4(uv * 2 - 1, 1 * 2 - 1, 1);
            #endif
            return mul(_MatrixHClipToWorld, positionCS).xyz;
        }

        half4 Frag(Interpolators input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);

            half3 color = SAMPLE_TEXTURE2D_X(_BlitTex, sampler_LinearClamp, uv).xyz;
            //float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_LinearClamp, uv).x;

            float3 volumetricLightPositionWS = float3(0, 5, 0);
            float3 volumetricLightColor = float3(1, 1, 1);
            float  volumetricLightRadius = 1;

            float3 cameraDirection = normalize(GetCameraPositionWS() - TransformUVToWorldPos(uv, 1));
            float3 volumetricLightViewDirection = normalize(GetCameraPositionWS() - volumetricLightPositionWS);
            float volumetricLightDistance = length(GetCameraPositionWS() - volumetricLightPositionWS);
            
            float cameraLightDot = max(0, dot(volumetricLightViewDirection, cameraDirection));
            //cameraLightDot /= volumetricLightDistance;
            
            color += lerp((0).xxx, volumetricLightColor, pow(cameraLightDot, 256));
            //color = ray;

            return half4(color, 1.0);
        }

    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "Atmosphere"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
            ENDHLSL
        }
    }
}
