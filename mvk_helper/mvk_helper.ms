
parentFolder = pathConfig.removePathLeaf (getFileNamePath (getSourceFileName()))
fileIn (pathConfig.appendPath parentFolder "mvk_partNameFunction.ms")

LOGFILE = undefined

fn _selectPartHierarchy root =
(
	if root != undefined do (
		selectmore root
		for child in root.children do _selectPartHierarchy child
	)
)

fn _cleanDisplaySettingsOnObject obj =
(
	obj.boxmode = off
	obj.backfacecull = off
	obj.renderable = on
)

fn _hasGeometryInChildren root =
(
	hasGeo = (superClassOf root == GeometryClass)
	for child in root.children where child != undefined do(
		hasGeo = (_hasGeometryInChildren child) or hasGeo
		if hasGeo do return True
	)
	return hasGeo
)

fn _exportPartsToFileChecked partsList destinationPath =
(
	for root in partsList do(
		max select none
		_selectPartHierarchy root
		_cleanDisplaySettingsOnObject selection
		exportFileName = (destinationPath +"/"+ root.name + ".max")
		format "exporting part % to file % \n" root.name  exportFileName
		saveNodes $ exportFileName
	)
)

fn _getValidParent child =
(
	local validParent = undefined
	if child == undefined do return undefined
	name = child.name
	if extractVBOMPartNoFromName(name) != undefined then(
		validParent = child
	)
	else(
		validParent = _getValidParent(child.parent)
	)
	return validParent
)

fn _hasValidParent child =
(
	local validParent = _getValidParent(child)
	if validParent == child then return False 
	else if validParent == undefined then return False 
	else return True 
	
)

fn _checkForDuplicateParts validParts =
(
	local partNumbers = #()
	for part in validParts do(
		number = extractVBOMPartNoFromName(part.name)
		for part2 in validParts do(
			count = 0
			number2 = extractVBOMPartNoFromName(part2.name)
			if number == number2 do count=count+1
			if count > 1 do(
				format "WARNING: The partNr '%' is used more than once for different objects in this file!\n" number to:LOGFILE
				break
			)
		)
	)
)

fn _collectValidIdentifierParts =
(
	local maybeValidParts = #()
	for obj in objects do(
		objname = obj.name 
		if properEOName(obj) do(
			append maybeValidParts obj
		)
	)
	return maybeValidParts
)

fn _collectValidParts maybeValidParts=
(
	local validParts = #()
	for mvp in maybeValidParts do(
		if not _hasValidParent(mvp) do(
			
			append validParts mvp
		)
	)
	return validParts
)

fn _unparentValidParts validParts=
(
	for vp in validParts do(
		vp.parent = undefined
	)
)

fn _collectValidExportParts validParts =
(
	local validExportParts = #()
	for part in validParts do(
		if not _hasGeometryInChildren(part) then(
			format "WARNING: the part '%' has no geometric children. Ignored for export.\n" part.name to:LOGFILE
		)
		else (
			append validExportParts part
		)
	)
	return validExportParts
)

fn _exportValidPartsToDestination destinationPath=
(
	disablesceneredraw()
	with undo off (
		local maybeValidParts = _collectValidIdentifierParts()
		local validParts = _collectValidParts(maybeValidParts)
		_unparentValidParts(validParts)
		_checkForDuplicateParts(validParts)
		local validExportParts = _collectValidExportParts(validParts)
		if destinationPath != undefined then(
			_exportPartsToFileChecked validExportParts destinationPath
		)
		else(
			for part in validExportParts do(
				format "i would export %\n" part.name
			)
		)
	)
	enablesceneredraw()
)

fn mvk_helper_exportPartsToFolder inputFileName destinationPath =
(
	clearlistener()
	print ("opening max file: " + inputFileName)
	print ("destination path set: " + destinationPath)
	loadMaxFile inputFileName useFileUnits:true quiet:true
	thisFileName = getFileNameFile inputFileName
	logfileName = destinationPath +"/"+thisFileName+"_LOG.txt"
	LOGFILE = openfile logfileName mode:"w"
	_exportValidPartsToDestination destinationPath
	close LOGFILE
	return True
)

registerOLEInterface #(
	mvk_helper_exportPartsToFolder
)

True