// (C)2008 S2 Games
// mesh_color_unit.vsh
// 
// Default unit vertex shader
//=============================================================================

//=============================================================================
// Headers
//=============================================================================
#include "../common/common.h"

//=============================================================================
// Global variables
//=============================================================================
float4x4	mWorldViewProj;          // World * View * Projection transformation
float4x4	mWorldViewOffset;        // World * View Offset
float3x3	mWorldRotate;            // World rotation for normals

float4		vSunPositionWorld;

float3		vAmbient;
float3		vSunColor;

float4		vColor;

#if (NUM_BONES > 0)
float4x3	vBones[NUM_BONES];
#endif


//=============================================================================
// Vertex shader output structure
//=============================================================================
struct VS_OUTPUT
{
	float4 Position : POSITION;
	float4 Color0 : COLOR0;
	float2 Texcoord0 : TEXCOORDX;
		#include "../common/inc_texcoord.h"
	float3 DiffLight : TEXCOORDX;
		#include "../common/inc_texcoord.h"
};

//=============================================================================
// Vertex shader input structure
//=============================================================================
struct VS_INPUT
{
	float3 Position   : POSITION;
	float3 Normal     : NORMAL;
#if (TEXCOORDS == 1)
	float2 Texcoord0  : TEXCOORD0;
	float4 Tangent    : TEXCOORD1;
#endif
#if (NUM_BONES > 0)
	int4 BoneIndex    : TEXCOORD_BONEINDEX;
	float4 BoneWeight : TEXCOORD_BONEWEIGHT;
#endif
};

//=============================================================================
// Vertex Shader
//=============================================================================
VS_OUTPUT VS( VS_INPUT In )
{
	VS_OUTPUT Out;
	
	float3 vInNormal = (In.Normal / 255.0f) * 2.0f - 1.0f;
	float4 vInTangent = (In.Tangent / 255.0f) * 2.0f - 1.0f;
	
#if (NUM_BONES > 0)
	float4 vPosition = 0.0f;
	float3 vNormal = 0.0f;
	float3 vTangent = 0.0f;

	//
	// GPU Skinning
	// Blend bone matrix transforms for this bone
	//
	
	int4 vBlendIndex = In.BoneIndex;
	float4 vBoneWeight = In.BoneWeight / 255.0f;
	
	float4x3 mBlend = 0.0f;
	for (int i = 0; i < NUM_BONE_WEIGHTS; ++i)
		mBlend += vBones[vBlendIndex[i]] * vBoneWeight[i];

	vPosition = float4(mul(float4(In.Position, 1.0f), mBlend).xyz, 1.0f);
	vNormal = mul(float4(vInNormal, 0.0f), mBlend).xyz;
	vTangent = mul(float4(vInTangent.xyz, 0.0f), mBlend).xyz;
	
	vNormal = normalize(vNormal);
	vTangent = normalize(vTangent);
#else
	float4 vPosition = float4(In.Position, 1.0f);
	float3 vNormal = vInNormal;
	float3 vTangent = vInTangent.xyz;
#endif

	float3 vPositionOffset = mul(vPosition, mWorldViewOffset).xyz;
	
	Out.Position       = mul(vPosition, mWorldViewProj);
	Out.Color0         = vColor;
	Out.Texcoord0      = In.Texcoord0;

	float3 vLight = vSunPositionWorld.xyz;		
	float3 vWVNormal = mul(vNormal, mWorldRotate);

	float fDiffuse = saturate(dot(vWVNormal, vLight));

	Out.DiffLight.xyz = vSunColor * fDiffuse;

	return Out;
}
