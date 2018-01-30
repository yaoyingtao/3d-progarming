
varying lowp vec4 DestinationColor;
varying lowp vec2 DestTexturCoord;

uniform sampler2D ourTexture;
uniform sampler2D fishTexture;



void main(void) {
    gl_FragColor = DestinationColor;

//    gl_FragColor = mix(texture2D(ourTexture, DestTexturCoord), texture2D(fishTexture, vec2(DestTexturCoord.x + DestTexturCoord.x, DestTexturCoord.y + DestTexturCoord.y)), 0.2);
}
