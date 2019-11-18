

fn isPartNumberName nameString =
(
	fixValue = nameString
	
	if findstring nameString "CATPart" != undefined then fixValue = substituteString fixValue "_CATPart" ""
	if findstring nameString "igs" != undefined then fixValue = substituteString fixValue "_igs" ""
	if findstring nameString "model" != undefined then fixValue = substituteString fixValue "_model" ""
	if findstring nameString "stp"!= undefined then fixValue = substituteString fixValue "_stp" ""
	if findstring nameString ".fbx"!= undefined then fixValue = substituteString fixValue ".fbx" ""
	if findstring nameString ".FBX"!= undefined then fixValue = substituteString fixValue ".FBX" ""
		
    if fixValue =="" then( return true)
	else (return false)
)


fn properEOName oneObject=
(
	rgx = dotnetObject "System.Text.RegularExpressions.Regex" ""
	str = oneObject.name
	match = rgx.Match str "[0-9A-Z]{10}_(TEST(\d)?_)?[0-9A-Z]{8}|[0-9A-Z]{10}_(RHD|OPEN)_[0-9A-Z]{8}|[0-9A-Z]{10}_POS[0-9]_[0-9A-Z]{8}|[0-9A-Z]{10}_POS[0-9]{4}_[0-9A-Z]{8}|[0-9A-Z]{10}_(RHD|OPEN)_(RHD|OPEN)_[0-9A-Z]{8}|[0-9A-Z]{10}_(RHD|OPEN)_POS[0-9]{4}_[0-9A-Z]{8}|[0-9A-Z]{10}_POS[0-9]{4}_(RHD|OPEN)_[0-9A-Z]{8}|[0-9A-Z]{10}_(RHD|OPEN)_POS[0-9]_[0-9A-Z]{8}|[0-9A-Z]{10}_POS[0-9]_(RHD|OPEN)_[0-9A-Z]{8}|[0-9A-Z]{10}_(RHD|OPEN)_[0-9A-Z]{7}"
	
	mFlag = false

	if match.Success then(
		
		v = match.groups.item[0].value--matched text
		e = substituteString str v ""--unmatched text
		if e == "" then(
			mFlag = true
			
		)else(
			result = isPartNumberName e--recheck unmatched text
			mFlag = result 
			
		)	
	)
	if (findstring str "NONF" != undefined) then( mFlag = true )
	return mFlag
)


fn findPoswhatever nameString = (
	
	if findstring nameString "_POS" != undefined then (
		sepPart= filterstring nameString "_"
		for i in sepPart do (
			if findstring i "POS" != undefined then ( return i )
		)
	)
)

fn isTESTPart nameString =
(
	if findstring nameString "_TEST"!= undefined then return true
	return false
)

fn isOPENPart nameString =
(
	if findstring nameString  "_OPEN" != undefined then return true
	return false
)

fn isRHDPart nameString =
(
	if findstring nameString "_RHD" != undefined then return true
	return false
)

fn is1Part nameString =
(
	if findstring nameString "_1" != undefined then return true
	return false
)

fn is2Part nameString =
(
	if findstring nameString "_2" != undefined then return true
	return false
)

fn is3Part nameString =
(
	if findstring nameString "_3" != undefined then return true
	return false
)

fn is4Part nameString =
(
	if findstring nameString "_4" != undefined then return true
	return false
)


fn extractVBOMPartNoFromName nameString =
(
	rgx = dotnetObject "System.Text.RegularExpressions.Regex" ""
	str = nameString
	match = rgx.Match str ".*_?((?=[a-zA-Z]*[0-9][a-zA-Z]*)[0-9a-zA-Z]{10}_RHD|(?=[a-zA-Z]*[0-9][a-zA-Z]*)[0-9a-zA-Z]{10})_.*"
	if match.Success then(
		return match.groups.item[1].value
	)
	else(
		return undefined
	)
)

fn partNumberFromName nameString =
(
	if nameString.count>=12 then
		return (substring nameString 1 10)
	else return nameString
)

fn endswith wholeString ending =
(
	if ((findstring wholeString ending) == (wholeString.count-ending.count+1)) then return true
	return false
)
