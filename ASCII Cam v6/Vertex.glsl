#version 120

// Vertex shader - since the program only uses a rectangle
// for the viewport, no vertices need to be transformed


void main()
{
    // Set vertex position on screen
    gl_Position = ftransform();
    
    // Set texture position
    gl_TexCoord[0] = gl_MultiTexCoord0;
}