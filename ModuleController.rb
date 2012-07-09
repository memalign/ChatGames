#!/usr/bin/ruby
#

require 'ChatLogger.rb'
require 'User.rb'
require 'FileUtils'

class ModuleController
    @@USERSFILE = "./users.txt"
    @@LOADEDMODULES = {}

    def ModuleController.loadModules
        dir = "./modules/"
        Dir.foreach(dir) { |file|
            if (file =~ /\.rb$/)
                ChatLogger.puts "[loadModules] Including #{dir + file}"
                load dir + file
            end
        }
    end

    def ModuleController.loadModule(moduleName, modClass)
        @@LOADEDMODULES[moduleName] = modClass
    end

    def ModuleController.setMainModuleName(mainModName)
        @@MAINMODULENAME = mainModName
    end

    def initialize
        @modules = {}
        loadModules

        @users = {}
        loadUsers
    end

    def loadUsers
        FileUtils.touch(@@USERSFILE)
        IO.foreach(@@USERSFILE) { |line|
            # The user's handle is at the beginning of each line
            match = /^\<([^\>]+)\>(\S+) (.+)/.match(line)
            handle = match[1]
            moduleName = match[2]
            modStr = match[3]
            if (!handle.nil?)
                user = @users[handle]
                if (user.nil?)
                    user = User.new(handle)
                    @users[handle] = user
                end

                if (!moduleName.nil?)
                    mod = @modules[moduleName]
                    user.addState(moduleName, mod.parseState(modStr))
                end
            end
        }
    end

    def saveUsers
        File.open(@@USERSFILE, 'w') { |f|
            @users.each { |handle,user|
                user.state.each { |modName, state|
                    modStr = @modules[modName].serialize(state)
                    f.write("<#{handle}>#{modName} #{modStr}\n")
                }
            }
        }
    end

    def loadModules
        ModuleController.loadModules
        @@LOADEDMODULES.each { |modName, modClass|
            @modules[modName] = modClass.new
        }
    end

    def messageReceived(chatServer, handle, text)
        # Find the appropriate module
        user = @users[handle]
        if (user.nil?)
            user = User.new(handle)
            @users[handle] = user
        end
        
        currentModule = user.currentModule
        if (currentModule.nil?)
            currentModule = @@MAINMODULENAME
        end

        @modules[currentModule].process(chatServer, user, text)
    end
end
