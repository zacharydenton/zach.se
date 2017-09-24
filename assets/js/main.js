"use strict";

(function() {
    function createLines(fragment) {
        var container = document.createElement("div")
        container.className = "space-container"
        var space = document.createElement("div")
        space.className = "space"
        container.appendChild(space)
        fragment.appendChild(container)
        var line = document.createElement("div")
        line.className = "line"
        for (var i = 0; i < 40; i++) {
            var el = line.cloneNode(true)
            el.style.top = 2 * i + 0.4 * Math.random() + 'vh'
            space.appendChild(el)
        }
    }

    function createCircles(fragment) {
        var circle = document.createElement("div")
        circle.className = "circle"
        fragment.appendChild(circle.cloneNode(true))
        circle.className = "circle dark"
        fragment.appendChild(circle.cloneNode(true))
    }

    function createFractal(fragment) {
        var size = 64
        var canvas = document.createElement("canvas")
        canvas.width = canvas.height = size
        canvas.className = "circle fractal"
        fragment.append(canvas)

        var gl = canvas.getContext("webgl") || canvas.getContext("experimental-webgl")
        if (gl == null) return

        var vertexShader = gl.createShader(gl.VERTEX_SHADER)
        gl.shaderSource(vertexShader, "attribute vec2 position;\nvoid main(){gl_Position=vec4(position,0,1);}")
        gl.compileShader(vertexShader)

        var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
        gl.shaderSource(fragmentShader, "precision lowp float;uniform float time;uniform vec2 resolution;vec3 a(vec3 b){vec4 c=vec4(1.,2./3.,1./3.,3.);vec3 d=abs(fract(b.xxx+c.xyz)*6.-c.www);return b.z*mix(c.xxx,clamp(d-c.xxx,.0,1.),b.y);}vec3 e(float f){return vec3(.02,.5,.4)+vec3(.8,.3,.1)*cos(6.28319*(vec3(1.,2.,4.)*f+vec3(.8,.4,.65)));}void main(void){vec2 g=((gl_FragCoord.xy-resolution*.5)/min(resolution.x,resolution.y))*20.;float h=.0;float i=(7.295+.0001*time)*6.28319;float j=cos(i);float k=sin(i);vec2 l=vec2(j,-k);vec2 m=vec2(k,j);vec2 n=vec2(0,1.618);float o=3.521+.0001*time;for(int p=0;p<800;p++){float q=dot(g,g);if(q>1.){q=1./q;g*=q;}h*=.99;h+=q;g=vec2(dot(g,l),dot(g,m))*o+n;}gl_FragColor=vec4(e(fract(.01*time+h)),1.);}")
        gl.compileShader(fragmentShader)

        var shader = gl.createProgram()
        gl.attachShader(shader, vertexShader)
        gl.attachShader(shader, fragmentShader)
        gl.linkProgram(shader)
        gl.useProgram(shader)

        var positionAttrib = gl.getAttribLocation(shader, "position")
        gl.enableVertexAttribArray(positionAttrib)
        var timeUniform = gl.getUniformLocation(shader, "time")
        gl.uniform1f(timeUniform, 0)
        var resolutionUniform = gl.getUniformLocation(shader, "resolution")
        gl.uniform2f(resolutionUniform, size, size)

        var vertexPosBuffer = gl.createBuffer()
        gl.bindBuffer(gl.ARRAY_BUFFER, vertexPosBuffer)
        var vertices = [-1, -1, 1, -1, -1, 1, 1, 1]
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
        gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0)

        var rand = Math.random()
        var timeOffset = 3900
        ;(function render(time) {
            requestAnimationFrame(render)
            var ts = time / 1000
            gl.uniform1f(timeUniform, ts + timeOffset + 300 * rand)
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)
        })(0)
    }
    
    function createSpace() {
        var fragment = document.createDocumentFragment()
        createLines(fragment)
        createCircles(fragment)
        createFractal(fragment)
        document.body.appendChild(fragment)
    }

    if (document.body.classList.contains("front")) {
        createSpace()
    }
})();
