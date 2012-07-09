#!/usr/bin/ruby
#

class Fortune 
    @@NAME = "Fortune"
    def Fortune.name
        return @@NAME
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def shortDescription
        return "fortune - open a cookie"
    end

    def get_file_as_string(filename)
        data = ''
        f = File.open(filename, "r") 
        f.each_line do |line|
            data += line
        end
        f.close
        return data
    end

    def getFortune
        Kernel.system("wget", "-O", "temp.html", "-T", "150", "http://www.fortunecookiemessage.com/")
        pagetext = get_file_as_string("temp.html")
        #               <a href="cookie/7985-You-will-be-selected-for-a-promotion-because-of-your-accomplishments." style="font-size:18px; text-decoration:none;">You will be selected for a promotion because of your accomplishments.</a> </p>    <p align="center">
        #
        if (/<a href="cookie[^>]+>([^<]+)<\/a>/.match(pagetext))
            return $1
        end
        return "You are very lucky!"
    end

    def process(chatServer, user, text)
        str = getFortune
        if (!str.nil?)
            chatServer.sendMessage(user.handle, str)
        end
    end
end

ModuleController.loadModule(Fortune.name, Fortune)

