Shader "VFX/RimeFireUnlit"
{
    Properties
    {
        [HDR] _InnerColor1("Inner Color", Color) = (1, 1, 1, 1)
        [HDR] _InnerColor2("Inner Color", Color) = (1, 1, 1, 1)
        [HDR] _OutterColor1("Outter Color", Color) = (1, 1, 1, 1)
        [HDR] _OutterColor2("Outter Color", Color) = (1, 1, 1, 1)
		_DisScale1("Distortion Texture Scaler", Float) = 1
		_DisScale2("Distortion 2 Texture Scaler", Float) = 1
		_Flicker("Flicker Speed", Float) = 1
		
        _Speed1("Distortion 1 speed", Float) = 1
		_Speed2("Distortion 2 speed", Float) = 1

        _MainTex ("Texture", 2D) = "white" {}
        _DisTex("Distortion Texture", 2D) = "white" {}
		_TopMask("Top Mask", Float) = 1
		_BottomMask("Bottom Mask", Float) = 1



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
			float _BottomMask;
			float _Speed1;
			float _Speed2;
			float _Flicker;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

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
                _Speed1 *= _Time;
                _Speed2 *= _Time;

                float2 disUV1 = float2(i.uv.x, i.uv.y + _Speed1);
                float2 disUV2 = float2(i.uv.x, i.uv.y + _Speed2);

                fixed4 dist = tex2D(_DisTex, disUV1 * _DisScale1);
                fixed4 dist2 = tex2D(_DisTex, disUV2 * _DisScale2);

                float a = dist.r + dist2.g;
                a *= 0.3f;
                a *= 2.3f;

                fixed4 shape = tex2D(_MainTex, i.uv);
                float alphaMask = 1 - i.uv.y + _TopMask;
                float bottomMask = i.uv.y * _BottomMask;
                alphaMask *= shape.a;

                a *= alphaMask;
                a *= bottomMask;
                float2 finalUV = float2(i.uv.r, i.uv.g + a);
                
                fixed4 shape2 = tex2D(_MainTex, finalUV);
            
                float cut = 1 - shape2.b;

                float4 innerColor = lerp(_InnerColor1, _InnerColor2, sin(_Flicker * _Time));
                float4 innerAlpha = lerp(_InnerColor1.a, _InnerColor2.a, sin(_Flicker * _Time));

                innerColor *= innerAlpha;
                
                float4 outterColor = lerp(_OutterColor1, _OutterColor2, sin(_Flicker * _Time));
                float4 outterAlpha = lerp(_OutterColor1.a, _OutterColor2.a, sin(_Flicker * _Time));

                outterColor *= outterAlpha;

                float4 g = shape2.g * innerColor;
                float4 r = shape2.r * outterColor;
                //________________________________
                
                float4 n = g + r;
                

                UNITY_APPLY_FOG(i.fogCoord, n);

                return float4(n.rgb, cut);
                // return float4(finalUV, 0, cut);
            }
            ENDCG
        }
    }
}
