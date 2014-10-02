class Banner
  constructor: ->
    @$banner = $("#banner")
    @width = @$banner.width()
    @height = @$banner.height()
    @scene = new THREE.Scene()
    @camera = new THREE.OrthographicCamera(-@width / 2, @width / 2, @height / 2, -@height / 2, -1000, 1000)
    @camera.position.z = 100
    @camera.lookAt @scene.position
  
    @material = new THREE.ShaderMaterial
      uniforms:
        time:
          type: "f"
          value: 0.0
        resolution:
          type: "v2"
          value: new THREE.Vector2(@width, @height)
        mouse:
          type: "v2"
          value: new THREE.Vector2(0.5, 0.5)
      vertexShader: "void main(){gl_Position=vec4(position,1.0);}"
      fragmentShader: "#ifdef GL_ES\nprecision mediump float;\n#endif\nuniform float time;uniform vec2 resolution;uniform vec2 mouse;vec3 a(vec3 b){vec4 c=vec4(1.0,2.0/3.0,1.0/3.0,3.0);vec3 d=abs(fract(b.xxx+c.xyz)*6.0-c.www);return b.z*mix(c.xxx,clamp(d-c.xxx,0.0,1.0),b.y);}\n#define N 80\nvoid main(void){vec2 e=(gl_FragCoord.xy-resolution/2.0)/min(resolution.y,resolution.x)*20.0;float f=0.0;float g=3.1415926535*2.0;float h=(-.57166-0.001*mouse.x*0.2+0.0001*time)*g;float i=cos(h);float j=sin(h);vec2 k=vec2(i,-j);vec2 l=vec2(j,i);\nvec2 m=vec2(0,1.0+0.618);float n=1.7171+0.001*mouse.y+0.0001*time;for(int o=0;o<N;o++){float p=dot(e,e);if(p>1.0){p=(1.0)/p;e.x=e.x*p;e.y=e.y*p;}f*=.99;f+=p;e=vec2(dot(e,k),dot(e,l))*n+m;}float q=fract(f);q=2.0*min(q,1.0-q);float r=mod(time/20.0,1.0);gl_FragColor=vec4(a(vec3(mod(r-0.2*abs(sin(q)),1.0),mod(0.7 + 0.3*pow(q,3.0)*cos(q+0.1*time),1.0),mod(pow(q, 0.8), 1.0))),1.0);}"
    @uniforms = @material.uniforms

    plane = new THREE.PlaneGeometry(@width, @height)
    quad = new THREE.Mesh(plane, @material)
    quad.position.z = -100
    @scene.add(quad)
  
    @renderer = new THREE.WebGLRenderer()
    @$banner.append(@renderer.domElement)
    @animating = $('body').is('.front')
    @random = Math.random()
    @timeOffset = 0

    $(window).resize (e) => @resize(e)
    $(window).mousemove (e) => @mousemove(e)
    $('header').click (e) => @toggleAnimation()

  resize: (e) ->
    @width = @$banner.width()
    @height = @$banner.height()
    @uniforms.resolution.value = new THREE.Vector2(@width, @height)
    @camera.aspect = @width / @height
    @camera.updateProjectionMatrix()
    @renderer.setSize(@width, @height)

  mousemove: (e) ->
    @uniforms.mouse.value = new THREE.Vector2(e.clientX / @width, 1 - e.clientY / @height)

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
      @uniforms.time.value = @timestamp + @timeOffset + @random * 200
      @renderer.clear()
      @renderer.render(@scene, @camera)

    requestAnimationFrame (timestamp) => @render(timestamp)

$ ->
  window.banner = new Banner()
  banner.resize()
  banner.render()
