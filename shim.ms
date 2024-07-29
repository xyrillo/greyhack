//ZAM12 - ShimShamShallaBim
//14JUN2023
//Added handling for attaining type: File
//File Handling v1 - simple enumeration
//Password (number) handling for changing user passwords
//14JUN2023
//Began interactive mode, static shim needs to be hard coded anyways
//Started prompts for Computer type loot, needs more because more can be done
//Started adding extra enum info for type shell, since it can also get type computer, that can be passed as well.
//TODO: if get shell/computer, prompt for upload of full suite.  *.so's
//15JUN2023
//Added prompt for args if using remloc n and not in the cmd line
//Decided to start cutting out all the save file stuff.  Just show on screen.
//Proof of concept for get_router seems to work from computer object, this could be big\
//The docs page is way out of date, stick to in game for documentation
//TODO: Fix crack passwords prompt <DONE>
//18JUN2023
//Fixed some bugs and error handling with file copy/enum
//Finally fixed and got password changes to work... sorta
//TODO: Still needs password handling for bank/mail.  Honestly, just echoing or copying is probably best
//A rainbow table script would be awesome too, I'm getting enough password reuse to make it worthwhile
//Fixed file copy ability to save as new name, its good now.
//Cleaned up some logic, less lines in main section.  Still should be functionallized though.
//22JUN2023
//Finished up cred harvesting, pretty clean now.
//4SEP2023
//added cred harvesting to file object exploits.
//probs won't work for guest/some users
//5MAY2024
//Looks for librarys in local folder first
//Fixed target library finding and version checking.
//Added getJumpFile function for auto pulling missing files from jump server
//Moved function definitions after initial param check, and before library checks
//26MAY2024
//Migrated to use of shim.lib for global vars
//TODO: update shimlib's use of dynamic global vars



//Check paramters
if params.len < 3 or params[0] == "-h" or params[0] == "--help" then exit("<b>Usage: "+program_path.split("/")[-1]+" [library] [version] [r/l/n] [memory] [value] (args)</b>")

//Static variables
//(moved to shim.lib)
if not import_code("shim.lib")

///////////DEFINE FUNCTIONS

getJumpFile = function(remoteFile)
//Pulls file from jump server to local folder via scp
	localShell = get_shell
	remoteShell = localShell.connect_service(jumpIP, 22, jumpUser, jumpPass)
	remoteShell.scp(remoteFile, current_path, localShell)
end function

recurseFolder = function(folder)
//List objects in a folder.
//If object is a folder, it also gets passed to this function.
//If object is a file, it's file perms get displayed. 
//This effectively recurses a directory and displays all files
	subFiles = folder.get_files()
	subFolders = folder.get_folders()
	print(folder.permissions() + " " + folder.owner() + " " + folder.group() + " " + folder.size() + " " + folder.path())
	for i in subFiles
		print(i.permissions() + " " + i.owner() + " " + i.group() + " " + i.size() + " " + i.path())
	end for
	for i in subFolders
		recurseFolder(i)
	end for
end function

getCreds = function(folder, preserve=0)
//Parses passed folder(typeof File) recursively for any file named Bank/Mail/passwd
//Saves contents of those files to arrays, then returns as monolith string.
//This function calls itself, and passes a preserve of 1 to prevent reseting stored lists.
	if preserve == 0 then
		globals.passwdList = ""
		globals.bankList = []
		globals.mailList = []
	end if
	//begin search
	subFiles = folder.get_files()
	subFolders = folder.get_folders()
	for i in subFiles
		if i.name == "passwd" then i.chmod("o+rwx",0)
		if (i.name == "passwd" and not i.is_binary) then globals.passwdList = (globals.passwdList + i.get_content)
		if i.name == "Bank.txt" then globals.bankList.push(i.get_content)
		if i.name == "Mail.txt" then globals.mailList.push(i.get_content)
	end for
	for i in subFolders
		if i.name == "etc" then i.chmod("o+rwx",0)
		getCreds(i,1)
	end for
	result = globals.passwdList + char(10) + globals.bankList.join(char(10)) + char(10) + globals.mailList.join(char(10))
	return result
