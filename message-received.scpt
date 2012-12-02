using terms from application "Messages"
	on message received theMessage from theBuddy for theChat
		set qMessage to quoted form of theMessage
		set qHandle to quoted form of (id of theBuddy as text)
		do shell script "echo \\<" & qHandle & "\\> " & qMessage & " >> /Users/chatgames/game/gamelog.txt"
		-- do shell script "echo hello >> /Users/chatgames/game/gamelog.txt"
	end message received
end using terms from

