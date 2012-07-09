#!/usr/bin/ruby
#

class Jack 
    @@NAME = "Jack"
    def Jack.name
        return @@NAME
    end

    def initialize
        File.open("modules/jack.txt", 'r') { |f| 
            @quotes = f.readlines
        }
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def shortDescription
        return "jack - deep thought"
    end

    def process(chatServer, user, text)
        str = "#{@quotes[rand(@quotes.length)].chomp}"
        chatServer.sendMessage(user.handle, str)
    end
end

ModuleController.loadModule(Jack.name, Jack)

