jumpIP = "1.2.3.4"
jumpPort = 22
jumpUser = "root"
jumpPass = "password"
jumpDir = "/root/"
jumpStr = "_creds.txt"
rtablePath = "/etc/rainbow.table"


////////////////////DEFINE FUNCTIONS

loadRainbowTable = function(tablePath)
	tableMap = {}
	//Loads rainbow table at tableFileName and returns as a map
	//print(tableFileName)
	//Check if file exists, otherwise create
	tableFile = get_shell.host_computer.File(tablePath)
	if not tableFile then
		//If tableFile doesn't exist, then touch a new one
		print("Table file not found, creating empty at " + tablePath)
		get_shell.launch("/bin/touch", tablePath)
		tableFile = get_shell.host_computer.File(tablePath)
		//Or ragequit if still unable to create file
		if not tableFile then exit("Unable to find or create rainbow table at " + tablePath)
	end if
	//Read in file to map in format of hash : plaintext
	rawTable = tableFile.get_content.split("\n")
	for line in rawTable
		if line.len > 2 then
			tableMap[line.split(":")[1]] = line.split(":")[0]
		end if
	end for
	return(tableMap)
end function

loadHashList = function(hashData)
	//Parses string credData into a map of new values for processing, returns list of hashes only
	hashList = []
	hashData = hashData.split("\n")
	for line in hashData
		//Split line on ":", push to hashList
		if line.len > 2 then hashList.push(line.split(":")[1])
	end for
	return(hashList)
end function

hashToPlain = function(tableMap, hash)
	if tableMap.hasIndex(hash) then 
		return tableMap[hash]
	else
		crypto = include_lib("/lib/crypto.so")
		if not crypto then exit("Error: Missing crypto library")
		return crypto.decipher(hash)
	end if
end function
	
printPlainText = function(tableMap, hashData)
	hashData = hashData.split("\n") //make list of lines
	for line in hashData
		//print user name from line, and mapping of hash
		//Sometimes blank lines get in here, filtering by length controls for this
		if line.len > 2 then print(line.split(":")[0] + " : " + tableMap[line.split(":")[1]])
	end for
end function

saveRainbowTable = function(tableMap, rtablePath)
	//Saves tableMap in format of hash : text again.
	//I hate this process and think it should be done differently
	//saveFile = get_shell.host_computer.File(rtablePath)
	saveFile = get_shell.host_computer.File(rtablePath)
	hashList = tableMap.indexes
	saveText = ""
	for hash in hashList
		saveText = saveText + tableMap[hash] + ":" + hash + char(10)
	end for
	saveFile.set_content(saveText)
end function
		
mailCheck = function(hashData, tableMap)
	hashList = hashData.split("\n")
	for line in hashList
		if line.indexOf("@") then
			accountName = line.split(":")[0]
			accountPass = tableMap[line.split(":")[1]]
			print(accountName)
			get_shell.launch("/bin/readmail", accountName + " " + accountPass)
		end if
	end for
end function


////////////////////////MAIN

//check startup

//If params == 1, then local file is specified, do that
if params.len == 1 then
	dataFile = get_shell.host_computer.File(current_path + "/" + params[0])
	if not dataFile then exit("Could not find local file.")
else if params.len == 0 then //No params, so pull from jump server
	hostShell = get_shell
	remoteShell = hostShell.connect_service (jumpIP, jumpPort, jumpUser, jumpPass)
	remoteComp = remoteShell.host_computer()
	remoteFolder = remoteComp.File(jumpDir)
	dataFile = null
	for file in remoteFolder.get_files()
		fileName = file.name()
		if fileName.indexOf(jumpStr) then
			dataFile = file
		end if
	end for
	if not dataFile then exit("Could not locate any valid remote file.")
else
	exit("Specify either local file, or default to jump server")
end if
hashData = dataFile.get_content		//Contents of new cred file



//Create map of existing rainbow table entries
tableMap = loadRainbowTable(rtablePath)
//Create list of hashes from new data
hashList = loadHashList(hashData)
//Check if new hash exists in map, or add if it doesn't
for hash in hashList
	tableMap[hash] = hashToPlain(tableMap, hash)
end for
//All hashes should exist in map now, print them to screen
printPlainText(tableMap, hashData)
//save rainbow table
saveRainbowTable(tableMap, rtablePath)
//Check of mail?
if hashData.indexOf("@") then
	opt = user_input("Read email [y/N]: ", 0, 1).lower
	if opt == "y" then mailCheck(hashData, tableMap)
end if
//Delete source file?
opt = user_input("Delete source file [y/N]: ", 0, 1).lower
if opt == "y" then dataFile.delete


