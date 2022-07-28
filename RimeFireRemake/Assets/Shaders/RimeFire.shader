Shader "Unlit/RimeFire"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DisTex("Distortion Texture", 2D) = "white" {}

        _InnerColor("Inner Color", Color) = (1, 1, 1, 1)
        _OutterColor("Outter Color", Color) = (1, 1, 1, 1)

		_Intensity("Intensity", Float) = 1
		_DistortionScale("Distortion Scale", Float) = 1
		_XSpeed1("Distortion 1 speed x axis", Float) = 1
		_YSpeed1("Distortion 1 speed y axis", Float) = 1
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

            float4 _InnerColor;
            float4 _OutterColor;

			float _Intensity;
			float _DistortionScale;
			float _XSpeed1;
			float _YSpeed1;

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
                _XSpeed1 *= _Time;
                _YSpeed1 *= _Time;

                float2 disUV1 = float2(i.uv.x, i.uv.y + _XSpeed1);
                float2 disUV2 = float2(i.uv.x, i.uv.y + _YSpeed1);

                fixed4 dist = tex2D(_DisTex, disUV1);
                fixed4 dist2 = tex2D(_DisTex, disUV2);

                float a = dist.r + dist2.g;
                //a *= 0.333;
                //a *= 2.3;


                fixed4 shape = tex2D(_MainTex, i.uv);
                float alphaMask = 1 - i.uv.y + _Intensity;
                float bottomMask = i.uv.y + _DistortionScale;
                alphaMask *= shape.a;

                a *= alphaMask;
                a *= bottomMask;
                float2 finalUV = float2(i.uv.r, i.uv.g + a);
                
                float2 finalUVs = i.uv + dist.x + dist2.y;
                finalUVs *= alphaMask;
                fixed4 shape2 = tex2D(_MainTex, finalUV);
                fixed4 shape3 = tex2D(_MainTex, finalUV);
                float cut = 1 - shape2.b;

                float4 g = shape2.g * _InnerColor;
                float4 r = shape2.r * _OutterColor;
                //________________________________
                
                float4 n = g + r;
                

                // UNITY_APPLY_FOG(i.fogCoord, col);

                return float4(n.rgb, cut);
                // return shape2;
            }
            ENDCG
        }
    }
}
