// Comparison
float GreaterThan(float a, float b)
{
    return clamp(ceil(a-b), 0, 1);
}
float LessThan(float a, float b)
{
    return clamp(ceil(b-a), 0, 1);
}
float EqualTo(float a, float b)
{
    return min(ceil(abs(a-b)), 1);
}


// Logic
float And(float a, float b)
{
    return a*b;
}
float Or(float a, float b)
{
    return saturate(a+b);
}
float Not(float a)
{
    return 1 - a;
}


// Packing
// from https://stackoverflow.com/questions/48288154/pack-depth-information-in-a-rgba-texture-using-mediump-precison
float4 PackXTo32(float x)
{
    x *= (256.0 * 256.0 * 256.0 - 1.0) / (256.0 * 256.0 * 256.0);
    float4 encode = frac(x * float4(1.0, 256.0, 256.0*256.0, 256.0*256.0*256.0));
    return float4(encode.xyz - encode.yzw / 256.0, encode.w) + 1.0/512.0;
}
float UnpackXFrom32(float4 pack)
{
    float x = dot(pack, 1.0 / float4(1.0, 256.0, 256.0*256.0, 256.0*256.0*256.0));
    return x * (256.0*256.0*256.0) / (256.0*256.0*256.0 - 1.0);
}
float3 PackXTo24(float x)
{
    float xVal = x * (256.0*256.0*256.0 - 1.0) / (256.0*256.0*256.0);
    float4 encode = frac( xVal * float4(1.0, 256.0, 256.0*256.0, 256.0*256.0*256.0) );
    return encode.xyz - encode.yzw / 256.0 + 1.0/512.0;
}
float UnpackXFrom24(float3 pack)
{
    float x = dot( pack, 1.0 / float3(1.0, 256.0, 256.0*256.0) );
    return x * (256.0*256.0*256.0) / (256.0*256.0*256.0 - 1.0);
}
float2 PackXTo16(float x )
{
    float xVal = x * (256.0*256.0 - 1.0) / (256.0*256.0);
    float3 encode = frac( xVal * float3(1.0, 256.0, 256.0*256.0) );
    return encode.xy - encode.yz / 256.0 + 1.0/512.0;
}
float UnpackXFrom16(float2 pack )
{
    float x = dot( pack, 1.0 / float2(1.0, 256.0) );
    return x * (256.0*256.0) / (256.0*256.0 - 1.0);
}


// Values
float Remap(float value, float l1, float h1, float l2, float h2)
{
    return l2 + (value - l1) * (h2 - l2) / (h1 - l1);
}


// Colors
float Brightness(float3 color)
{
    return color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
}
