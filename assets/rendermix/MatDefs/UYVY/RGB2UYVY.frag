// For textureSize2D
#extension GL_EXT_gpu_shader4 : enable

varying vec2 texCoord;

uniform sampler2D m_Texture;

// BT.601 matrix from http://www.equasys.de/colorconversion.html
const vec3 BT601_bias = vec3 (0.0625, 0.5, 0.5);
const mat3 BT601 = mat3( 0.257,  0.504,  0.098,
                        -0.148, -0.291,  0.439,
                         0.439, -0.368, -0.071);

void main() {
    float uvPixel = 1.0 / float(textureSize2D(m_Texture, 0).x);

    vec2 uv1 = texCoord;
    vec2 uv2 = uv1;
    uv2.x += uvPixel;

    vec3 color1 = texture2D(m_Texture, uv1).rgb;
    vec3 color2 = texture2D(m_Texture, uv2).rgb;
    vec3 YCbCr1 = BT601_bias + (BT601 * color1.rgb);
    vec3 YCbCr2 = BT601_bias + (BT601 * color2.rgb);
    vec2 meanCbCr = (YCbCr1.yz + YCbCr2.yz) / 2.0;
    // Pixel layout is: U0 Y0 V0 Y1 - U2 Y2 V2 Y3 - U4 Y4 V4 Y5
    // Return Cb Y0 Cr Y1
    gl_FragColor = vec4(meanCbCr.x, YCbCr1.x, meanCbCr.y, YCbCr2.x);
}
