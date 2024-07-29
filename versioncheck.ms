//If no args passed, parse /lib.  Otherwise, parse param[1]
if params.len > 1 then exit("Default action checks /lib recursively, otherwise " + char(10) + "libver [/path/to/lib]")
//load metalib
metaxploit = include_lib("/lib/metaxploit.so")
if not metaxploit then
    metaxploit = include_lib(current_path + "/metaxploit.so")
end if
if not metaxploit then exit("Error: Can't find metaxploit library in the /lib path or the current folder")
//begin checks of target folder
tlName = "/lib"
if params.len == 1 then tlName = params[0]
tlFile = get_shell.host_computer.File(tlName)
if not tlFile then exit("Unable to get File object at " + tlName)
if not tlFile.is_folder then exit("Arguement must be folder.")
globals.product = ""
//////Checks Done

/////Define functions/
recurseFolder = function(folder, metaxploit)
	subFiles = folder.get_files()
	subFolders = folder.get_folders()
	for i in subFiles
		lib = metaxploit.load(i.path)
		if lib then globals.product = (globals.product + i.path() + " " + lib.version + char(10))
	end for
	for i in subFolders
		recurseFolder(i, metaxploit)
	end for
end function

////////FUNCTIONS DONE

/////Start program
recurseFolder(tlFile, metaxploit)
globals.product = format_columns(globals.product)
print(globals.product)



