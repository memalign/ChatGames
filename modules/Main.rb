#!/usr/bin/ruby
#

class Main
    @@NAME = "Main"
    def Main.name
        return @@NAME
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def setModules(modules)
        @modules = modules
        @sortedModuleNames = @modules.keys.sort
    end

    def helpString
        string = "Commands:\n"
        string << "👉help (?) - this text\n"
        @sortedModuleNames.each { |name|
            if (name != @@NAME.downcase)
                string << "👉#{@modules[name].shortDescription}\n"
            end
        }
        string
    end

    def process(chatServer, user, text)
        state = user.state[@@NAME]
        
        if (state.nil?)
            user.state[@@NAME] = "notnew"
            chatServer.sendMessage(user.handle, "Hello, I am a chat bot! You can learn more about my capabilities by saying \"help\"")
            return
        end

        # Check for any other command
        firstWord = text.split(' ', 2)[0]
        if (!firstWord.nil?)
            mod = @modules[firstWord.downcase]
            if (!mod.nil?)
                mod.process(chatServer, user, text)
                return
            end
        end

        wantsHelp = (text =~ /help/i)
        wantsHelp = wantsHelp || (text =~ /\?/)
        if (wantsHelp)
            chatServer.sendMessage(user.handle, helpString)
            return
        end

        chatServer.sendMessage(user.handle, "😰 Sorry, I don't recognize that command")
    end
end

ModuleController.loadModule(Main.name, Main)
ModuleController.setMainModuleName(Main.name)
