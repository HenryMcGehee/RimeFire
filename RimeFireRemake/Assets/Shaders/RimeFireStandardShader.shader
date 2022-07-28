Shader "Custom/RimeFireStandardShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DisTex("Distortion Texture", 2D) = "white" {}

        _InnerColor("Inner Color", Color) = (1, 1, 1)
        _OutterColor("Outter Color", Color) = (1, 1, 1)

		_Intensity("Intensity", Float) = 1
		_DistortionScale("Distortion Scale", Float) = 1
		_XSpeed1("Distortion 1 speed x axis", Float) = 1
		_YSpeed1("Distortion 1 speed y axis", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent+2" "RenderType"="Transparent" }
        LOD 200

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:blend

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _DisTex;



        struct Input
        {
            float2 uv_MainTex;
            float2 uv_DisTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float4 _InnerColor;
        float4 _OutterColor;

        float _Intensity;
        float _DistortionScale;
        float _XSpeed1;
        float _YSpeed1;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            _XSpeed1 *= _Time;
            _YSpeed1 *= _Time;

            float2 disUV1 = float2(IN.uv_DisTex.x, IN.uv_DisTex.y + _XSpeed1);
            float2 disUV2 = float2(IN.uv_DisTex.x, IN.uv_DisTex.y + _YSpeed1);

            fixed4 dist = tex2D(_DisTex, disUV1);
            fixed4 dist2 = tex2D(_DisTex, disUV2);

            float a = dist.r + dist2.g;

            fixed4 shape = tex2D(_MainTex, IN.uv_MainTex);
            float alphaMask = 1 - IN.uv_MainTex.y + _Intensity;
            float bottomMask = IN.uv_MainTex.y + _DistortionScale;
            alphaMask *= shape.a;

            a *= alphaMask;
            a *= bottomMask;
            float2 finalUV = float2(IN.uv_MainTex.r, IN.uv_MainTex.g + a);
            
            fixed4 shape2 = tex2D(_MainTex, finalUV);
            float cut = 1 - shape2.b;

            float4 g = shape2.g * _InnerColor;
            float4 r = shape2.r * _OutterColor;

            // o.Albedo = g + r;
            o.Alpha = cut;
            o.Emission = g + r;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
