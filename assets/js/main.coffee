class FractalBanner
  constructor: ->
    @banner = document.getElementById("banner")
    @header = document.getElementById("header")

    @initRenderer()
    return unless @gl?

    @initShaders()
    @initQuad()
    @resize()

    @animating = document.body.classList?.contains("front")
    @random = Math.random()
    @timeOffset = -250

    window.addEventListener "resize", (e) => @resize(e)
    window.addEventListener "orientationchange", (e) => @resize(e)
    document.addEventListener "mousemove", (e) => @mousemove(e)
    header.addEventListener "click", (e) => @toggleAnimation(e)

    @render()

  initRenderer: ->
    @canvas = document.createElement("canvas")
    @banner.appendChild(@canvas)
    @gl = @canvas.getContext("webgl") ? @canvas.getContext("experimental-webgl")

  initShaders: ->
    vertexShader = @gl.createShader(@gl.VERTEX_SHADER)
    @gl.shaderSource(vertexShader, "attribute vec2 position;\nvoid main(){gl_Position=vec4(position,0,1);}")
    @gl.compileShader(vertexShader)

    fragmentShader = @gl.createShader(@gl.FRAGMENT_SHADER)
    @gl.shaderSource(fragmentShader, "precision lowp float;uniform float time;uniform vec2 resolution;uniform vec2 mouse;vec3 a(vec3 b){vec4 c=vec4(1.0,2.0/3.0,1.0/3.0,3.0);vec3 d=abs(fract(b.xxx+c.xyz)*6.0-c.www);return b.z*mix(c.xxx,clamp(d-c.xxx,0.0,1.0),b.y);}vec3 e(float f){return vec3(0.02,0.5,0.4)+vec3(0.8,0.3,0.1)*cos(6.28319*(vec3(1.0,2.0,4.0)*f+vec3(0.8,0.4,0.65)));}void main(void){vec2 g=((gl_FragCoord.xy-resolution*0.5)/min(resolution.x,resolution.y))*20.0;float h=0.0;float i=(7.296-0.01*mouse.x*0.2+0.0001*time)*6.28319;float j=cos(i);float k=sin(i);vec2 l=vec2(j,-k);vec2 m=vec2(k,j);vec2 n=vec2(0,1.618);float o=3.516+0.01*mouse.y+0.0001*time;for(int p=0;p<120;p++){float q=dot(g,g);if(q>1.0){q=(1.0)/q;g.x=g.x*q;g.y=g.y*q;}h*=.99;h+=q;g=vec2(dot(g,l),dot(g,m))*o+n;}gl_FragColor=vec4(e(fract(0.01*time+h)),1.0);}")
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
      @gl.uniform1f(@timeUniform, @timestamp + @timeOffset + (50 * (1.0 - 2.0 * @random)))
      @gl.drawArrays(@gl.TRIANGLE_STRIP, 0, 4)

    requestAnimationFrame (timestamp) => @render(timestamp)

new FractalBanner()
