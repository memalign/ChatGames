#!/usr/bin/ruby
#

class User
    attr_reader :state, :handle, :currentModule
    attr_writer :currentModule

    def initialize(handle)
        @handle = handle
        @state = {}
    end

    def addState(moduleName, state)
        @state[moduleName] = state
    end
end
