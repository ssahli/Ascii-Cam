#version 120

/*
    Fragment shader -- this shader grabs the average color of a 16x16 pixel block
    of the captured camera texture, and clamps it to an algorithmically selected
    ASCII character
 */

uniform sampler2D cameraTexture;
uniform sampler2D asciiTexture;

const vec2 fontSize = vec2(16.0, 16.0); // Each ASCII character is 16x16 pixels

/*
    Finds the correct pixel from the corresponding ASCII character.
    The ASCII png file is 3936x16 pixels (all ASCII characters lined up).
 */
vec4 findASCII(float asciiValue)
{
    vec2 position = mod(gl_FragCoord.xy, fontSize.xy);
    position /= vec2(3936.0, 16.0);
    position.x += asciiValue;
    return vec4(texture2D(asciiTexture, position).rgb, 1.0);
}





/*
    Main routine
 */
void main()
{
    vec2 invViewport = vec2(1.0) / vec2(864.0, 480.0); // inverse of the viewport
    vec2 blockSize = fontSize;
    vec4 sum = vec4(0.0);
    vec2 uvClamped = gl_TexCoord[0].st - mod(gl_TexCoord[0].st, blockSize * invViewport);
    
    
    /*
        Sum the colors of the 16x16 pixel block from the current frame,
        to be used to calculate the average color of that block.
     */
    for (float x = 0.0; x < fontSize.x; x++)
    {
        for (float y = 0.0; y < fontSize.y; y++)
        {
            vec2 offset = vec2(x, y);
            sum += texture2D(cameraTexture, uvClamped + (offset * invViewport));
        }
    }
    
    
    /*
        Calculate the average color of the block using the sum from above.
        Here, the luminance (brightness) is calculated using:
            Luminance = (0.2126 * Red) + (0.7152 * Green) + (0.0722 * Blue)
        However, only a single value (average) is used in place of the RGB values.
     */
    vec4 average = sum / vec4(fontSize.x * fontSize.y);
    float luminance = dot(average.xyz, vec3(0.2126, 0.7152, 0.0722));
    vec4 color = floor(average * 16.0) / 16.0;
    
    
    /*
        Depending on the calculated luminance, select the ASCII character that best
        fits the pixel block.
     */
    float asciiChar = floor(luminance * 246.0) / 246.0;
    gl_FragColor = color * findASCII(asciiChar);
}