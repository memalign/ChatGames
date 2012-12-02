using terms from application "Messages"
	on received text invitation theMessage from theBuddy for theChat
		accept theChat
		set qMessage to quoted form of theMessage
		set qHandle to quoted form of (id of theBuddy as text)
		do shell script "echo \\<" & qHandle & "\\> " & qMessage & " >> /Users/chatgames/game/gamelog.txt"
		-- do shell script "echo hello >> /Users/chatgames/game/gamelog.txt"
	end received text invitation
end using terms from

