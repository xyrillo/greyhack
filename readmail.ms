//readmail [username] [password]
//Prints all messages in users mailbox
//Scriptable and useful for bulk enumeration of harvested credentials
//
//MailObj is prone to bugs on game updates and changes to mail headers
//will break parsing on the msgID slice.


mailObj = mail_login(params[0], params[1])
if typeof(mailObj) == "string" then exit("ERROR: " + mailObj)
mailPrev = mailObj.fetch()
for msg in mailPrev
	if msg.indexOf("MailID") then 
		msgID = slice(msg, 10, 46) //I hope this slice is consistent
		print(mailObj.read(msgID))
		//This makes mailIndex a list of just strings for mail ID's						
		
	end if
end for