end function

fileContentCopy = function(srcFile, destName = "")
//gets content of passed file and saves to dstName
	if srcFile.is_binary then return ("Cannot copy binary files.")		//Can only copy ascii without a shell
	if srcFile.is_folder then return ("Cannot copy folder.")			//Can only copy ascii without a shell
	if srcFile.has_permission("r") == false then return ("Do not have read permissions.")
	if dstName == "" then dstName = srcFile.name 									//Check if new name, or keep name
	if get_shell.host_computer.touch(current_path, dstName) then		//Check if can make local dest file
		//Get that made local File object, or return contents if can't
		localFile = get_shell.host_computer.File(dstName)
		if not localFile then return ("Error getting local handle.  Dumping to term:" + char(20) + file.get_content)
		localFile.set_content(srcFile.get_content)						//Write contents to new local File obj
		return localFile.name + " saved as " + dstName + "."		//Return success string
	else
		return get_shell.host_computer.touch(current_path, dstName)	//Return error from touch
	end if
end function

getBinFile = function(srcFile, dstName)
	if srcFile.has_permission("r") == false then return ("Do not have read permissions.")
	print(srcFile.permissions())
	print(typeof(srcFile))
	//dstName = "tgt"
	//if dstName == "" then dstName = srcFile.name 									//Check if new name, or keep name
	//if get_shell.host_computer.touch(current_path, dstName) then		//Check if can make local dest file
	copyResult = srcFile.copy("/home/guest", "Config2")
	if typeof(copyResult) == "string" then return ("Error: " + copyResult)
	//else
	//	return get_shell.host_computer.touch(current_path, dstName)	//Return error from touch
	//end if
end function

//Pretty sure this is deprecated, but has some good flow
writeCreds = function(data, file)	//Saves data to file, format is specific
	if not data then exit("Write: error, no data")
	if not file then file = "/loot/zam_temp.log"
	credStr = ""
	for item in data["user_name"]
		i = item["key"]
		credStr = credStr + data["user_name"][i] + ":" + data["user_pass"][i] + char(10)
		if data["user_name"][i] != "root" then
			credStr = credStr + "  " + data["mail_name"][i] + ":" + data["mail_pass"][i] + char(10)
			credStr = credStr + "  " + data["bank_name"][i] + ":" + data["bank_pass"][i] + char(10)
		end if
	end for
	globals.credStr = credStr
	outStr = headStr + char(10) + credStr
	print(outStr)
	if not get_shell.host_computer.File(file) then get_shell.launch("/bin/touch", file)
	outFile = get_shell.host_computer.File(file)
	outFile.set_content(outStr)
	print("Results saved.")
	print("Notepad.exe " + file)
end function

////////END FUNCTIONS




////////////////////////////////////
////////////POST EXPLOIT FUNCTIONS

resultType_Shell = function(result)
	enumPrompt = ""
	if enumPrompt != "a" then enumPrompt = user_input("Enumerate computer? [y/N/a] ", 0, 1).lower
	if enumPrompt == "y" or enumPrompt == "a" then
		computerObj = result.host_computer
		portsC = computerObj.get_ports
		if (portsC.len() > 0) then
			for i in portsC
				print(i.get_lan_ip() + ":" + i.port_number() + " " + i.is_closed())
			end for
		end if
	end if
	if enumPrompt != "a" then enumPrompt = user_input("Obtain interactive shell? [y/N/a] ", 0, 1).lower
	if enumPrompt == "y" or enumPrompt == "a" then
		result.start_terminal
	end if
end function


