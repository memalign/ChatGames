#!/usr/bin/ruby
#

class Main
    def initialize
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def process(chatServer, user, text)
        chatServer.sendMessage(user.handle, "Hello! I got \"#{text}\"")
    end
end

ModuleController.loadModule("Main", Main)
ModuleController.setMainModuleName("Main")
