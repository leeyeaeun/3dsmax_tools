rx = dotNetObject "System.Text.RegularExpressions.RegEx" "[^0-9]{2}"
scenename=maxFileName
scenepath=maxFilePath
savescene=scenepath+scenename
scenename=filterString scenename "."
sn=filterString scenename[1] "_"
na=""
ccount=sn.count

for i=1 to sn.count do
(
	if (rx.isMatch sn[ccount]) then
	(
		print sn[i]
		ccount=ccount-1
	)
)

print ccount

j=1
while j<(ccount) do
(
	na+=sn[j]
	na+="_"
	j+=1
)

na+=sn[ccount]
print na

for o in objects do
(
setUserPropBuffer o (na)
)

saved = saveMAXFile savescene quiet:true
saved