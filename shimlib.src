chomp = function(string)
//Strips whateChars from start and end of any string passed, returns string.
	if string.len < 1 then return string
	whiteChars = [char(0), char(3), char(9), char(10), char(11), char(13), char(32), " "]
	//print(string.len)
	while whiteChars.indexOf(string[0]) != null
		string = string[1:]
	end while
	while whiteChars.indexOf(string[-1]) != null
		string = string[:-1]
	end while
	return string
end function

listToMap = function(rawList, demarc = " ")
//returns a map object of the provided list
//each item in the list is split by the demarc
	retMap = {}
	for item in rawList
		retMap[item.split(demarc)[0]] = item.split(demarc)[1]
		print(item.split(demarc)[0] + " : " + item.split(demarc)[1])
	end for
	return retMap
end function

markupGetList = function(markupPath, markupBody)
//returns any fields nested under mlPath within mlBody as a list
	if typeof(markupPath) == "string" then markupPath = markupPath.split("\n")
	act = false
	step = 0
	markupSelect = []
	for rawLine in markupBody
		line = chomp(rawLine).lower
		if line == "[/"+markupPath[step].lower+"]" then act = false
		if act == true then markupSelect.push(line)
		if line == "["+markupPath[step].lower+"]" then 
			step = step+1
			if step == markupPath.len then
				step = step-1
				act = true
			end if
		end if
	end for
	return markupSelect
end function

markupGetString = function(mlPath, mlBody)
//returns any fields nested under mlPath within mlBody as a string
	mlLines = mlBody.split("\n")
	act = false
	step = 0
	markupSelect = ""
	for rawLine in mlLines
		line = chomp(rawLine).lower
		if line == "[/"+mlPath[step].lower+"]" then act = false
		if act == true then markupSelect = markupSelect + line +"\n"
		if line == "["+mlPath[step].lower+"]" then 
			step = step+1
			if step == mlPath.len then
				step = step-1
				act = true
			end if
		end if
	end for
	return markupSelect
end function

markupAdd = function(addText, addPath, markupBody)
//addText = string to add to markupBody
//addPath = list of of nested marks for where to add addText
//markupBody = list of markup content to get added to
	act = false
	pathEnd = false
	step = 0
	markupReturn = []
	for line in markupBody
		cleanLine = chomp(line).lower
		//print("ADD TIME:")
		//print(cleanLine)
		//count steps into desired path
		if not pathEnd and cleanLine == "[" + addPath[step].lower + "]" then step = step + 1
		//check if we just hit the end of addPath, take one out of step to prevent out of range
		if step == addPath.len then pathEnd = true
		//count steps out of desire path
		//(If we hit a step out before the end, then our path doesn't exist and needs to be made)
		if not pathEnd and cleanLine == "[/" + addPath[step-1].lower + "]" then act = true
		//if we hit step out after path end, then we're at the insert location
		if pathEnd and cleanLine == "[/" + addPath[step-1].lower + "]" then act = true
		//if we hit all steps, add the text
		if act and pathEnd then
			markupReturn.push(addText)
			act = false
		end if
		//if we didn't hit all the steps, but are closing, then we need to add the fields and text
		if act and not pathEnd then
			//add new path fields
			for i in range(step, addPath.len-1)
				markupReturn.push("[" + addPath[i] + "]")
			end for
			//add addText
			markupReturn.push(addText)
			//back out new path fields
			for i in range(addPath.len-1, step)
				markupReturn.push("[/" + addPath[i] + "]")
			end for
			act = false
		end if
		markupReturn.push(line)
	end for
	return(markupReturn)
end function


markupFormat = function(markupBody)
//markupBody = list of markup text to be formatted
//Good to do before a write for easy ready
//Returns a string, which can be split again if needed
	markupNewBody = []
	step = 0
	for line in markupBody
		if line.len < 1 then 
			markupNewBody.push(char(10))
		else if line[0] == "[" and line[0:2] != "[/" and line[-1] == "]" then 
			markupNewBody.push(char(9)*step + chomp(line))
			step = step + 1
		else if line[0:2] == "[/" and line[-1] == "]" then
			step = step - 1
			markupNewBody.push(char(9)*step + chomp(line))
		else
			markupNewBody.push(char(9)*step + chomp(line))
		end if
	end for
	return(markupNewBody.join(char(10)))
end function

