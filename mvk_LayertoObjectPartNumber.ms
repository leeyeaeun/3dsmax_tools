
fileIn "mvk_partNameFunction.ms"
fileIn "mvk_helper/mvk_helper.ms"

fn add2Arr obj arra=(if isValidNode obj and isValidNode obj.parent do(append arra obj.parent;add2Arr obj.parent arra))
	
fn parentCheck ob = (
	local arr = #()
	add2Arr ob arr
	
	for i in arr do(
		if properEOName(i) then(
			return False
		)
	)
	return True
)

fn putHierarchieOnLayer root Layername=
(
	layer = Layermanager.GetLayerFromName Layername
	if layer == undefined then layer = Layermanager.NewLayerFromName Layername
	layer.addnode root
	for child in root.children do putHierarchieOnLayer child Layername
)

fn assignToLayer root =
(
	if properEOName(root) and parentCheck(root) then -- lux
	(
		layerName = partNumberFromName(root.name)

		if isTESTPart(root.name) then
			(
			layerName = layerName + "_TEST"
			afterN = substring root.name 16 1
			if (findstring "0123456789" afterN) != undefined then layerName = layerName + afterN
			)

		POSresult = findPoswhatever(root.name)
		if POSresult != undefined then layerName = layerName + "_" + POSresult
			
		if isOPENPart(root.name) then layerName = layerName + "_OPEN"
		
		if isRHDPart(root.name) then layerName = layerName + "_RHD"

		if is1Part(root.name) then layerName = layerName + "_1"

		if is2Part(root.name) then layerName = layerName + "_2"

		if is3Part(root.name) then layerName = layerName + "_3"

		if is4Part(root.name) then layerName = layerName + "_4"
		
		if (findstring root.name "NONF" != undefined) then( layerName = root.name)
		putHierarchieOnLayer root layerName
		return True
	)
	for child in root.children do assignToLayer child
)

fn deleteEmptyLayers=
(
	beforeDeleteNumLayers = LayerManager.count
	deflayer = LayerManager.getLayer(0)
	deflayer.current = true
	for i = Layermanager.count-1 to 1 by-1 do
	(
		layer = LayerManager.getLayer(i)
		if layer != undefined then
		(
			thislayername = layer.name
			LayerManager.deleteLayerByName thislayername
		)
	)
	numLayers = LayerManager.count
	numLayersDelta = beforeDeleteNumLayers - numLayers
	format "deleted all deleteable layers (% deleted, % layers remain)" (numLayersDelta as string) (numLayers as string)
)

disablesceneredraw()
with undo off (
	local maybeValidParts = _collectValidIdentifierParts()
	local validParts = _collectValidParts(maybeValidParts)
	for n in validParts do assignToLayer n
	deleteEmptyLayers()
)
enablesceneredraw()
