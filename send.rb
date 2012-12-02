#!/usr/local/bin/macruby
#

framework 'ScriptingBridge'

msgapp = SBApplication.applicationWithBundleIdentifier('com.apple.iChat')
buddy = nil
buddies = msgapp.buddies
identifier = ARGV[0] # Either GUID:address or address
buddies.each { |b|
    buddyIdentifier = b.id.split(":", 2)[1]
    if ((b.id == identifier) || (buddyIdentifier == identifier))
        buddy = b
        break
    end
}

exit if buddy.nil?

msg = ARGV[1]
msgapp.send msg, :to => buddy

