class Banner
  constructor: ->
    @$banner = $("#banner")
    @frameCount = 0
    @width = @$banner.width()
    @height = @$banner.height()
    @scene = new THREE.Scene()
    @camera = new THREE.OrthographicCamera(-@width / 2, @width / 2, @height / 2, -@height / 2, -1000, 1000)
    @camera.position.z = 100
    @camera.lookAt @scene.position
  
    @startTime = Date.now()
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
      fragmentShader: [
        "#ifdef GL_ES",
        "precision mediump float;",
        "#endif",
        "uniform float time;uniform vec2 resolution;uniform vec2 mouse;vec3 a(vec3 b){vec4 c=vec4(1.0,2.0/3.0,1.0/3.0,3.0);vec3 d=abs(fract(b.xxx+c.xyz)*6.0-c.www);return b.z*mix(c.xxx,clamp(d-c.xxx,0.0,1.0),b.y);}",
        "#define N 52",
        "void main(void){vec2 e=(gl_FragCoord.xy-resolution/2.0)/min(resolution.y,resolution.x)*20.0;float f=0.0;float g=3.1415926535*2.0;float h=(0.595-0.001*mouse.x*0.2+0.00003*time)*g;float i=cos(h);float j=sin(h);vec2 k=vec2(i,-j);vec2 l=vec2(j,i);",
        "#define MAGIC 0.618",
        "vec2 m=vec2(0,1.0+MAGIC);float n=1.16+0.001*mouse.y+0.00003*time;for(int o=0;o<N;o++){float p=dot(e,e);if(p>1.0){p=(1.0)/p;e.x=e.x*p;e.y=e.y*p;}f*=.99;f+=p;e=vec2(dot(e,k),dot(e,l))*n+m;}float q=fract(f);q=2.0*min(q,1.0-q);float r=mod(0.441+time/30.0,1.0);gl_FragColor=vec4(a(vec3(mod(r+0.5*sin(q+0.1*time),1.0),min(q,1.0),q)),1.0);}"].join("\n")
    @uniforms = @material.uniforms

    plane = new THREE.PlaneGeometry(@width, @height)
    quad = new THREE.Mesh(plane, @material)
    quad.position.z = -100
    @scene.add(quad)
  
    @renderer = new THREE.WebGLRenderer()
    @$banner.append(@renderer.domElement)

    $(window).resize (e) => @resize(e)
    $(window).mousemove (e) => @mousemove(e)

  resize: (e) ->
    @width = @$banner.width()
    @height = @$banner.height()
    @uniforms.resolution.value = new THREE.Vector2(@width, @height)
    @camera.aspect = @width / @height
    @camera.updateProjectionMatrix()
    @renderer.setSize(@width, @height)

  mousemove: (e) ->
    @uniforms.mouse.value = new THREE.Vector2(e.clientX / @width, 1 - e.clientY / @height)

  render: ->
    if @frameCount == 15
      if (Date.now() - @startTime) / 1000 > 15 / 30
        # disable animation
        return
    @uniforms.time.value = (Date.now() - @startTime) / 1000
    @renderer.clear()
    @renderer.render(@scene, @camera)
    @frameCount++
    requestAnimationFrame => @render()

$ ->
  window.banner = new Banner()
  banner.resize()
  banner.render()
