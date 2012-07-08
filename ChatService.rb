#!/usr/bin/ruby
#

class ChatService
    # delegate should implement messageReceived(handle, text)
    def initialize(delegate)
        @delegate = delegate
    end

    def messageReceived(handle, text)
        @delegate.messageReceived(handle, text)
    end

    def sendMessage(handle, text)
        puts "sendMessage should be overridden by a subclass of ChatService"
    end

    def run
        puts "run should be overridden by a subclass of ChatService"
    end
end

class LogBasedChatService < ChatService
    def initialize(delegate, filename)
        super(delegate)
        @filename = filename
    end

    # line is of the format:
    # <handle> text
    def parseLine(line)
        handle = nil
        text = nil
        match = /^\<([^\>]+)\> (.*)$/.match(line)
        if (match)
            handle = match[1]
            text = match[2]
        end
        return handle, text
    end
    
    def startIOThread
        @io = IO.popen("tail -n 0 -F #{@filename}", "r")
        while (!@io.closed?)
            line = @io.gets
            if (!line.nil?)
                handle, text = parseLine(line)
                if (!handle.nil? && !text.nil?)
                    messageReceived(handle, text)
                end
            end
        end
    end

    def run
        startIOThread
    end

    alias :super_messageReceived :messageReceived
    def messageReceived(handle, text)
        puts "<< <#{handle}> #{text}"
        super_messageReceived(handle, text)
    end

    def sendMessage(handle, text)
        puts ">> <#{handle}> #{text}"
    end
end
