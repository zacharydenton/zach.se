class FractalBanner
  constructor: ->
    @banner = document.getElementById("banner")
    @header = document.getElementById("header")

    @initRenderer()
    return unless @gl?

    @initShaders()
    @initPalette()
    @initQuad()
    @resize()
  
    @animating = document.body.classList?.contains("front")
    @random = Math.random()
    @timeOffset = 0

    window.addEventListener "resize", (e) => @resize(e)
    window.addEventListener "orientationchange", (e) => @resize(e)
    document.addEventListener "mousemove", (e) => @mousemove(e)
    header.addEventListener "click", (e) => @toggleAnimation(e)

  initRenderer: ->
    @canvas = document.createElement("canvas")
    @banner.appendChild(@canvas)
    @gl = @canvas.getContext("webgl") ? @canvas.getContext("experimental-webgl")

  initShaders: ->
    vertexShader = @gl.createShader(@gl.VERTEX_SHADER)
    @gl.shaderSource(vertexShader, "attribute vec2 position;\nvoid main(){gl_Position=vec4(position,0,1);}")
    @gl.compileShader(vertexShader)

    fragmentShader = @gl.createShader(@gl.FRAGMENT_SHADER)
    @gl.shaderSource(fragmentShader, "precision lowp float;\nuniform float time;uniform vec2 resolution;uniform vec2 mouse;uniform sampler2D palette;vec3 a(vec3 b){vec4 c=vec4(1.0,2.0/3.0,1.0/3.0,3.0);vec3 d=abs(fract(b.xxx+c.xyz)*6.0-c.www);return b.z*mix(c.xxx,clamp(d-c.xxx,0.0,1.0),b.y);}\n#define N 42\nvoid main(void){vec2 e=((gl_FragCoord.xy-resolution*0.5)/min(resolution.x,resolution.y))*20.0;float f=0.0;float g=3.1415926535*2.0;float h=(7.296-0.01*mouse.x*0.2+0.0001*time)*g;float i=cos(h);float j=sin(h);vec2 k=vec2(i,-j);vec2 l=vec2(j,i);\nvec2 m=vec2(0,1.618);float n=-2.916+0.01*mouse.y+0.0001*time;for(int o=0;o<N;o++){float p=dot(e,e);if(p>1.0){p=(1.0)/p;e.x=e.x*p;e.y=e.y*p;}f*=.99;f+=p;e=vec2(dot(e,k),dot(e,l))*n+m;}float q=fract(f);gl_FragColor=texture2D(palette, vec2(fract(0.1 * time + q), 0.5));}")
    @gl.compileShader(fragmentShader)

    @shader = @gl.createProgram()
    @gl.attachShader(@shader, vertexShader)
    @gl.attachShader(@shader, fragmentShader)
    @gl.linkProgram(@shader)
    @gl.useProgram(@shader)

    @positionAttrib = @gl.getAttribLocation(@shader, "position")
    @gl.enableVertexAttribArray(@positionAttrib)
    @timeUniform = @gl.getUniformLocation(@shader, "time")
    @gl.uniform1f(@timeUniform, 0)
    @resolutionUniform = @gl.getUniformLocation(@shader, "resolution")
    @gl.uniform2f(@resolutionUniform, @width, @height)
    @mouseUniform = @gl.getUniformLocation(@shader, "mouse")
    @gl.uniform2f(@mouseUniform, 0.5, 0.5)

  initPalette: ->
    palette = new Uint8Array(512 * 4)
    lerp = (startIndex, stopIndex, startColor, stopColor) ->
      for i in [startIndex...stopIndex]
        ratio = 1 - (i - startIndex) / (stopIndex - startIndex)
        palette[i*4 + 0] = Math.floor(ratio * startColor[0] + (1 - ratio) * stopColor[0])
        palette[i*4 + 1] = Math.floor(ratio * startColor[1] + (1 - ratio) * stopColor[1])
        palette[i*4 + 2] = Math.floor(ratio * startColor[2] + (1 - ratio) * stopColor[2])
        palette[i*4 + 3] = 255

    colors = [[[43,4,74], [11,46,89], [13,103,89], [122,179,23], [160,197,95]],
              [[7,9,61],[12,15,102], [11,16,140], [14,78,173], [16,127,201]],
              [[51,19,39],[153,23,102], [217,15,90], [243,71,57], [255,110,39]],
              [[101,19,102],[167,26,91], [231,32,78], [247,110,42], [240,197,5]],
              [[166,2,108],[209,2,78], [252,57,3], [252,127,3], [255,171,3]],
              [[4,57,78],[0,135,94], [167,204,21], [245,204,23], [245,98,23]]]

    colors = colors[Math.floor(Math.random() * colors.length)]

    lerp(0, 128,     colors[0], colors[1])
    lerp(128, 192,   colors[1],   colors[2])
    lerp(192, 224,  colors[2], colors[3])
    lerp(224, 256,  colors[3], colors[4])

    lerp(256, 320,     colors[4], colors[3])
    lerp(320, 384,   colors[3],   colors[2])
    lerp(384, 448,  colors[2], colors[1])
    lerp(448, 512,  colors[1], colors[0])

    @paletteUniform = @gl.getUniformLocation(@shader, "palette")
    @gl.uniform1i(@paletteUniform, 0)
    @gl.activeTexture(@gl.TEXTURE0)
    @paletteTexture = @gl.createTexture()
    @gl.bindTexture(@gl.TEXTURE_2D, @paletteTexture)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.LINEAR)
    @gl.texImage2D(@gl.TEXTURE_2D, 0, @gl.RGBA, 512, 1, 0, @gl.RGBA, @gl.UNSIGNED_BYTE, palette)

  initQuad: ->
    vertexPosBuffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ARRAY_BUFFER, vertexPosBuffer)
    vertices = [-1, -1, 1, -1, -1, 1, 1, 1]
    @gl.bufferData(@gl.ARRAY_BUFFER, new Float32Array(vertices), @gl.STATIC_DRAW)
    @gl.vertexAttribPointer(@vertexPosAttrib, 2, @gl.FLOAT, false, 0, 0)

  resize: (e) ->
    @devicePixelRatio = window.devicePixelRatio ? 1
    @width = @banner.offsetWidth * @devicePixelRatio
    @height = @banner.offsetHeight * @devicePixelRatio
    @canvas.style.width = @banner.offsetWidth + "px"
    @canvas.style.height = @banner.offsetHeight + "px"
    @canvas.width = @width
    @canvas.height = @height
    @gl.uniform2f(@resolutionUniform, @width, @height)
    @gl.viewport(0, 0, @width, @height)

  mousemove: (e) ->
    canvasX = (e.pageX - @canvas.offsetLeft) * @devicePixelRatio
    canvasY = (e.pageY - @canvas.offsetTop) * @devicePixelRatio
    @gl.uniform2f(@mouseUniform, canvasX / @width, 1 - canvasY / @height)

  toggleAnimation: ->
    @animating = not @animating

    if @animating
      @lastAnimated ?= 0
      @timeOffset += @lastAnimated - @timestamp
      @render()
    else
      @lastAnimated = @timestamp

  render: (timestamp) ->
    timestamp ?= 0
    @timestamp = timestamp / 1000

    if @animating or @timestamp == 0
      @gl.uniform1f(@timeUniform, @timestamp + @timeOffset + (250 * (1.0 - 2.0 * @random)))
      @gl.drawArrays(@gl.TRIANGLE_STRIP, 0, 4)

    requestAnimationFrame (timestamp) => @render(timestamp)

document.addEventListener "DOMContentLoaded", ->
  window.fractalBanner = new FractalBanner()
  fractalBanner.render()
