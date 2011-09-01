theCanvas = document.getElementById('c')
ctx = theCanvas.getContext('2d')

CANVAS_WIDTH = theCanvas.width
CANVAS_HEIGHT = theCanvas.height
GRID_SCALE = 20
GRID_MAJOR_SCALE = GRID_SCALE * 10

currentBlockType = 1
currentColorIndex = 1
currentLayerIndex = 1
currentLayer = null
canvasMouseDown = false
canvasDrawing = false

drawLine = (x1, y1, x2, y2) ->
  ctx.beginPath()
  ctx.moveTo x1, y1
  ctx.lineTo x2, y2
  ctx.stroke()
  
drawGrid = ->
  # Draw minor lines
  ctx.strokeStyle = '#e8e8e8'
  for y in [GRID_SCALE..CANVAS_HEIGHT] by GRID_SCALE
    drawLine 0, y+0.5, CANVAS_WIDTH, y+0.5
  for x in [GRID_SCALE..CANVAS_WIDTH] by GRID_SCALE
    drawLine x+0.5, 0, x+0.5, CANVAS_HEIGHT

  # Draw major lines
  ctx.strokeStyle = '#c8c8c8'
  for y in [GRID_MAJOR_SCALE..CANVAS_HEIGHT] by GRID_MAJOR_SCALE
    drawLine 0, y+0.5, CANVAS_WIDTH, y+0.5
  for x in [GRID_MAJOR_SCALE..CANVAS_WIDTH] by GRID_MAJOR_SCALE
    drawLine x+0.5, 0, x+0.5, CANVAS_HEIGHT

drawPolygon = (coords) ->
  ctx.beginPath()
  for index in [0..coords.length] by 2
    ctx.moveTo(coords[index], coords[index+1]) if index == 0
    ctx.lineTo(coords[index], coords[index+1]) if index != 0
  ctx.fill()

drawBlock = (block) ->
  ctx.fillStyle = colors[block.color]
  x1 = block.x * GRID_SCALE 
  y1 = block.y * GRID_SCALE 
  x2 = x1 + GRID_SCALE 
  y2 = y1 + GRID_SCALE
  drawPolygon [x1, y1, x2, y1, x2, y2, x1, y2] if block.type == 1
  drawPolygon [x2, y1, x2, y2, x1, y2] if block.type == 2
  drawPolygon [x1, y1, x1, y2, x2, y2] if block.type == 3
  drawPolygon [x1, y1, x2, y1, x1, y2] if block.type == 4
  drawPolygon [x1, y1, x2, y1, x2, y2] if block.type == 5

drawLayer = (layer) ->
  if layer.visible
    drawBlock(block) for block in layer.blocks
  
drawLayers = ->
  drawLayer(layer) for layer in layers

layers = [
  { visible: true, blocks: [] }, 
  { visible: true, blocks: [] }, 
  { visible: true, blocks: [] }, 
  { visible: true, blocks: [] }, 
  { visible: true, blocks: [] }]

colors = ['#000', '#300', '#600', '#900', '#c00', '#f00']

redraw = ->
  # Clear canvas
  theCanvas.width = CANVAS_WIDTH
  drawGrid()
  drawLayers()
  dumpLog()

dumpLog = ->
  $('#log').val( JSON.stringify(layers))

loadLog = ->
  layers = JSON.parse($('#log').val())
  currentLayer = layers[currentLayerIndex - 1]
  redraw()

canvasToBlockCoordinates = (x, y) ->
  [Math.floor(x / GRID_SCALE), Math.floor(y / GRID_SCALE)]

createBlock = (layer, x, y) ->
  layer.blocks.push {x: x, y: y, type: currentBlockType, color: currentColorIndex}

destroyBlock = (layer, x, y) ->
  layer.blocks = _.reject(layer.blocks, (b) -> b.x == x and b.y == y)

hasBlock = (layer, x, y, blockType, colorIndex) ->
  _.any(layer.blocks, (b) -> b.x == x and b.y == y and b.type == blockType and b.color == colorIndex)

canvasClicked = (x, y) ->
  canvasMouseDown = true
  [blockX, blockY] = canvasToBlockCoordinates x, y
  if currentLayer.visible
    if not hasBlock(currentLayer, blockX, blockY, currentBlockType, currentColorIndex)
      # The block could exist, but be of another block type.
      destroyBlock currentLayer, blockX, blockY
      createBlock currentLayer, blockX, blockY
      canvasDrawing = true
    else
      destroyBlock currentLayer, blockX, blockY
      canvasDrawing = false
    redraw()
  
canvasDragged = (x, y) ->
  [blockX, blockY] = canvasToBlockCoordinates x, y
  if canvasDrawing
    destroyBlock currentLayer, blockX, blockY
    createBlock currentLayer, blockX, blockY
  else
    destroyBlock currentLayer, blockX, blockY
  redraw()

setCurrentBlockType = (type) ->
  $('#block-types button').removeClass('current')
  $('#block-types button[data-block-type=' + type+ ']').addClass('current')
  currentBlockType = type

$('#block-types button').mousedown (e) ->
  setCurrentBlockType(parseInt($(this).attr('data-block-type')))

initializeColorIndices = ->
  for color, index in colors
    $('#colors button[data-color-index=' + index + ']').css('background-color', color)
    
setCurrentColorIndex = (index) ->
  $('#colors button').removeClass('current')
  $('#colors button[data-color-index=' + index + ']').addClass('current')
  currentColorIndex = index

$('#colors button').mousedown (e) ->
  setCurrentColorIndex(parseInt($(this).attr('data-color-index')))
  
setCurrentLayerIndex = (index) ->
  $('#layers button').removeClass('current')
  $('#layers button[data-layer-index=' + index + ']').addClass('current')

  currentLayerIndex = index
  # Indexes are 1-based, but layer objects are stored zero-based.
  currentLayer = layers[index-1]
  
$('#layers button').click (e) ->
  setCurrentLayerIndex(parseInt($(this).attr('data-layer-index')))
  
toggleLayerVisible = (index) ->
  # Indexes are 1-based, but layer objects are stored zero-based.
  layer = layers[index-1]
  layer.visible = !layer.visible
  el = $('#layers-visible button[data-layer-index=' + index + ']')
  if layer.visible
    el.addClass 'checked'
  else
    el.removeClass 'checked'
  redraw()
  
$('#layers-visible button').click (e) ->
  toggleLayerVisible(parseInt($(this).attr('data-layer-index')))
  
$('#load-log').click (e) -> loadLog()
  
$('#c')
  .mousedown (e) ->
    if e.offsetX
      canvasClicked e.offsetX, e.offsetY
    else if e.pageX
      canvasClicked e.pageX, e.pageY
    e.preventDefault()
  .mouseup (e) ->
    canvasMouseDown = false
  .mousemove (e) ->
    if e.offsetX
      canvasDragged e.offsetX, e.offsetY if canvasMouseDown
    else if e.pageX
      canvasDragged e.pageX, e.pageY if canvasMouseDown
    e.preventDefault()

$(document.body).keypress (e) ->
  char = String.fromCharCode(e.which)
  if '0' <= char <= '9'
    setCurrentBlockType(parseInt(char))
  else if (colorIndex = 'qwerty'.indexOf(char) + 1) > 0
    setCurrentColorIndex(colorIndex)
  
initializeColorIndices()
setCurrentBlockType 1
setCurrentColorIndex 1
setCurrentLayerIndex 1
redraw()

