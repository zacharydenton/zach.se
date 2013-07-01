(function() {
  var Game, cameraEnabled, canvasCtx, canvasInput, drawIdent, enableStart, gUMnCamera, htracker, offsetX, offsetY, videoInput,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Game = (function() {
    var createExplosion,
      _this = this;

    function Game() {
      this.animate = __bind(this.animate, this);
      this.init = __bind(this.init, this);
      this.onDocumentMouseMove = __bind(this.onDocumentMouseMove, this);
      this.onKeyPress = __bind(this.onKeyPress, this);
      this.onKeyUp = __bind(this.onKeyUp, this);
      this.onKeyDown = __bind(this.onKeyDown, this);
      this.onWindowResize = __bind(this.onWindowResize, this);
      var _this = this;

      this.status = 0;
      this.health = this.speed = this.maxSpeed = this.speedLimit = this.view = this.tm = this.score = this.hiScore = null;
      this.shipX = this.shipY = 0;
      this.fullscreen = this.windowHalfX = this.windowHalfY = this.windowX = this.windowY = null;
      this.mx = this.my = 0;
      this.light1 = this.light2 = null;
      this.sensitivity = 1;
      this.sen = 1;
      this.autoSwitch = 1;
      this.controls = 0;
      this.yInvert = 0;
      this.keyUp = this.keyDown = this.keyLeft = this.keyRight = this.keySpace = false;
      this.container = this.ctx = null;
      this.camera = this.scene = this.renderer = null;
      this.geometry = this.dust = null;
      this.group2 = this.group2color = null;
      this.ship = null;
      this.mouseX = this.mouseY = this.faceX = this.faceY = 0;
      this.particles = new Array();
      this.bullet = null;
      this.objs = this.background = null;
      this.explosions = [];
      this.fov = 80;
      this.fogDepth = 3500;
      this.tm = this.dtm = this.track = this.nextFrame = this.phase = null;
      this.zCamera = this.zCamera2 = 0;
      this.p = new Array();
      this.sensList = ['low', 'default', 'high', 'very high', 'extreme'];
      this.sensValue = [1, 1.3, 1.6, 2, 4];
      this.controlsList = ['mouse', 'arrows / WASD', 'head tracking'];
      this.spark = THREE.ImageUtils.loadTexture('img/spark.png');
      this.introReset(false);
      this.init();
      this.animate();
      $('#start').on('click', function() {
        _this.gameReset();
        $('#hud').show();
        $('#score').show();
        $('#like').hide();
        $('#panel1').hide();
        return $('#feedback').hide();
      });
      $('#options').on('click', function() {
        $('#panel1').hide();
        return $('#panel2').show();
      });
      $('#op_sensitivity').on('click', function() {
        _this.sensitivity += 1;
        _this.sensitivity %= 4;
        return _this.updateUI();
      });
      $('#op_close').on('click', function() {
        $('#panel2').hide();
        return $('#panel1').show();
      });
      $('#op_1stperson').on('click', function() {
        _this.autoSwitch = 1 - _this.autoSwitch;
        return _this.updateUI();
      });
      $('#op_controls').on('click', function() {
        _this.controls += 1;
        _this.controls %= 3;
        return _this.updateUI();
      });
      $('#op_yinvert').on('click', function() {
        _this.yInvert = 1 - _this.yInvert;
        return _this.updateUI();
      });
    }

    Game.prototype.gameReset = function() {
      var obj, _i, _len, _ref;

      console.log('gameReset');
      this.health = 100;
      this.speed = 0;
      this.score = 0;
      this.status = 1;
      this.shipX = 0;
      this.shipY = 0;
      this.view = 1;
      this.maxSpeed = 52;
      this.speedLimit = 100;
      this.zCamera2 = 0;
      _ref = this.objs.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        obj = _ref[_i];
        obj.position.x = Math.random() * 5000 - 2500;
        obj.position.y = -300;
      }
      return $('#score').html(this.score);
    };

    Game.prototype.introReset = function(gameCompleted) {
      console.log('introReset');
      this.speed = 0;
      this.view = 2;
      this.status = 0;
      this.hiScore = this.get('fk2hiscore', 0);
      if (gameCompleted && this.hiScore < this.score) {
        this.set('fk2hiscore', this.score);
      }
      $('#score').html("Hi-Score: " + this.hiScore);
      $('#hud').hide();
      $('#like').show();
      $('#panel1').show();
      return $('#feedback').show();
    };

    Game.prototype.onWindowResize = function() {
      this.windowX = window.innerWidth;
      this.windowY = window.innerHeight;
      this.windowHalfX = this.windowX / 2;
      this.windowHalfY = this.windowY / 2;
      this.camera.aspect = this.windowX / this.windowY;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(this.windowX, this.windowY);
      return this.fullscreen = this.windowX === window.outerWidth;
    };

    Game.prototype.get = function(id, def) {
      var value;

      value = localStorage.getItem(id);
      if (value == null) {
        value = def;
      }
      return parseInt(value);
    };

    Game.prototype.set = function(id, value) {
      if (value == null) {
        value = 0;
      }
      return localStorage.setItem(id, value);
    };

    Game.prototype.updateUI = function() {
      $('#op_sensitivity').html("controls sensitivity : " + this.sensList[this.sensitivity]);
      $('#op_1stperson').html("automatic 1st/3rd person : " + (this.autoSwitch ? 'yes' : 'no'));
      $('#op_controls').html("controls : " + this.controlsList[this.controls]);
      $('#op_yinvert').html("invert Y axis : " + (this.yInvert === 0 ? 'no' : 'yes'));
      this.set('fk2sensitivity', this.sensitivity);
      this.set('fk2autoswitch', this.autoSwitch);
      this.set('fk2controls', this.controls);
      return this.set('fk2yinvert', this.yInvert);
    };

    Game.prototype.drawSector = function(centerX, centerY, r, startingAngle, endingAngle, color) {
      var arcSize;

      this.ctx.save();
      arcSize = endingAngle - startingAngle;
      this.ctx.beginPath();
      this.ctx.moveTo(centerX, centerY);
      this.ctx.arc(centerX, centerY, r * 0.65, 0, Math.PI * 2, false);
      this.ctx.closePath();
      this.ctx.fillStyle = '#000000';
      this.ctx.fill();
      this.ctx.beginPath();
      this.ctx.moveTo(centerX, centerY);
      this.ctx.arc(centerX, centerY, r * 0.60, 0, Math.PI * 2, false);
      this.ctx.closePath();
      this.ctx.fillStyle = '#ff0000';
      this.ctx.fill();
      if (this.health > 0) {
        this.ctx.beginPath();
        this.ctx.moveTo(centerX, centerY);
        this.ctx.arc(centerX, centerY, r * 0.60 * (this.health / 100), 0, Math.PI * 2, false);
        this.ctx.closePath();
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fill();
      }
      return this.ctx.restore();
    };

    Game.prototype.rgbColor = function(r, g, b) {
      return b + (256 * g) | 0 + (256 * 256 * r) | 0;
    };

    Game.prototype.createSkybox = function() {
      var cubemap, material, shader, skybox, urls;

      urls = ['img/sky05_lf.png', 'img/sky05_rt.png', 'img/sky05_up.png', 'img/sky05_dn.png', 'img/sky05_ft.png', 'img/sky05_bk.png'];
      cubemap = THREE.ImageUtils.loadTextureCube(urls);
      cubemap.format = THREE.RGBFormat;
      shader = THREE.ShaderLib["cube"];
      shader.uniforms["tCube"].value = cubemap;
      material = new THREE.ShaderMaterial({
        fragmentShader: shader.fragmentShader,
        vertexShader: shader.vertexShader,
        uniforms: shader.uniforms,
        depthWrite: false,
        side: THREE.BackSide
      });
      skybox = new THREE.Mesh(new THREE.CubeGeometry(1.6 * this.fogDepth, 1.6 * this.fogDepth, 1.6 * this.fogDepth), material);
      return this.scene.add(skybox);
    };

    Game.prototype.fireWeapon = function() {
      var i, material, range, sprite, total, _i;

      if (this.bullet != null) {
        return;
      }
      this.bullet = new THREE.Object3D();
      this.bullet.attributes = {
        startSize: [],
        startPosition: [],
        randomness: []
      };
      total = 200;
      range = 100;
      for (i = _i = 0; 0 <= total ? _i < total : _i > total; i = 0 <= total ? ++_i : --_i) {
        material = new THREE.SpriteMaterial({
          map: this.spark,
          useScreenCoordinates: false,
          color: 0xffffff
        });
        sprite = new THREE.Sprite(material);
        sprite.scale.set(32, 32, 1.0);
        sprite.position.set(Math.random() - 0.5, Math.random() - 0.5, Math.random() - 0.5);
        sprite.position.setLength(range * (Math.random() * 0.1 + 0.9));
        sprite.material.color.setHSL(Math.random(), 0.9, 0.7);
        sprite.material.blending = THREE.AdditiveBlending;
        this.bullet.add(sprite);
        this.bullet.attributes.startPosition.push(sprite.position.clone());
        this.bullet.attributes.randomness.push(Math.random());
      }
      this.bullet.position = {
        x: this.ship.position.x,
        y: this.ship.position.y,
        z: this.ship.position.z - 100
      };
      return this.scene.add(this.bullet);
    };

    createExplosion = function(position) {
      var explosion, i, material, particles, total, v, _i;

      if (game.explosions.length > 20) {
        return;
      }
      particles = new THREE.Geometry();
      material = new THREE.ParticleBasicMaterial({
        blending: THREE.AdditiveBlending
      });
      material.color.setHSL(Math.random(), 0.9, 0.7);
      total = 5000;
      for (i = _i = 0; 0 <= total ? _i < total : _i > total; i = 0 <= total ? ++_i : --_i) {
        v = new THREE.Vector3(0.5 - Math.random(), 0.5 - Math.random(), 0.5 - Math.random());
        v.multiplyScalar(50 * (0.9 + 0.1 * Math.random()) / v.length());
        particles.vertices.push(v);
      }
      explosion = new THREE.ParticleSystem(particles, material);
      explosion.position = position;
      explosion.rotation.x = Math.random();
      explosion.rotation.y = Math.random();
      explosion.rotation.z = Math.random();
      game.scene.add(explosion);
      return game.explosions.push(explosion);
    };

    Game.prototype.generateCubesRing = function(cubes, y, radius, spreading, depthSpread, sizeVariance) {
      var geometry, i, mergedGeo, mesh, _i;

      mergedGeo = new THREE.Geometry();
      geometry = new THREE.CubeGeometry(10, 10, 10);
      mesh = new THREE.Mesh(geometry);
      for (i = _i = 0; 0 <= cubes ? _i < cubes : _i > cubes; i = 0 <= cubes ? ++_i : --_i) {
        mesh.scale.x = mesh.scale.y = mesh.scale.z = 1 + Math.random() * sizeVariance;
        mesh.position.x = Math.cos(i / cubes * Math.PI * 2) * radius + Math.random() * spreading - spreading / 2;
        mesh.position.y = y + Math.random() * depthSpread;
        mesh.position.z = Math.sin(i / cubes * Math.PI * 2) * radius + Math.random() * spreading - spreading / 2;
        mesh.rotation.x = Math.random() * 360 * (Math.PI / 180);
        mesh.rotation.y = Math.random() * 360 * (Math.PI / 180);
        THREE.GeometryUtils.merge(mergedGeo, mesh);
      }
      return mergedGeo;
    };

    Game.prototype.generateObstacle = function() {
      var geometry, material, mesh;

      geometry = new THREE.SphereGeometry(50, 5, 3);
      material = new THREE.MeshPhongMaterial({
        color: 0xffffff,
        specular: 0xffffff,
        shininess: 150,
        opacity: 1,
        shading: THREE.FlatShading
      });
      mesh = new THREE.Mesh(geometry, material);
      mesh.matrixAutoUpdate = true;
      mesh.updateMatrix();
      this.objs.add(mesh);
      return mesh;
    };

    Game.prototype.generateShip = function() {
      var createExhaust, geometry_cube, geometry_cyl, geometry_cyl2, group, material, mergedGeo, mesh, mesh2, mesh3,
        _this = this;

      mergedGeo = new THREE.Geometry();
      geometry_cube = new THREE.CubeGeometry(50, 50, 50);
      geometry_cyl = new THREE.CylinderGeometry(50, 20, 50, 8, 1);
      geometry_cyl2 = new THREE.CylinderGeometry(50, 40, 50, 4, 1);
      material = new THREE.MeshPhongMaterial({
        color: 0xffffff,
        specular: 0xffffff,
        shininess: 50,
        opacity: 1,
        shading: THREE.FlatShading
      });
      mesh = new THREE.Mesh(geometry_cube, material);
      mesh2 = new THREE.Mesh(geometry_cyl, material);
      mesh3 = new THREE.Mesh(geometry_cyl2, material);
      mesh2.position.x = 0;
      mesh2.position.y = 0;
      mesh2.position.z = 0;
      mesh2.rotation.x = Math.PI / 2;
      mesh2.rotation.y = Math.PI / 2;
      mesh2.scale.x = 0.25;
      THREE.GeometryUtils.merge(mergedGeo, mesh2);
      mesh3.position.x = 0;
      mesh3.position.y = 0;
      mesh3.position.z = 16;
      mesh3.rotation.x = Math.PI / 2;
      mesh3.rotation.y = Math.PI / 2;
      mesh3.scale.x = 0.1;
      mesh3.scale.y = 0.5;
      mesh3.scale.z = 1.6;
      THREE.GeometryUtils.merge(mergedGeo, mesh3);
      mesh.position.y = 15;
      mesh.position.z = 12;
      mesh.scale.x = 0.015;
      mesh.scale.y = 0.4;
      mesh.scale.z = 0.25;
      mesh.rotation.y = 0;
      mesh.rotation.x = -Math.PI / 10;
      mesh.position.x = 20;
      mesh.rotation.z = -Math.PI / 20;
      THREE.GeometryUtils.merge(mergedGeo, mesh);
      mesh.position.x = -20;
      mesh.rotation.z = Math.PI / 20;
      THREE.GeometryUtils.merge(mergedGeo, mesh);
      mergedGeo.computeFaceNormals();
      group = new THREE.Mesh(mergedGeo, material);
      group.matrixAutoUpdate = true;
      group.updateMatrix();
      this.scene.add(group);
      createExhaust = function() {
        var exhaust, i, range, sprite, total, _i;

        exhaust = new THREE.Object3D();
        exhaust.attributes = {
          startSize: [],
          startPosition: [],
          randomness: []
        };
        total = 200;
        range = 10;
        for (i = _i = 0; 0 <= total ? _i < total : _i > total; i = 0 <= total ? ++_i : --_i) {
          material = new THREE.SpriteMaterial({
            map: _this.spark,
            useScreenCoordinates: false,
            color: 0xffffff
          });
          sprite = new THREE.Sprite(material);
          sprite.scale.set(4, 4, 1.0);
          sprite.position.set(Math.random() - 0.5, Math.random() - 0.5, Math.random() - 0.5);
          sprite.position.setLength(range * Math.random());
          sprite.material.color.setHSL(0.6 + 0.1 * Math.random(), 0.9, 0.7);
          sprite.material.blending = THREE.AdditiveBlending;
          exhaust.add(sprite);
          exhaust.attributes.startPosition.push(sprite.position.clone());
          exhaust.attributes.randomness.push(Math.random());
        }
        return exhaust;
      };
      this.engine_lt = createExhaust();
      this.engine_lt.position.set(-20, 0, 35);
      group.add(this.engine_lt);
      this.engine_rt = createExhaust();
      this.engine_rt.position.set(20, 0, 35);
      group.add(this.engine_rt);
      return group;
    };

    Game.prototype.onKeyDown = function(event) {
      switch (event.keyCode) {
        case 38:
        case 87:
          return this.keyUp = true;
        case 40:
        case 83:
          return this.keyDown = true;
        case 37:
        case 65:
          return this.keyLeft = true;
        case 39:
        case 68:
          return this.keyRight = true;
        case 27:
          this.materials.opacity = 0;
          $('#body').css('background-color', '#000');
          return this.introReset(false);
      }
    };

    Game.prototype.onKeyUp = function(event) {
      switch (event.keyCode) {
        case 38:
        case 87:
          return this.keyUp = false;
        case 40:
        case 83:
          return this.keyDown = false;
        case 37:
        case 65:
          return this.keyLeft = false;
        case 39:
        case 68:
          return this.keyRight = false;
      }
    };

    Game.prototype.onKeyPress = function(event) {
      switch (event.keyCode) {
        case 32:
          return this.fireWeapon();
      }
    };

    Game.prototype.onDocumentMouseMove = function(event) {
      if (this.controls === 0) {
        this.mouseX = (event.clientX - this.windowHalfX) / this.windowX * 2;
        return this.mouseY = (event.clientY - this.windowHalfY) / this.windowY * 2;
      }
    };

    Game.prototype.init = function() {
      var a, canvas, canvasInput, i, mesh_tmp, obs, r, vector, videoInput, _i, _j;

      this.sensitivity = this.get('fk2sensitivity', 1);
      this.autoSwitch = this.get('fk2autoswitch', 1);
      this.controls = this.get('fk2controls', 2);
      this.yInvert = this.get('fk2yinvert', 0);
      videoInput = document.getElementById('inputVideo');
      canvasInput = document.getElementById('inputCanvas');
      $(window).on('keyup', this.onKeyUp);
      $(window).on('keydown', this.onKeyDown);
      $(window).on('keypress', this.onKeyPress);
      $(window).on('mousemove', this.onDocumentMouseMove);
      this.container = $('div');
      $('body').append(this.container);
      this.camera = new THREE.PerspectiveCamera(90, window.innerWidth / window.innerHeight, 1, this.fogDepth);
      this.camera.position.z = 0;
      this.scene = new THREE.Scene();
      this.light1 = new THREE.DirectionalLight(0xddddff);
      this.light1.position.set(2, -3, 1.5);
      this.light1.position.normalize();
      this.scene.add(this.light1);
      this.light2 = new THREE.DirectionalLight();
      this.light2.color.setHSL(Math.random(), 0.75, 0.5);
      this.light2.position.set(-1.5, 2, 0);
      this.light2.position.normalize();
      this.scene.add(this.light2);
      this.scene.fog = new THREE.Fog(0x000000, 1, this.fogDepth);
      this.dust = new THREE.Geometry();
      for (i = _i = 0; _i < 2000; i = ++_i) {
        r = 850 + Math.random() * 2100;
        a = Math.random() * 2 * Math.PI;
        vector = new THREE.Vector3(Math.cos(a) * r, Math.sin(a) * r, Math.random() * this.fogDepth);
        this.dust.vertices.push(new THREE.Vector3(vector));
      }
      this.materials = new THREE.ParticleBasicMaterial({
        size: 15,
        opacity: 0.1
      });
      this.materials.color.setRGB(1, 1, 1);
      this.particles[0] = new THREE.ParticleSystem(this.dust, this.materials);
      this.particles[0].position.z = 0;
      this.scene.add(this.particles[0]);
      this.particles[1] = new THREE.ParticleSystem(this.dust, this.materials);
      this.particles[1].position.z = -this.fogDepth;
      this.scene.add(this.particles[1]);
      this.background = new THREE.Object3D();
      this.scene.add(this.background);
      mesh_tmp = this.generateCubesRing(300, 0, 1200, 200, 1500, 5);
      mesh_tmp.computeFaceNormals();
      this.group2color = new THREE.MeshPhongMaterial({
        color: 0xff0000,
        specular: 0xffffff,
        shininess: 150,
        shading: THREE.FlatShading
      });
      this.group2 = new THREE.Mesh(mesh_tmp, this.group2color);
      this.group2color.color.setRGB(0, 1, 0);
      this.group2.matrixAutoUpdate = true;
      this.group2.updateMatrix();
      this.background.add(this.group2);
      this.group2.position.z = -this.fogDepth;
      this.group2.rotation.x = Math.PI / 2;
      this.objs = new THREE.Object3D();
      this.scene.add(this.objs);
      for (i = _j = 0; _j < 200; i = ++_j) {
        obs = this.generateObstacle();
        obs.position.z = -i * (this.fogDepth / 200);
        obs.position.x = Math.random() * 5000 - 2500;
        obs.position.y = Math.random() * 3000 - 1500;
        obs.rotation.x = Math.random() * Math.PI;
        obs.rotation.y = Math.random() * Math.PI;
      }
      this.ship = this.generateShip();
      this.renderer = new THREE.WebGLRenderer({
        antialias: true
      });
      canvas = $('#hud')[0];
      this.ctx = canvas.getContext('2d');
      this.renderer.autoClear = true;
      this.renderer.sortObjects = false;
      this.container.append(this.renderer.domElement);
      $(window).resize(this.onWindowResize);
      this.onWindowResize();
      this.tm = (new Date).getTime();
      this.track = 10000;
      this.nextFrame = 0;
      this.phase = 1;
      return this.updateUI();
    };

    Game.prototype.animate = function() {
      var ntm;

      requestAnimationFrame(this.animate);
      ntm = (new Date).getTime();
      this.dtm = ntm - this.tm;
      this.tm = ntm;
      if (this.status === 0) {
        return this.renderIntro();
      } else {
        return this.renderGame();
      }
    };

    Game.prototype.renderIntro = function() {
      var obj, _i, _len, _ref;

      this.clight = (this.tm / 1000000) % 1;
      this.light2.color.setHSL(this.clight, 0.4, 0.5);
      this.zCamera2 = this.zCamera = -220;
      this.xRatio = 1;
      this.yRatio = 1;
      this.camera.position = {
        x: this.shipX * this.xRatio,
        y: this.shipY * this.yRatio,
        z: this.zCamera
      };
      this.group2.position.z += this.speed;
      this.group2.rotation.y = -new Date().getTime() * 0.0004;
      if (this.group2.position.z > 0) {
        this.group2.position.z = -this.fogDepth;
        this.group2color.color.setHSL(Math.random(), 1, 0.5);
      }
      this.camera.lookAt(new THREE.Vector3(this.shipX * 0.5, this.shipY * 0.25, -1000));
      _ref = this.objs.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        obj = _ref[_i];
        obj.rotation.x += 0.01;
        obj.rotation.y += 0.005;
        obj.position.z += this.speed;
        if (obj.position.z > 100) {
          obj.position.z -= this.fogDepth;
          obj.position.x = Math.random() * 3000 - 1500;
          obj.position.y = Math.random() * 3000 - 1500;
        }
      }
      this.renderer.render(this.scene, this.camera);
      this.speed = 0.3;
      this.fov = 110;
      this.camera.fov = this.fov;
      return this.camera.updateProjectionMatrix();
    };

    Game.prototype.renderGame = function() {
      var a, c, collision, exhaust, explosion, i, obj, pulseFactor, r, s, sp, sprite, tmp, x, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3, _ref4;

      if (this.speed > 0) {
        this.clight = this.speed / this.speedLimit;
        $('#body').css('background-color', '#000');
      } else {
        this.clight = 0;
        tmp = -Math.floor(Math.random() * this.speed * 100);
        $('#body').css('background-color', "rgb(" + tmp + ", " + (tmp / 2) + ", 0)");
      }
      this.light2.color.setHSL(this.clight, 0.3, 0.5);
      switch (this.controls) {
        case 0:
          this.mx = Math.max(Math.min(this.mouseX * this.sen, 1), -1);
          this.my = Math.max(Math.min(this.mouseY * this.sen, 1), -1);
          break;
        case 1:
          if (this.keyUp) {
            this.my -= 0.002 * this.dtm * this.sen;
          }
          if (this.keyDown) {
            this.my += 0.002 * this.dtm * this.sen;
          }
          if (this.keyLeft) {
            this.mx -= 0.003 * this.dtm * this.sen;
          }
          if (this.keyRight) {
            this.mx += 0.003 * this.dtm * this.sen;
          }
          this.mx = Math.max(Math.min(this.mx, 1), -1);
          this.my = Math.max(Math.min(this.my, 1), -1);
          break;
        case 2:
          this.mx = Math.max(Math.min(this.faceX * this.sen, 1), -1);
          this.my = Math.max(Math.min(this.faceY * this.sen, 1), -1);
      }
      if (this.yInvert === 1) {
        this.my = -this.my;
      }
      this.shipX = this.shipX - (this.shipX - this.mx * 700) / 4;
      this.shipY = this.shipY - (this.shipY - (-this.my) * 250) / 4;
      if (this.autoSwitch) {
        if (this.speed < 15) {
          this.view = 1;
          this.zCamera2 = 0;
        } else {
          this.view = 2;
          this.zCamera2 = -220;
        }
      }
      if (this.view === 1) {
        this.xRatio = 1.1;
        this.yRatio = 0.5;
      } else {
        this.xRatio = 1;
        this.yRatio = 1;
      }
      this.zCamera = this.zCamera - (this.zCamera - this.zCamera2) / 10;
      this.camera.position = {
        x: this.shipX * this.xRatio,
        y: this.shipY * this.yRatio,
        z: this.zCamera
      };
      this.ship.position.x = this.shipX;
      this.ship.position.y = this.shipY;
      this.ship.position.z = -200;
      this.ship.rotation.z = -this.shipX / 1000;
      this.group2.position.z += this.speed;
      this.group2.rotation.y = -new Date().getTime() * 0.0004;
      if (this.group2.position.z > 0) {
        this.group2.position.z = -4000;
        this.group2color.color.setHSL(this.clight, 1, 0.5);
      }
      this.camera.lookAt(new THREE.Vector3(this.shipX * 0.5, this.shipY * 0.25, -1000));
      this.particles[0].position.z += this.speed;
      if (this.particles[0].position.z > 100) {
        this.particles[0].position.z -= this.fogDepth * 2;
      }
      this.particles[1].position.z += this.speed;
      if (this.particles[1].position.z > 100) {
        this.particles[1].position.z -= this.fogDepth * 2;
      }
      if (this.bullet != null) {
        this.bullet.position.z -= this.speedLimit / 4;
        if (this.bullet.position.z < -10000) {
          this.scene.remove(this.bullet);
          this.bullet = null;
        } else {
          this.bullet.rotation.x -= 0.1;
          this.bullet.rotation.y += 0.03;
          _ref = this.bullet.children;
          for (c = _i = 0, _len = _ref.length; _i < _len; c = ++_i) {
            sprite = _ref[c];
            a = this.bullet.attributes.randomness[c] + 1;
            pulseFactor = Math.sin(a * this.tm / 100) * 0.8 + 0.9;
            sprite.position.x = this.bullet.attributes.startPosition[c].x * pulseFactor;
            sprite.position.y = this.bullet.attributes.startPosition[c].y * pulseFactor;
            sprite.position.z = this.bullet.attributes.startPosition[c].z * pulseFactor;
          }
        }
      }
      _ref1 = this.objs.children;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        obj = _ref1[_j];
        obj.rotation.x += 0.01;
        obj.rotation.y += 0.005;
        obj.position.z += this.speed;
        collision = false;
        if ((this.bullet != null) && Math.abs(this.bullet.position.x - obj.position.x) < 200 && Math.abs(this.bullet.position.y - obj.position.y) < 200 && Math.abs(this.bullet.position.z - obj.position.z) < 200) {
          collision = true;
          createExplosion(obj.position.clone());
          this.score += 10;
          $('#score').html(this.score);
        }
        if (obj.position.z > 100 || collision) {
          obj.position.z -= this.fogDepth;
          this.nextFrame++;
          switch (this.phase) {
            case 1:
              if (Math.random() < 0.97) {
                obj.position.x = Math.random() * 3000 - 1500;
                obj.position.y = Math.random() * 3000 - 1500;
              } else {
                obj.position.x = this.ship.position.x;
                obj.position.y = this.ship.position.y;
              }
              break;
            case 2:
            case 3:
              obj.position.x = Math.cos(this.nextFrame / this.p[0]) * this.p[1] * Math.cos(this.nextFrame / this.p[2]) * this.p[3];
              obj.position.y = Math.sin(this.nextFrame / this.p[4]) * this.p[5] * Math.sin(this.nextFrame / this.p[6]) * this.p[7];
              break;
            case 4:
              r = Math.cos(this.nextFrame / this.p[0]) * 2000;
              obj.position.x = Math.cos(this.nextFrame / this.p[1]) * r;
              obj.position.y = Math.sin(this.nextFrame / this.p[1]) * r;
              break;
            case 5:
              if (Math.random() < 0.95) {
                obj.position.x = this.ship.position.x;
                obj.position.y = this.ship.position.y;
              } else {
                obj.position.x = Math.random() * 3000 - 1500;
                obj.position.y = Math.random() * 3000 - 1500;
              }
          }
        }
        if (Math.abs(this.ship.position.x - obj.position.x) < 100 && Math.abs(this.ship.position.y - obj.position.y) < 50 && Math.abs(this.ship.position.z - obj.position.z) < 50) {
          if (this.speed > 0) {
            this.health -= this.speed;
          }
          this.speed = -3;
        }
      }
      if (this.health < 0 && this.speed > 0) {
        this.introReset(true);
      }
      this.renderer.render(this.scene, this.camera);
      this.speed += this.dtm / 300;
      if (this.speed > this.maxSpeed) {
        this.speed = this.maxSpeed;
        this.maxSpeed = Math.min(this.maxSpeed + (this.dtm / 1500), 100);
      }
      if (this.speed > 25) {
        this.score++;
        $('#score').html(this.score);
      }
      this.materials.opacity = this.speed / this.maxSpeed;
      this.track -= this.speed;
      if (this.track < 0) {
        this.track = 5000 + Math.random() * 5000;
        this.phase = Math.floor(Math.random() * 5) + 1;
        switch (this.phase) {
          case 2:
            this.p[0] = Math.random() * 3 + 0.01;
            this.p[1] = 300 + Math.random() * 900;
            this.p[4] = this.p[0];
            this.p[5] = 300 + Math.random() * 900;
            this.p[2] = 8 + Math.random() * 77;
            this.p[3] = Math.random() * 500;
            this.p[6] = 8 + Math.random() * 77;
            this.p[7] = Math.random() * 400;
            break;
          case 3:
            this.p[0] = Math.random() * 30 + 7;
            this.p[1] = 300 + Math.random() * 900;
            this.p[4] = this.p[0];
            this.p[5] = 300 + Math.random() * 700;
            this.p[2] = 8 + Math.random() * 77;
            this.p[3] = 200 + Math.random() * 1000;
            this.p[6] = 8 + Math.random() * 77;
            this.p[7] = 200 + Math.random() * 1000;
            break;
          case 4:
            this.p[0] = Math.random() * 3 + 0.01;
            this.p[1] = (Math.random() * 500 + 40) * (Math.random() > 0.5 ? 1 : -1);
        }
      }
      this.fov = this.fov - (this.fov - (65 + this.speed / 2)) / 4;
      this.camera.fov = this.fov;
      this.camera.updateProjectionMatrix();
      _ref2 = this.explosions;
      for (i = _k = 0, _len2 = _ref2.length; _k < _len2; i = ++_k) {
        explosion = _ref2[i];
        s = explosion.scale;
        explosion.scale.set(1.08 * s.x, 1.02 * s.y, 1.08 * s.z);
        if (explosion.scale.length() > 100) {
          this.scene.remove(explosion);
          this.explosions[i] = null;
        }
      }
      this.explosions = (function() {
        var _l, _len3, _ref3, _results;

        _ref3 = this.explosions;
        _results = [];
        for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
          explosion = _ref3[_l];
          if (explosion != null) {
            _results.push(explosion);
          }
        }
        return _results;
      }).call(this);
      _ref3 = [this.engine_lt, this.engine_rt];
      for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
        exhaust = _ref3[_l];
        _ref4 = exhaust.children;
        for (c = _m = 0, _len4 = _ref4.length; _m < _len4; c = ++_m) {
          sprite = _ref4[c];
          a = exhaust.attributes.randomness[c] + 1;
          if (this.speed > 50) {
            x = 30;
          } else if (this.speed > 45) {
            x = 40;
          } else if (this.speed > 35) {
            x = 60;
          } else if (this.speed > 25) {
            x = 90;
          } else if (this.speed > 15) {
            x = 200;
          } else if (this.speed > 5) {
            x = 300;
          } else {
            x = 500;
          }
          pulseFactor = Math.sin(a * this.tm / x) * 0.1 + 0.9;
          sprite.position.x = exhaust.attributes.startPosition[c].x * pulseFactor;
          sprite.position.y = exhaust.attributes.startPosition[c].y * pulseFactor;
          sprite.position.z = Math.abs(exhaust.attributes.startPosition[c].z * pulseFactor * Math.min(this.speed / 3, 10));
        }
      }
      this.ctx.clearRect(0, 0, 300, 300);
      sp = this.speed / this.speedLimit * Math.PI * 2;
      if (this.speed > 0) {
        return this.drawSector(50, 50, 50, 0, sp, '#00dd44');
      } else {
        return this.drawSector(50, 50, 50, 0, sp, '#992200');
      }
    };

    return Game;

  }).call(this);

  $(function() {
    return window.game = new Game();
  });

  cameraEnabled = false;

  offsetX = offsetY = 0;

  videoInput = document.createElement("video");

  videoInput.setAttribute("loop", "true");

  videoInput.setAttribute("autoplay", "true");

  videoInput.setAttribute("width", "320");

  videoInput.setAttribute("height", "240");

  document.body.appendChild(videoInput);

  gUMnCamera = function() {
    var gumSupported, messages;

    gumSupported = true;
    cameraEnabled = true;
    return messages = ["trying to detect face", "please wait"];
  };

  enableStart = function() {
    document.getElementById("but").className = "";
    document.getElementById("start").innerHTML = "START";
    return document.getElementById("start").addEventListener("click", start, true);
  };

  document.addEventListener("headtrackrStatus", (function(e) {
    switch (e.status) {
      case "camera found":
        return gUMnCamera();
      case "no getUserMedia":
        return noGUM();
      case "no camera":
        return noCamera();
      case "found":
        return enableStart();
    }
  }), false);

  canvasInput = document.createElement("canvas");

  canvasInput.setAttribute("width", "320");

  canvasInput.setAttribute("height", "240");

  htracker = new headtrackr.Tracker({
    smoothing: false,
    fadeVideo: true,
    ui: false
  });

  htracker.init(videoInput, canvasInput);

  htracker.start();

  canvasInput = document.createElement("canvas");

  canvasInput.setAttribute("width", videoInput.clientWidth);

  canvasInput.setAttribute("height", videoInput.clientHeight);

  document.body.appendChild(canvasInput);

  canvasInput.style.position = "absolute";

  canvasInput.style.top = "60px";

  canvasInput.style.left = "10px";

  canvasInput.style.zIndex = "1002";

  canvasInput.style.display = "block";

  canvasCtx = canvasInput.getContext("2d");

  canvasCtx.strokeStyle = "#999";

  canvasCtx.lineWidth = 2;

  drawIdent = function(cContext, x, y) {
    x = (x / 320) * canvasInput.width;
    y = (y / 240) * canvasInput.height;
    x = canvasInput.width - x;
    cContext.clearRect(0, 0, canvasInput.width, canvasInput.height);
    cContext.strokeRect(0, 0, canvasInput.width, canvasInput.height);
    cContext.beginPath();
    cContext.moveTo(x - 5, y);
    cContext.lineTo(x + 5, y);
    cContext.closePath();
    cContext.stroke();
    cContext.beginPath();
    cContext.moveTo(x, y - 5);
    cContext.lineTo(x, y + 5);
    cContext.closePath();
    return cContext.stroke();
  };

  document.addEventListener("facetrackingEvent", (function(e) {
    return drawIdent(canvasCtx, e.x, e.y);
  }), false);

  document.addEventListener("headtrackingEvent", (function(e) {
    if (offsetX === 0 && offsetY === 0) {
      offsetX = e.x;
      offsetY = e.y;
    }
    game.faceX = (e.x - offsetX) * 0.08;
    return game.faceY = -(e.y - offsetY) * 0.08;
  }), false);

}).call(this);
