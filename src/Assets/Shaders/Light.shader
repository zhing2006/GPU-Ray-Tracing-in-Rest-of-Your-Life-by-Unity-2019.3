Shader "Tutorial/Light"
{
  Properties
  {
    _BaseColorMap ("Texture", 2D) = "white" {}
    _Intensity ("Intensity", Float) = 10.0
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 100

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

      sampler2D _BaseColorMap;
      CBUFFER_START(UnityPerMaterial)
      float4 _BaseColorMap_ST;
      CBUFFER_END

      v2f vert (appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _BaseColorMap);
        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {
        // sample the texture
        fixed4 col = tex2D(_BaseColorMap, i.uv);
        // apply fog
        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
    }
  }

  SubShader
  {
    Pass
    {
      Name "RayTracing"
      Tags { "LightMode" = "RayTracing" }

      HLSLPROGRAM

      #pragma raytracing test

      #include "./Common.hlsl"
      #include "./PRNG.hlsl"

      struct IntersectionVertex
      {
        float2 texCoord0;
      };

      TEXTURE2D(_BaseColorMap);
      SAMPLER(sampler_BaseColorMap);
      CBUFFER_START(UnityPerMaterial)
      float4 _BaseColorMap_ST;
      float _Intensity;
      CBUFFER_END

      void FetchIntersectionVertex(uint vertexIndex, out IntersectionVertex outVertex)
      {
        outVertex.texCoord0  = UnityRayTracingFetchVertexAttribute2(vertexIndex, kVertexAttributeTexCoord0);
      }

      [shader("closesthit")]
      void ClosestHitShader(inout RayIntersection rayIntersection : SV_RayPayload, AttributeData attributeData : SV_IntersectionAttributes)
      {
        // Fetch the indices of the currentr triangle
        uint3 triangleIndices = UnityRayTracingFetchTriangleIndices(PrimitiveIndex());

        // Fetch the 3 vertices
        IntersectionVertex v0, v1, v2;
        FetchIntersectionVertex(triangleIndices.x, v0);
        FetchIntersectionVertex(triangleIndices.y, v1);
        FetchIntersectionVertex(triangleIndices.z, v2);

        // Compute the full barycentric coordinates
        float3 barycentricCoordinates = float3(1.0 - attributeData.barycentrics.x - attributeData.barycentrics.y, attributeData.barycentrics.x, attributeData.barycentrics.y);

        // Get uv and sample texture.
        float2 texCoord0 = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord0, v1.texCoord0, v2.texCoord0, barycentricCoordinates);
        float4 texColor = SAMPLE_TEXTURE2D_LOD(_BaseColorMap, sampler_BaseColorMap, texCoord0, 0);
        rayIntersection.color = float4(texColor.rgb * _Intensity, 1.0f);
      }

      ENDHLSL
    }
  }}
