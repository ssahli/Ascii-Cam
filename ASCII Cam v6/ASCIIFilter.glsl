#version 120

// Fragment shader -- this shader grabs the average color of a 16x16 pixel block
// of the captured camera texture, and clamps it to an algorithmically selected
// ASCII character


uniform sampler2D cameraTexture;
uniform sampler2D asciiTexture;

const vec2 fontSize = vec2(16.0, 16.0);

// Grab the right pixel from the ASCII character
vec4 findASCII(float asciiValue)
{
    vec2 position = mod(gl_FragCoord.xy, fontSize.xy);
    position /= vec2(3936.0, 16.0);
    position.x += asciiValue;
    return vec4(texture2D(asciiTexture, position).rgb, 1.0);
}

void main()
{
    vec2 invViewport = vec2(1.0) / vec2(864.0, 480.0);
    vec2 blockSize = fontSize;
    vec4 sum = vec4(0.0);
    vec2 uvClamped = gl_TexCoord[0].st - mod(gl_TexCoord[0].st, blockSize * invViewport);
    
    // Sum the colors of the block
    for (float x = 0.0; x < fontSize.x; x++)
    {
        for (float y = 0.0; y < fontSize.y; y++)
        {
            vec2 offset = vec2(x, y);
            sum += texture2D(cameraTexture, uvClamped + (offset * invViewport));
        }
    }
    
    // Calculate average color of the block
    vec4 average = sum / vec4(fontSize.x * fontSize.y);
    float brightness = dot(average.xyz, vec3(0.2126, 0.7152, 0.0722));
    vec4 clampedColor = floor(average * 16.0) / 16.0;
    
    // Depending on the brightness of the block, pick an ASCII value that best fits the brightness
    float asciiChar = floor(brightness * 246.0) / 246.0;
    
    // Calculate the final color of the pixel
    gl_FragColor = clampedColor * findASCII(asciiChar);
}