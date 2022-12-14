Shader "VFX/RimeFireUnlit"
{
    Properties
    {
        [HDR] _InnerColor1("Inner Color 1", Color) = (1, 1, 1, 1)
        [HDR] _InnerColor2("Inner Color 2", Color) = (1, 1, 1, 1)
        [HDR] _OutterColor1("Outter Color 1", Color) = (1, 1, 1, 1)
        [HDR] _OutterColor2("Outter Color 2", Color) = (1, 1, 1, 1)
		_DisScale1("Distortion Texture Scaler", Float) = 1
		_DisScale2("Distortion 2 Texture Scaler", Float) = 1
		_Flicker("Flicker Speed", Float) = 1
		_FireBreakUp("Fire Break Up", Float) = 1
		
        _Speed1("Distortion 1 speed", Float) = 1
		_Speed2("Distortion 2 speed", Float) = 1

        _MainTex ("Texture", 2D) = "white" {}
        _DisTex("Distortion Texture", 2D) = "white" {}
		_TopMask("Top Mask", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent+2" "RenderType"="Transparent" }
        LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			sampler2D _DisTex;
            float4 _DisTex_ST;

            float _DisScale1;
            float _DisScale2;
            float4 _InnerColor1;
            float4 _OutterColor1;
            float4 _InnerColor2;
            float4 _OutterColor2;

			float _TopMask;
			float _Speed1;
			float _Speed2;
			float _Flicker;
			float _FireBreakUp;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Face camera
				float3 vpos = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
				float4 worldCoord = float4(unity_ObjectToWorld._m03, unity_ObjectToWorld._m13, unity_ObjectToWorld._m23, 1);
				float4 viewPos = mul(UNITY_MATRIX_V, worldCoord) + float4(vpos, 0);
				float4 outPos = mul(UNITY_MATRIX_P, viewPos);

				o.vertex = outPos;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Get different scroll speeds for each uv channel
                _Speed1 *= _Time;
                _Speed2 *= _Time;

                float2 disScroll1 = float2(i.uv.x, i.uv.y + _Speed1);
                float2 disScroll2 = float2(i.uv.x, i.uv.y + _Speed2);

                // Scale distortion texture size
                fixed4 distTex1 = tex2D(_DisTex, disScroll1 * _DisScale1);
                fixed4 distTex2 = tex2D(_DisTex, disScroll2 * _DisScale2);

                // Increase effect
                float a = distTex1.r * _FireBreakUp  + distTex2.g * _FireBreakUp;
                a *= 0.3f;
                a *= 2.3f;

                // Define fire shape
                fixed4 shape = tex2D(_MainTex, i.uv);
                float alphaMask = 1 - i.uv.y + _TopMask;
                float bottomMask = i.uv.y * 0.12f;
                saturate(bottomMask);
                alphaMask *= shape.a;
                a *= bottomMask;
                a *= alphaMask * 0.5f;
                float2 finalUV = float2(i.uv.r, i.uv.g + a);
                fixed4 shape2 = tex2D(_MainTex, finalUV);
                
                // Make a transparency mask
                float cut = 1 - shape2.b;

                // Add color variation over time
                float4 innerColor = lerp(_InnerColor1, _InnerColor2, sin(_Flicker * _Time));   
                float4 outterColor = lerp(_OutterColor1, _OutterColor2, sin(_Flicker * _Time));

                // Colorize each part of the fire
                float4 g = shape2.g * innerColor;
                float4 r = shape2.r * outterColor;
                float4 n = g + r;
                
                UNITY_APPLY_FOG(i.fogCoord, n);

                return float4(n.rgb, cut * shape.a);
            }
            ENDCG
        }
    }
}