fileRead = function(fileName, create=false)
//attempt to read from the absolute or relative path fileName
//returns file context as text blob
	//check if fileName was passed as an absolute path
	if fileName[0] == "/" then
		filePath = parent_path(fileName)
		fileName = fileName.split("/")[-1]
	else
		filePath = current_path
	end if
	//pad path name with a trailing /
	if filePath[-1] != "/" then filePath = filePath + "/"
	//check exists and permissions for folder and file
	folderObj = get_shell.host_computer.File(filePath)
	if not folderObj then return("ERROR: Folder " + filePath + " does not exist")
	if not folderObj.has_permission("r") then return("ERROR: Read permission denied on " + filePath)
	fileObj = get_shell.host_computer.File(filePath+fileName)
	//if no file, then attempt to create if told to
	if not fileObj and create then get_shell.host_computer.touch(filePath, fileName)
	fileObj = get_shell.host_computer.File(filePath+fileName)
	if not fileObj and create then return("ERROR: Could not locate or create " + fileName)
	fileObj = get_shell.host_computer.File(filePath+fileName)
	if not fileObj then return("ERROR: Could not locate " + filePath+fileName)
	if not fileObj.has_permission("r") then return("ERROR: Read permission denied on " + filePath+fileName)
	return fileObj.get_content
end function

fileWrite = function(fileContent, fileName, filePath = "")
//Write file to filename, whether passed as absolute or relative file
	//do some checks, use current dir if none specified
	if filePath == "" then filePath = current_path
	//if absolute path was passed as fileName, parse that
	if fileName[0] == "/" then
		filePath = parent_path(fileName)
		fileName = fileName.split("/")[-1]
	end if
	//pad path with a trailing /
	if filePath[-1] != "/" then filePath = filePath + "/"
	//check if path exists and permissions allow for write
	folderObj = get_shell.host_computer.File(filePath)
	if not folderObj then return ("ERROR: Folder " + filePath + " does not exist")
	if not folderObj.has_permission("w") then return("ERROR: Write permission denied on " + filePath)
	fileObj = get_shell.host_computer.File(fileName)
	//check if file doesn't exist, attempt to create it if needed
	if not fileObj then
		get_shell.host_computer.touch(filePath, fileName)
		fileObj = get_shell.host_computer.File(fileName)
	end if
	if not fileObj.has_permission("w") then return("ERROR: Write permission denied on " + filePath + fileName)
	if not fileObj then return ("ERROR: Could not create " + filePath + fileName)
	fileObj.set_content(fileContent)
	return("SUCCESSFUL write on " + filePath+fileName)
end function

//word = "     hi steve       "
//word = chomp(word)
//print("'" + word + "'")

//shimSect = ["EXPLOIT", "kernel_router.so", "1.0.1"]
//shimport(shimSect)

//shimSect = ["variable"]
//shimport(shimSect)

//mlPath = ["EXPLOIT", "kernel_router.so", "1.0.1"]
//markupBody = fileRead("shim.lib")

//markupList = markupGetList(mlPath, markupBody)
//print(typeof(markupList))
//print(markupList)


//markupAdd = function(addList, mlPath, mlBody, format=false)
//addList = ["new stuff", "newer stuff"]
//markupList = markupAdd(addList, mlPath, markupBody.split("\n"))

//print(markupList)


//print(fileWrite("words \n new words", "deleteme.txt", "/root"))
//print(fileRead("/etc/passwd"))
//print(fileRead("deleteme.txt"))
//print(fileRead("/root/words.txt"))
//print(fileRead("/etc/rainbow.table"))
//print(fileRead("/etc/rainbow.table.2", true))



words = "words one " + char(10) +"words two"+char(10)+"words three"
list = words.split("\n")
print(list[1])
print(str(list))










markupPath = ["EXPLOIT", "kernel_router.so", "1.0.1"]
markupText = fileRead("shim.lib")


print("MARKUP TEXT")
print(markupText)


print("SPLIT TEXT")
splitText = markupText.split("\n")
for line in splitText
	print(line)
end for

addedText = markupAdd("thisn thatn", markupPath, splitText)
print("ADDED TEXT")
for line in addedText
	print(line)
end for

totallynewPath = ["VARIABLE", "supersecret"]
addedText = markupAdd("ilove you", totallynewPath, addedText)



formatText = markupFormat(addedText)
print("FORMATTED TEXT")
print(formatText)


print("WRITING")
print(fileWrite(formatText, "shim.lib.2"))


//tlist = ["jumpIP 1111111", "jumpUser root"]
//varMap = listToMap(tlist)
//print(typeof(varMap))
//print(varMap["jumpIP"])

//shimList = sFile.get_content.split("\n")
//print(typeof(sList))
//print(sList)
//m = sList.split(" ")
//print(m)
