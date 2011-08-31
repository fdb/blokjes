theCanvas = document.getElementById('c')
ctx = theCanvas.getContext('2d')

CANVAS_WIDTH = theCanvas.width
CANVAS_HEIGHT = theCanvas.height
GRID_SCALE = 20
GRID_MAJOR_SCALE = GRID_SCALE * 10

currentBlockType = 1
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
  x1 = block.x * GRID_SCALE 
  y1 = block.y * GRID_SCALE 
  x2 = x1 + GRID_SCALE 
  y2 = y1 + GRID_SCALE
  drawPolygon [x1, y1, x2, y1, x2, y2, x1, y2] if block.type == 1
  drawPolygon [x2, y1, x2, y2, x1, y2] if block.type == 2
  drawPolygon [x1, y1, x1, y2, x2, y2] if block.type == 3
  drawPolygon [x1, y1, x2, y1, x1, y2] if block.type == 4
  drawPolygon [x1, y1, x2, y1, x2, y2] if block.type == 5

drawBlocks = ->
  drawBlock(block) for block in blocks

blocks = []

redraw = ->
  # Clear canvas
  theCanvas.width = CANVAS_WIDTH
  drawGrid()
  drawBlocks()

canvasToBlockCoordinates = (x, y) ->
  [Math.floor(x / GRID_SCALE), Math.floor(y / GRID_SCALE)]

createBlock = (x, y) ->
  blocks.push {x: x, y: y, type: currentBlockType}

destroyBlock = (x, y) ->
  blocks = _.reject(blocks, (b) -> b.x == x and b.y == y)

hasBlock = (x, y, blockType) ->
  _.any(blocks, (b) -> b.x == x and b.y == y and b.type == blockType)

canvasClicked = (x, y) ->
  canvasMouseDown = true
  [blockX, blockY] = canvasToBlockCoordinates x, y
  if not hasBlock(blockX, blockY, currentBlockType)
    # The block could exist, but be of another block type.
    destroyBlock blockX, blockY
    createBlock blockX, blockY
    canvasDrawing = true
  else
    destroyBlock blockX, blockY
    canvasDrawing = false
  redraw()
  
canvasDragged = (x, y) ->
  [blockX, blockY] = canvasToBlockCoordinates x, y
  console.log(blockX, blockY)
  if canvasDrawing
    destroyBlock blockX, blockY
    createBlock blockX, blockY
  else
    destroyBlock blockX, blockY
  redraw()

setCurrentBlockType = (type) ->
  $('#block_types button').removeClass('current')
  $('#block_types button[data-block-type=' + type+ ']').addClass('current')
  currentBlockType = type

$('#block_types button')
  .unbind()
  .mousedown (e) ->
    setCurrentBlockType(parseInt($(this).attr('data-block-type')))

$('#c')
  .unbind()
  .mousedown (e) ->
    #console.log(e)
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
  blockType = parseInt(String.fromCharCode(e.which))
  setCurrentBlockType(blockType) if 0 <= blockType <= 9

setCurrentBlockType 1
redraw()

