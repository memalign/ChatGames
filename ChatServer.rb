#!/usr/bin/ruby
#

require 'ChatService.rb'

class ChatServer
    def initialize(filename)
        @filename = filename
    end
    
    def run
        # This creates a retain cycle but it's ok because ChatServer instances live forever
        @chatService = LogBasedChatService.new(self, @filename)
        @chatService.run
    end

    def messageReceived(handle, text)
        @chatService.sendMessage(handle, "Got your message!")
    end
end

chatServer = ChatServer.new("text.txt")
chatServer.run
