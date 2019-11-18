
/** before running script, save file as "(originalFileName).max"  **/

thisPath = getFilenamePath (getThisScriptFilename())
otherFilepath = thisPath
pythonFile = thisPath+"convert_forUpdateTargetTable.py"

filein (otherFilepath + "mvk_partNameFunction.ms")
fn putHierarchieOnLayer root layerX =(	
	layerX.addnode root
	if root.name == "ROOT" then root.name = "ROOT_moved"
	for child in root.children do putHierarchieOnLayer child layerX
)

-- check filename 
fn checkFileName =(
	words = filterstring maxFileName "_"
	flag = ""

	if (((finditem words "BIW") != 0)) or (((finditem words "INTERNAL") != 0)) then(return flag)
	
	if ((finditem words "SOFT") != 0) then(
		flag = "soft"
		return flag
		
	)else(
		if ((((finditem words "MOVING") != 0)) or (((finditem words "MOVE") != 0))) then(
			flag = "moving"
			return flag
			
		)else(
			if ((((finditem words "HEV") != 0)) or (((finditem words "EV") != 0)) or (((finditem words "PHEV") != 0)) or (((finditem words "PE") != 0)) or (((finditem words "FL") != 0))) then(
				flag = "ev"
				return flag
			)else(
				if ((((finditem words "EXT") != 0)) or (((finditem words "INT") != 0))) then(
					flag = "normal"
					return flag
				)else(flag = "else")
			)
		)	
	)
	return flag
)

/**
--get partname from dummy	
fn getDummyName = (
	print "start getDummyName..."
	partArray = #()
	partNameArray = #()
	for i in helpers do(		
		iname = i.name
		subname= substring iname 1 3
		if (subname == "EXT" or subname=="INT") then (append partArray i.children)
	)
	
	partNameForfileName = ""
	if(partArray.count != 0 ) then (
		num = partArray[1].count

		if (num>3) then ( partNameForfileName = "_various" )
		else(
			for k in partArray[1] do (partNameForfileName = partNameForfileName + "_" + k.name )
		)
		partNameForfileName =substituteString partNameForfileName " "  "_"				
	)
	return partNameForfileName
)	
**/
fn compare f1 f2 =
(
	n1 = (f1.name.count) as integer
	n2 = (f2.name.count) as integer
	
	case of
	(
	(n1 < n2): -1
	(n1 > n2): 1
	default: 0
	)
)

fn makeTxt filenameTxt finalTxt savepath= (
	
	currentFilename = (filterstring maxFileName ".")[1]
	out_name = ((savepath)+"/"+ filenameTxt + currentFilename+".txt")
	out_file = createfile out_name
	format finalTxt to:out_file
	
	close out_file
)

--FIND DUPLICATE DUMMY----------------------------------------------------------------------------

fn add2Arr obj arra=(if isValidNode obj and isValidNode obj.parent do(append arra obj.parent;add2Arr obj.parent arra))