//File type result
resultType_File = function(result)
	resultType_File(result)
	fileName = result.name()
	filePath = result.path()
	filePerm = result.permissions()
	fileSize = result.size()
	fileOwner = result.owner()
	fileGroup = result.group()
	print(filePerm + " " + fileOwner + " " + fileGroup + " " + fileSize + " " + filePath)
	print("You currently have the following access:")
	if (result.has_permission("r")) then print("R = TRUE") else print("R = FALSE")
	if (result.has_permission("w")) then print("W = TRUE") else print("W = FALSE")
	if (result.has_permission("x")) then print("X = TRUE") else print("X = FALSE")
	if (result.is_folder()) then 
		subFiles = result.get_files()		//subFiles is a list of File Objects
		subFolders = result.get_folders()  //subFolders is a list of File Objects
		for i in subFiles
			print(i.permissions() + " " + i.owner() + " " + i.group() + " " + i.size() + " " + i.path())
		end for
		for i in subFolders
			recurseFolder(i)
		end for
	else
		if (result.is_binary()) then print("This is a binary file.") else print("This is an ASCII file.")
	end if
	opt = user_input("Attempt to enumerate credentials? [y/n/a]", 0, 1).lower()
	if (opt == "y" or opt == "a") then
		fs = result.parent()
		while (fs.path() != "/")
			fs = fs.parent()
		end while
		credsList = getCreds(fs)
		dstName = value + "_creds.txt"
		if get_shell.host_computer.touch(current_path, dstName) then localFile = get_shell.host_computer.File(dstName)
			//Check if can make local dest file
			//Get that made local File object, or return contents if can't
		if not localFile then print("Error getting local handle.  Dumping to term:" + char(20) + credsList)
		localFile.set_content(credsList)									//Write contents to new local File obj
		print("Creds saved as " + dstName + "."	)	//Return success string
	end if
end function

//Computer Type Result
resultType_Computer = function(result)
	//Check for user type via file permissions
	userLevel = "non-root user"
	//If can write this, then you have root
	if result.File("/root/.Trash").has_permission("w") == 1 then 
		userLevel = "root"
	//If can't read this, then have guest
	else if result.File("/root/.Trash").has_permission("r") == 0 then 
		userLevel = "guest"
	end if
	print("Obtained [Computer] with userlevel: " + userLevel)
	//Check processes, skip if guest
	if userLevel == "guest" then
		print("Skipping process enumeration due to user: guest")
	else if userLevel != "guest" then
		enumPrompt = user_input("Show running processes? [y/N/a]", 0, 1).lower
		if enumPrompt == "y" or "a" then 
			print(result.show_procs)
			procKill = " "
			while procKill != ""
				procKill = user_input("Kill PID [DONE]: ", 0, 0)
				if procKill != "" then
					if result.close_program(procKill.to_int) then print("Killed...")
				end if
			end while
		end if
	end if
	//Network Enumeration
	enumPrompt = ""
	if enumPrompt != "a" then enumPrompt = user_input("Enumerate network status? [y/N/a] ", 0, 1).lower
	if enumPrompt == "y" or enumPrompt == "a" then
		print("Public IP:	" + result.public_ip)
		print("Local IP:	" + result.local_ip)
		print("Gateway IP:	" + result.network_gateway)
		print("Interfaces:	" + result.network_devices)
		ports = result.get_ports()
		if (ports.len() > 0) then
			print("Open ports:")
			for i in ports
				print(i.get_lan_ip() + ":" + i.port_number() + " " + i.is_closed())
			end for
		end if
	end if
	//Router Enumeration (Maybe? This is back and forth, seems like doesn't work as guest)
	if userLevel == "guest" then
		print("Skipping router enumeration due to user: guest")
	else if userLevel != "guest" then
		if enumPrompt != "a" then enumPrompt = user_input("Attempt to get router? [y/N/a]", 0, 1).lower
		if enumPrompt == "y" or enumPrompt == "a" then
			routerIP = result.network_gateway
			routerObject = get_router(routerIP)
			if not routerObject then 
				print("Could not get router")
			else if routerObject then
				print("Obtained router")
				print("Kernel v.	" + routerObject.kernel_version)
				print("Public IP:	" + routerObject.public_ip)
				print("Local IP:	" + routerObject.local_ip)
				print("ESSID:		" + routerObject.essid_name)
				print("BSSID:		" + routerObject.bssid_name)
				ports = routerObject.used_ports
				print("Port info: ")
				for i in ports
				    print(routerObject.port_info(i))
				end for
				print("Gateway for the following devices:")
				subHosts = routerObject.devices_lan_ip
				print("Hosts using this gateway: ")
				for i in subHosts
					print(i)
				end for
				rules = routerObject.firewall_rules
				print("Firewall rules:")
				for i in rules
					print(i)
				end for
			end if
		end if
	end if
	//File system enum and collect
	if enumPrompt != "a" then enumPrompt = user_input("Enumerate filesystem? [y/N/a]", 0, 1).lower()
	if enumPrompt == "y" or enumPrompt == "a" then
		//Attempt to get file handle to /
		fileSystemObj = result.File("/")
		//traverse directories down from there
		if fileSystemObj then recurseFolder(fileSystemObj)
		if not fileSystemObj then print("Could not obtain filesystem.")
		//Begin selecting for file get, uses get_content and not binary copy, so only works on text files
		srcFile = " "
		while srcFile != ""
			srcFile = user_input("Get file [DONE]: ", 0, 0)
			if srcFile != "" then dstName = user_input("Save as [SAME]: ", 0, 0)
			if srcFile != "" then print(fileContentCopy(result.File(srcFile), dstName))
		end while
	end if
	//Password harvesting
	if enumPrompt != "a" then enumPrompt = user_input("Enumerate credentials? [y/N/a]", 0, 1).lower()
	if enumPrompt == "y" or enumPrompt == "a" then
		fileSystemObj = result.File("/")
		credsList = getCreds(fileSystemObj)
		credFileName = result.local_ip + "_creds.txt"
		if get_shell.host_computer.touch(current_path, credFileName) then localFile = get_shell.host_computer.File(credFileName)
		//Check if can make local dest file
		//Get that made local File object, or return contents if can't
		if not localFile then print("Error getting local handle.  Dumping to term:" + char(20) + credsList)
		//Write contents to new local File obj
		localFile.set_content(credsList)									
		print("Creds saved as " + credFileName + "."	)
	end if
