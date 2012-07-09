#!/usr/bin/ruby
#

class Ping
    @@NAME = "Ping"
    def Ping.name
        return @@NAME
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def shortDescription
        return "ping [string] - ask for pong"
    end

    def process(chatServer, user, text)
        response = "pong"
        pingString = text.split(' ', 2)[1]
        if (!pingString.nil?)
            response = "#{response} #{pingString}"
        end

        chatServer.sendMessage(user.handle, response)
    end
end

ModuleController.loadModule(Ping.name, Ping)

