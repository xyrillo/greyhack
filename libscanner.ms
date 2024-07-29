//Library Scanner - Enhanced
//
if params.len < 1 or params[0] == "-h" or params[0] == "--help" then exit("<b>Usage: "+program_path.split("/")[-1]+" [library]</b>")
//Load metaxploit locally first, then from /lib/ if failed
metaxploit = include_lib(current_path + "/metaxploit.so")
if not metaxploit then
    metaxploit = include_lib("/lib/metaxploit.so")
end if
if not metaxploit then exit("Error: Can't find metaxploit library in the /lib path or the current folder")
//Load target library locally first, then from /lib/ if failed
libPath = params[0]							//Load specified library
scanLib = metaxploit.load(libPath)
if not scanLib then
	scanLib = metaxploit.load("/lib/" + libPath)
	if not scanLib then exit("Error: Unable to find <b>" + libPath + "</b> or <b>/lib/" + libPath + "</b>.")
end if
//Both libraries loaded!

libName = scanLib.lib_name					//Get exact library name
libVer = scanLib.version					//Get exact library version
print("Using <b>" + libName + " " + libVer + "</b>.")					//Confirm which library is loaded, and version
memAddrList = metaxploit.scan(scanLib)									//Scan metaLib for list of memory addresses, save that to memAddrList
print("Found <b>" + memAddrList.len + "</b> memory fields.")			//Report number of vulnerable memory addresses found
for memAddr in memAddrList 												//Begin scanning specific addresses from memAddrList
	print("Scanning address: " + memAddr)		
	vulnList = metaxploit.scan_address(scanLib, memAddr)				//Scan that address in that library, get list of vulnerabilities
	vulnList = vulnList.replace("decompiling source...","")				//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.replace("searching unsecure values...","")		//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.replace("Unsafe check: loop in array ","")		//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.replace("Unsafe check: string copy in ","")		//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.replace(". Buffer overflow.","")				//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.replace("<b>","")								//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.replace("</b>","")								//Clean this junk so we just have the vulnerability string
	vulnList = vulnList.split(char(10)) 								//Cleaning done. vulnList is now an array of mostly vuln strings
	for i in vulnList
		if (i.len > 2 and not i[0]=="*") then print("shim " + libName + " " + libVer + " lnr " + memAddr + " " + i)
		if (i.len > 2 and i[0]=="*") then print("     " + i)
	end for
end for