end function
//END Computer type

mailCheck = function(mailIndex=0)
	//Scrubs email for hints to type of mission and slices bolded
	//words to ID any possible IP's in target, retuns as list
	//0 should be passed to get the most recent message
	//Attempt login with creds, get obj
	mailFlags = []
	mailObj = mail_login(mailUser, mailPass)
	if typeof(mailObj) == "string" then exit("ERROR: " + mailObj)
	//fetch mail preview list
	mailPrev = mailObj.fetch()
	//slice most recent message to get mail ID
	mailID = slice(mailPrev[mailIndex], 10, 46)
	mailText = mailObj.read(mailID)
	//ID mission type and set to [0]
	if mailText.indexOf("client wants the login credentials") then
		mailFlags.push("credentials")
	else if mailText.indexOf("client wants the remote machine to stop working") then
		mailFlags.push("destroy")
	else
		mailFlags.push("unknown")
	end if
	//Scrub for IP's and pop em on
	//Sometimes usernames or files are bolded... this elimates them...
	while mailText.indexOf("<b>")
		startPos = mailText.indexOf("<b>")
		endPos = mailText.indexOf("</b>")
		//Strip "<b>" from start
		mailSlice = slice(mailText, startPos+3, endPos)
		//check for whitespace before
		while mailSlice[0:1] == " "
			mailSlice = mailSlice[1:]
		end while
		//check for whitespace after
		while mailSlice[-1:] == " "
			mailSlice = mailSlice[0:-1]
		end while
		//Make sure first char is a number, if so then add to mailFlags
		if slice(mailSlice, 0, 1).val > 0 then mailFlags.push(mailSlice)
		//Strip off any text before where we are now
		mailText = mailText[endPos+3:]
	end while
	return mailFlags
