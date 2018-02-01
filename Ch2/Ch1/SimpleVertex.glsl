
attribute vec2 Position;
attribute vec4 SourceColor;
attribute vec2 TexturCoord;


uniform mat4 Projection;
uniform mat4 Modelview;



varying vec4 DestinationColor;
varying vec2 DestTexturCoord;

void main(void) {
    DestinationColor = SourceColor;
    DestTexturCoord = TexturCoord;
    gl_Position =    Projection * Modelview * vec4(Position, 0.0, 1.0);
}
