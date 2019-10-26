Shader "Tutorial/Lambertian"
{
  Properties
  {
    _Color ("Main Color", Color) = (1,1,1,1)
    _BaseColorMap("BaseColorMap", 2D) = "white" {}
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
        float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float3 normal : TEXCOORD0;
        float2 uv : TEXCOORD1;
        UNITY_FOG_COORDS(2)
        float4 vertex : SV_POSITION;
      };

      sampler2D _BaseColorMap;
      CBUFFER_START(UnityPerMaterial)
      float4 _BaseColorMap_ST;
      half4 _Color;
      CBUFFER_END

      v2f vert (appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.uv = TRANSFORM_TEX(v.uv, _BaseColorMap);
        UNITY_TRANSFER_FOG(o, o.vertex);
        return o;
      }

      half4 frag (v2f i) : SV_Target
      {
        half d = max(dot(i.normal, float3(0.0f, 1.0f, 0.0f)), 0.5f);
        half4 col = half4((_Color * d).rgb, 1.0f);
        col *= tex2D(_BaseColorMap, i.uv);
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
      #include "./ONB.hlsl"

      struct IntersectionVertex
      {
        // Object space normal of the vertex
        float3 normalOS;
        float2 texCoord0;
      };

      TEXTURE2D(_BaseColorMap);
      SAMPLER(sampler_BaseColorMap);
      CBUFFER_START(UnityPerMaterial)
      float4 _BaseColorMap_ST;
      float4 _Color;
      CBUFFER_END

      void FetchIntersectionVertex(uint vertexIndex, out IntersectionVertex outVertex)
      {
        outVertex.normalOS = UnityRayTracingFetchVertexAttribute3(vertexIndex, kVertexAttributeNormal);
        outVertex.texCoord0  = UnityRayTracingFetchVertexAttribute2(vertexIndex, kVertexAttributeTexCoord0);
      }

      float ScatteringPDF(float3 inOrigin, float3 inDirection, float inT, float3 hitNormal, float3 scatteredDir)
      {
        float cosine = dot(hitNormal, scatteredDir);
        return max(0.0f, cosine / M_PI);
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

        // Get normal in world space.
        float3 normalOS = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.normalOS, v1.normalOS, v2.normalOS, barycentricCoordinates);
        float2 texCoord0 = INTERPOLATE_RAYTRACING_ATTRIBUTE(v0.texCoord0, v1.texCoord0, v2.texCoord0, barycentricCoordinates);
        float3x3 objectToWorld = (float3x3)ObjectToWorld3x4();
        float3 normalWS = normalize(mul(objectToWorld, normalOS));
        float4 texColor = _Color * SAMPLE_TEXTURE2D_LOD(_BaseColorMap, sampler_BaseColorMap, texCoord0, 0);

        float4 color = float4(0, 0, 0, 1);
        if (rayIntersection.remainingDepth > 0)
        {
          // Get position in world space.
          float3 origin = WorldRayOrigin();
          float3 direction = WorldRayDirection();
          float t = RayTCurrent();
          float3 positionWS = origin + direction * t;

          // Make reflection ray.
          ONB uvw;
          ONBBuildFromW(uvw, normalWS);

          RayDesc rayDescriptor;
          rayDescriptor.Origin = positionWS + 0.001f * normalWS;
          rayDescriptor.Direction = ONBLocal(uvw, GetRandomCosineDirection(rayIntersection.PRNGStates));
          rayDescriptor.TMin = 1e-5f;
          rayDescriptor.TMax = _CameraFarDistance;

          // Tracing reflection.
          RayIntersection reflectionRayIntersection;
          reflectionRayIntersection.remainingDepth = rayIntersection.remainingDepth - 1;
          reflectionRayIntersection.PRNGStates = rayIntersection.PRNGStates;
          reflectionRayIntersection.color = float4(0.0f, 0.0f, 0.0f, 0.0f);

          float pdf = dot(normalWS, rayDescriptor.Direction) / M_PI;

          TraceRay(_AccelerationStructure, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, 0xFF, 0, 1, 0, rayDescriptor, reflectionRayIntersection);

          rayIntersection.PRNGStates = reflectionRayIntersection.PRNGStates;
          color = ScatteringPDF(origin, direction, t, normalWS, rayDescriptor.Direction) * reflectionRayIntersection.color / pdf;
          color = max(float4(0, 0, 0, 0), color);
        }

        rayIntersection.color = texColor * 0.5f * color;
      }

      ENDHLSL
    }
  }
}