end function

///////////END POST EXPLOIT FUNCTIONS
///////////////////////////////////////





///////////////////////////////////////
////////////MAIN

//Check libraries and args
metaxploit = include_lib(current_path + "/metaxploit.so")
if not metaxploit then
	metaxploit = include_lib("/lib/metaxploit.so")
end if
if not metaxploit then
	print("Pulling copy of metaxploit.so...")
	getJumpFile("/lib/metaxploit.so")
	metaxploit = include_lib(current_path + "/metaxploit.so")
end if
if not metaxploit then exit("Error: Can't find metaxploit library in the /lib path or the current folder")
libName = params[0]
//if libName[:1] != "/" then libName = "/lib/" + libName
libVer = params[1]
remLoc = params[2]
memory = params[3]
value = params[4]
args = null
if params.len == 6 then
	args = params[5]
end if
//target library version check
lib = metaxploit.load(current_path + "/" + libName)
if not lib then
	libName = "/lib/" + libName
	lib = metaxploit.load(libName)
end if
if not lib then
	getJumpFile("/lib/" + libName)
	lib = metaxploit.load(current_path + "/" + libName)
end if
if not lib then exit("Cannot find " + params[0])
if lib.version != libVer then exit("Target library version mismatch, target has " + lib.version)
//Variable inits
headStr = "NULL"	//Formatted header string for log
credStr = "NULL"	//Formatted creds from getCreds & writeCreds
targetPub = ""		//Public IP of target
targetLan = ""		//Private IP of target


//Do the exploit, local or remote
if remLoc == "lnr" then 
	exit("Must select: (l)ocal, (n)et device, (r)emote")
else if remLoc == "l" then //for local machine exploits
	if not args then args = user_input("Args: ", 0)
	libKernel = metaxploit.load(libName)
else if remLoc == "r" then //for remote exploits, prompt for host, port, password(or optional input)
	rhost = user_input("Target IP: ", 0)
	rport = user_input("Target Port: ", 0)
	rpass = user_input("Password inject: ", 0)
	if rpass != "" then args = rpass
	print("Attempting session with '" + rhost + ":" + rport + "'")
	rport = rport.to_int()
	net_session = metaxploit.net_use(rhost, rport)
	if not net_session then exit("Unable to acquire remote session")
	libKernel = net_session.dump_lib
else if remLoc == "n" then //for network device exploits, routers and such.
	autoList = mailCheck() //Gets public and private IP of target from mail
	rhost = user_input("Target IP [" + autoList[1] + "]: ", 0, 0)
	if not args then args = user_input("Args [" + autoList[2] + "]: ", 0, 0)
	if rhost == "" then rhost = autoList[1]
	if args == "" then args = autoList[2]
	print("Attempting session with '" + rhost + "'" + char(10) + "###########################################")
	net_session = metaxploit.net_use(rhost)
	if not net_session then exit("Unable to acquire remote session")
	libKernel = net_session.dump_lib
end if
if not libKernel then exit("    Can't find " + libName)
//Exploit done... hopefully
//Check if args passed or not
if not args then result = libKernel.overflow(memory, value)
if args then result = libKernel.overflow(memory, value, args)
//Exploit probably worked if we're here.  Begin checking for type of result, and handle
print("###########################################")
print("Exploit returned object type: " + libKernel.lib_name() + ":" + typeof(result))






//SHELL
if typeof(result) == "shell" then 
	resultType_Shell(result)

//FILE
else if typeof(result) == "file" then
	resultType_File(result)

//COMPUTER
else if typeof(result) == "computer" then 
	resultType_Computer(result)

//NUMBER
else if typeof(result) == "number" then
//this usually means a "password change" type exploit was found
//Attempt it again with an argument passed as the desired password
	print("Exploit returned: " + result + char(10) + "This may be a password inject.  Try again with password argument")

//result was not a type we know how to handle if you get here.
end if
if not result then exit("Exploit maybe didn't succeed?")

