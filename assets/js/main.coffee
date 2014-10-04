class FractalBanner
  constructor: ->
    @banner = document.getElementById("banner")
    @header = document.getElementById("header")
    @initRenderer()
    @initShaders()
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
    @gl.shaderSource(fragmentShader, "precision lowp float;\nuniform float time;uniform vec2 resolution;uniform vec2 mouse;vec3 a(vec3 b){vec4 c=vec4(1.0,2.0/3.0,1.0/3.0,3.0);vec3 d=abs(fract(b.xxx+c.xyz)*6.0-c.www);return b.z*mix(c.xxx,clamp(d-c.xxx,0.0,1.0),b.y);}\n#define N 80\nvoid main(void){vec2 e=((gl_FragCoord.xy-resolution*0.5)/min(resolution.x,resolution.y))*20.0;float f=0.0;float g=3.1415926535*2.0;float h=(-.57166-0.001*mouse.x*0.2+0.0001*time)*g;float i=cos(h);float j=sin(h);vec2 k=vec2(i,-j);vec2 l=vec2(j,i);\nvec2 m=vec2(0,1.0+0.618);float n=1.7171+0.001*mouse.y+0.0001*time;for(int o=0;o<N;o++){float p=dot(e,e);if(p>1.0){p=(1.0)/p;e.x=e.x*p;e.y=e.y*p;}f*=.99;f+=p;e=vec2(dot(e,k),dot(e,l))*n+m;}float q=fract(f);q=2.0*min(q,1.0-q);float r=mod(time*0.025,1.0);float tf=q*sin(0.1*time);gl_FragColor=vec4(a(vec3(r-0.25*q-0.1*abs(tf),1.0 - 0.3*abs(tf),q+0.1*abs(tf))),1.0);}")
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
      @gl.uniform1f(@timeUniform, @timestamp + @timeOffset + @random * 400)
      @gl.drawArrays(@gl.TRIANGLE_STRIP, 0, 4)

    requestAnimationFrame (timestamp) => @render(timestamp)

document.addEventListener "DOMContentLoaded", ->
  window.fractalBanner = new FractalBanner()
  fractalBanner.render()