fn grabchildren abone = (
	childArray = #()
	tempArray = #()
	for z = 1 to abone.children.count do (
		append tempArray abone.children[z])
	while tempArray.count!=0 do (
		abone = tempArray[tempArray.count]
		append childArray abone
		deleteitem tempArray tempArray.count
		for z = 1 to abone.children.count do (
			append tempArray abone.children[z]))
	return childArray
)
fn checkDuplicateDummy = (
	print "Start Check Duplication....."
	orphanArr = #()
	txt = ""
	select $*
	for i in selection do(
		if(iskindof i geometryclass) then (
			arr = #()
			add2Arr i arr
			judgeParent = 0
			for j in arr do(				
				jname = j.name
				isEO= properEOName j
				if (isEO) then ( judgeParent += 1 )
			)
			if (properEOName( i ) != true ) then (
				if (judgeParent < 1) then (
					format "orphan.. : % \n" i.name
					append orphanArr i.name
				)
			)
		)
	)
	if (orphanArr.count != 0) then (
		txt = txt + "\n---------------< Geometry_without_Parent_Dummy >------------------- \n"
		for j in orphanArr do (
			txt = txt + j + "\n"
		)
	)
	
	format "text : ------------------ : % \n" txt

	--find duplicate name not on the same line( it's ok duplicated name is on the same line)

	targetArray = #()
	select $*
	for i in selection do(
		if (properEOName i == true) then(
			append targetArray i
		)
	)
	duplArray = #()
	for j=1 to targetArray.count do(
		for k = j+1 to targetArray.count do(
			if targetArray[j].name == targetArray[k].name then(
				jChildren= grabchildren targetArray[j]
				kChildren= grabchildren targetArray[k]
				
				if (((finditem (jChildren) targetArray[k]) == 0) and ((finditem (kChildren) targetArray[j]) == 0)) then( -- ??? ???? 
					append duplArray (targetArray[k].name)
				)
			)
		)
	)
	
	--------------------------------------------
	
	
	if (duplArray.count !=0) then (
		txt = "\n------------------<Duplicate object List> ------------------\n"
		for i in duplArray do (
			txt = txt + i + "\n"
		)		
	)

	if(txt != "") then (
		nametxt = "_Issue_in_"
		makeTxt nametxt txt maxfilepath
	)
)

fn layerOrganization flag=(
	dbPartNo = ""
	print "start layerOrganization..."
	
	--LayertoObjectPartNumber	
	fileIn (otherFilepath + "mvk_LayertoObjectPartNumber.ms")
	
	--Layer2VSEGroup
	select $helpers
	delete $	
	for i = 1 to (Layermanager.count - 1) do(
		convertLayer = (LayerManager.getLayer i)
		getLayerDummy = convertLayer.name
	
		local layerDummy = getNodeByName getLayerDummy
        if layerDummy != undefined do (
            if classOf layerDummy == Dummy do
                return layerDummy
        )

        layerDummy = Dummy name:getLayerDummy	

        convertLayer.nodes &layerNodes

        for layerNode in layerNodes where layerNode != layerDummy do
            layerNode.parent = layerDummy

        convertLayer.addnode layerDummy		
	)

--Rename By Parent Dummy
	select $*
	parentdummy = #()
	for o in selection do 
	(
		if (iskindof o geometryclass) then 
		(
			if ((o.parent!=undefined)AND((iskindof o.parent dummy)OR(iskindof o.parent Point))) then
			(
				prefix = "_"
				if flag == "soft" then (
					prefix = "_SOFT_"
					append parentdummy o.parent
				)
				format "Rename Object % to %\n" o.name (uniqueName (o.parent.name+prefix))
				o.name = (uniqueName (o.parent.name+prefix))
				
			)
		)
	)
	
	dummyname = ""
	if flag == "soft" then (
		for i in parentdummy do (
			if i.name != dummyname then (
				i.name = i.name + "_SOFT"
			)
			dummyname = i.name
		)
	)
		for i = 0 to layerManager.count-1 do
		(
		  ilayer = layerManager.getLayer i
		  if (ilayer.name != "0" ) then (
			dbPartNo  = dbPartNo + ilayer.name + "," -- for db insert
		  )
		 	-- Soft Rename
		  if (flag == "soft") then(
			  newname =  ilayer.name + "_SOFT"
			  ilayer.setname newname
			  layerName = ilayer.name
			  layer = ILayerManager.getLayerObject i
			  layerNodes = refs.dependents layer
		  )
		)
	return dbPartNo
)

fn scaleAndProp =(
	--Scale Fix  (delete save) -> do not excute
	--fileIn (otherFilepath +  "31-1-transformFix-deletes-instanceTarget-ID-remains.ms")
	
	--insert Prop - (delete save)
	fileIn (otherFilepath + "insert_userprop.ms")
)

--------------------------------db
fn dbUpdate dbPartNo flag= (
	fordb = ""
	if (flag != "soft" and flag != "else" ) then (
		filename = (filterstring maxfilename "_")
		if (flag != "ev") then (
			fordb = "vhcCode:"  + toupper filename[1]+ "\n"
		)else(
			needToStick = toupper filename[1]
			for i in filename do (
				if ((i=="HEV") or (i=="EV") or (i=="PHEV") or (i=="PE") or (i=="FL")) then(
					needToStick = needToStick + toupper i
				)
			)
			
			fordb = "vhcCode:"  + needToStick + "\n"
		)
		fordb = fordb + "partNo:" + dbPartNo+ "\n"
		lowOrHigh = "high"
		for i in filename do (
			if (i == "LOWPOLY") then (lowOrHigh = "low") 
		)
		fordb =  fordb +"lowhigh:" + lowOrHigh+ "\n"
	)
	fordb =  fordb +"max:" + maxfilename
	dbfile = createfile (thisPath+"txt/FORDB.txt")
	format fordb to:dbfile
	close dbfile
		
	python.ExecuteFile pythonFile
		
)

savelist = #()
thePath = ""

fn resetRenderers =
(
	renderers.ActiveShade = Default_Scanline_Renderer()
	print "ActiveShade renderer reset to Scanline"
	renderers.medit = Default_Scanline_Renderer()
	print "Material Editor renderer reset to Scanline"
)

fn wipeEmptyLayers =
(
	(LayerManager.getLayer 0).current =true
	for i=(LayerManager.count-1) to 0 by -1 do
	(
		theLayer = LayerManager.getLayer i
		theLayerName = theLayer.name
		--LayerManager.deleteLayerByName theLayer.name
		if (LayerManager.deleteLayerByName theLayer.name) do ( print ("Deleted empty layer named: " + theLayerName) )
	)
)

fn checkDuplicateNames =
(
		savelist=#()
		namesList=#()
		duplicateNames=#()
		for o in objects do
			(
					if (appendIfUnique namesList o.name) then
					(
						--append saveList o
					)
					else
					(
						append duplicateNames o
					)
			)

		if duplicateNames.count != 0 then
		(
			selectionSets["duplicateNamesObjectsSet"] = duplicateNames
			if (queryBox ("there are objects with conflicting names, want me to automatically rename it for you?") )	then --leave it 
			(
				for o in duplicateNames do
				(
					theString= "the object named " + o.name
					o.name= uniqueName o.name
					print (theString + " has been renamed to " + o.name)
				)
				return true
			)
			else
				(
				for o in duplicateNames do
				(
					print ("The Object " + o.name + " Has a duplicate name")
				)
				messageBox "Please Check the max Listener\nFor objects which have a duplicate name.\nA selectionSet containing the objects with a duplicate name has been created for you."
				return false
				)
		)
		else return true
)

fn saveVSE foldername=
(
	useLayer = true
	if foldername == undefined do return False

	thePath=foldername
	wipeEmptyLayers()
	if useLayer then (
		for i = 1 to Layermanager.count-1 do
		(

			append savelist (LayerManager.getLayer i)
		)
	)else(
	for o in objects do
	(
		if (o.parent== undefined) and (o.children.count>0) do
		(
			append savelist o
		)
	))

	progressStart "Saving VSEs"
	progressUpdate 0
	DidNotCancel=true

	if savelist.count>0 then
		(
			for i = 1 to savelist.count while DidNotCancel do
				(
					DidNotCancel = progressUpdate (100.0*i/savelist.count)

					fname =foldername +"\\"+ savelist[i].name + ".max"

					-- code to check for file existence
					if not (doesFileExist fname) then
					(
						if useLayer==false then
							allchilds = execute ("$'"+savelist[i].name+"'...*")
						else
							result = savelist[i].nodes &allchilds

						result = savenodes allchilds fname
						if result==OK then
							(
								print ( "Saving of " + (getfilenamefile (fname)) + " was successful" )
							)
							else
							(
								print ( "Saving of " + (getfilenamefile (fname)) + " was NOT successful\nCheck if there are network or disk space issues, or if your scene is corrupt!" )
							)
					)
					else
					(
						if ( queryBox ( "Did NOT save " + (getfilenamefile (fname)) + ".max as it already exists in the destination folder.\nWant me to overwrite anyway?" ) )then --leave
						(
							if useLayer==false then
								allchilds = execute ("$'"+savelist[i].name+"'...*")
							else
								result = (savelist[i].nodes &allchilds)

							result = savenodes allchilds fname
							if result==OK then
							(
								print ( "Saving of " + (getfilenamefile (fname)) + " was successful" )
							)
							else
							(
								print ( "Saving of " + (getfilenamefile (fname)) + " was NOT successful\nCheck if there are network or disk space issues, or if your scene is corrupt!" )
							)
						)
						else
						(
							print ("Did NOT save " + (getfilenamefile (fname)) + ".max as it already exists in the destination folder.")
						)
					)
				)
		)
	progressEnd()
	return True
)

fn deleteDummies =
(
	 delete helpers
		Masterdummy = dummy name:(getfilenamefile maxfilename)
		for i in objects do if i!=Masterdummy then i.parent = Masterdummy
)

fn mergeXRefs =
(
	 numXrefs = objXRefMgr.recordCount
	 for i = 1 to (numXrefs) do objXRefMgr.MergeRecordIntoScene (objXRefMgr.GetRecord 1)
)


fn parseXrefsForLayerDeletion doDeleteDummies doMergeXrefs=
(
	if thePath != "" and thePath != undefined then
	(
		theOriginalMaxFile=(maxFilePath+maxFileName)

		theFiles = getFiles (thePath+"\\*.max") --collect all max files in the dir.
		for f in theFiles do --go through all of them
		(
			print ( "Loading file :" + f )
			loadMaxFile f quiet:true
			resetRenderers()
			wipeEmptyLayers()
			if doDeleteDummies then deleteDummies()
			if doMergeXrefs then mergeXRefs()
			if (deletefile f) then ( print ("all good: deleted " + f + " successfully,") ) else (print ( "Shit man, something bad happened with deleting " + f ))
			if (saveMaxFile f) then ( print ("all good: saved " + f + " successfully,") ) else (print ( "Shit man, something bad happened with saving " + f ))
		)

		print ("ReLoading ORIGINAL MasterScene file...")
		loadMaxFile theOriginalMaxFile
		print "spilt done!"
	)
	else
	(
		messageBox "Umh, we have a problem with the script! Contact Lele (elecchi) through spark immediately."
	)
)
--save and insert DB
fn saveNewName dbPartNo flag = (
	originalFile = maxFilePath + maxfilename
	/**
	strPartname = ""
	if partNameForfileName != undefined then(strPartname = partNameForfileName)
	**/
	currentFilename = (filterstring maxFileName ".")[1]
	saveName = maxFilePath + currentFilename 
	saveMaxFile  (saveName  + ".max")
	
	/**
	savedName = (saveName + ".max")
	format "AFTER saveName : %   /// dir : % \n" savedName originalFile

	if (savedName != originalFile ) then (
		wantToDelete= originalFile
		if doesfileexist (wantToDelete) then (	-- if file exists
			try(deletefile wantToDelete)catch(print "error delating file")
			-- ff should have been deleted and all his data
		)
	)
	**/
	
	if ((flag != "soft") and (flag != "") and (flag != "else"))  then (
		dbUpdate dbPartNo flag
		
		if checkDuplicateNames() then(
			resetRenderers()
			currentName = (filterstring originalFile ".")[1]
			makeDir currentName all:true
			passedThrough = saveVSE (currentName) --useLayers instead of dummies
			if passedThrough do (
					 parseXrefsForLayerDeletion false false
			)
		)else(
			messageBox "Please rename the conflicting objects and re-Run the script!"
		)
		
	)
	if (flag == "soft") then(
		nameText = ""
		savepath = "\\\data\SEL-EDITORIAL\04_UNITED_DELIVERY_LIST\PDM_EDIT_INFO\03_Soft_Part_List"
		makeTxt nameText dbPartNo savepath
	)
	--gc light:on
)

/**
fn getRoot node = if isvalidnode node do (while node.parent != undefined do node = node.parent; return node)
topLevel= (getRoot $*[1])
**/

--START POINT
fn main = (
	delete cameras
	format "---------------------------------------------------convert start file : % \n"  (maxfilepath + maxfilename)
	flag = ""
	flag = checkFileName()
	checkDuplicateDummy()
	scaleAndProp()
	if flag != "" or flag != "else" then(
		dbPartNo = layerOrganization flag
	)else(
		nonfFlag = false
		for i in $* do (
			if findstring i.name "NONF" != undefined then(nonfFlag = true ;exit)
		)

		if nonfFlag then ( layerOrganization flag )
		else(
			-- make layer include all object
			fn putHierarchieOnLayer root layerX =(	
				layerX.addnode root
				if root.name == "ROOT" then root.name = "ROOT_moved"
				for child in root.children do putHierarchieOnLayer child layerX
			)

			if $ROOT == undefined then(
				select $*
				dummyObj = Dummy()
				dummyObj.name = "ROOT"
				selection.parent = dummyObj
			)

			s = $ROOT
			while s != undefined do(
				layer = Layermanager.NewLayerFromName s.children[1].name
				putHierarchieOnLayer s layer
				s = $ROOT
			)
			select $helpers
			delete $
		)
	)
	saveNewName dbPartNo flag
)
undo off main()