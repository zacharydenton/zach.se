class Spinner
  # based on http://lab.hakim.se/hypnos/

  constructor: (@$canvas) ->
    @canvas = @$canvas[0]
    @context = @canvas.getContext '2d'
    @height = @width = 200
    @radius = 0.5 * Math.min(@width, @height)
    @quality = 75
    @layers = []
    @layerSize = 0.5 * @radius
    @layerOverlap = Math.round(@quality * 0.5)
    @animate = false

  initialize: ->
    for i in [0...@quality]
      @layers.push
        x: (@width / 2) + Math.sin(i / @quality * 2 * Math.PI) * (@radius - @layerSize)
        y: (@height / 2) + Math.cos(i / @quality * 2 * Math.PI) * (@radius - @layerSize)
        r: (i / @quality) * Math.PI * 0.5

    @resize()
    @update()

  resize: ->
    @canvas.width = @width
    @canvas.height = @height

  update: =>
    @clear()
    @paint()

    if @animate
      requestAnimationFrame @update
      @step()

  step: ->
    for i in [0...@layers.length]
      @layers[i].r += 0.07

  clear: ->
    @context.clearRect 0, 0, @canvas.width, @canvas.height

  paint: ->
    for i in [(@layers.length - @layerOverlap)...@layers.length]
      @context.save()
      @context.globalCompositeOperation = 'destination-over'
      @paintLayer @layers[i]
      @context.restore()

    @context.save()
    @context.globalCompositeOperation = 'destination-in'
    @paintLayer @layers[0], true
    @context.restore()

    for layer in @layers
      @context.save()
      @context.globalCompositeOperation = 'destination-over'
      @paintLayer layer
      @context.restore()

  paintLayer: (layer, mask) ->
    size = @layerSize + (if mask then 25 else 0)
    half_size = size / 2

    @context.translate layer.x, layer.y
    @context.rotate layer.r

    unless mask
      @context.strokeStyle = '#092e68'
      @context.lineWidth = 1
      @context.strokeRect -half_size, -half_size, size, size

    @context.fillStyle = '#fff'
    @context.fillRect -half_size, -half_size, size, size

$ ->
  spinner = new Spinner($('header canvas'))
  spinner.initialize()
  $(spinner.canvas).mouseenter ->
    spinner.animate = true
    spinner.update()
  $(spinner.canvas).mouseleave ->
    spinner.animate = false
