#!/usr/bin/ruby
#

require 'ChatService.rb'
require 'ModuleController.rb'

class ChatServer
    def initialize(filename)
        @filename = filename

        # Load up users, modules?
        @modController = ModuleController.new
    end
    
    def run
        # This creates a retain cycle but it's ok because ChatServer instances live forever
        @chatService = LogBasedChatService.new(self, @filename)
        @chatService.run
    end

    def messageReceived(handle, text)
        @modController.messageReceived(@chatService, handle, text)
    end
end

chatServer = ChatServer.new("text.txt")
chatServer.run
