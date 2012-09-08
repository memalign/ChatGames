#!/usr/bin/ruby
#

require File.join(File.dirname(__FILE__), 'BillsLibrary/CashGraph/CGUser')
require File.join(File.dirname(__FILE__), 'BillsLibrary/CashGraph/CGBill')
require File.join(File.dirname(__FILE__), 'BillsLibrary/CashGraph/CGPersistedHistory')
require File.join(File.dirname(__FILE__), 'BillsLibrary/CashGraph/CGOweChart')
require File.join(File.dirname(__FILE__), 'BillsLibrary/CashGraph/CGUserGroup')

class Bills 
    @@NAME = "Bills"

    @@BILL_DATABASE_FILE = File.join(File.dirname(__FILE__), 'BillsLibrary/billdb.out')
    def Bills.name
        return @@NAME
    end

    def initialize
        # Load up the bill history
        loadBillHistory

        @sortedCommands = Array.new
        @commands = Hash.new

        cmd = "help"
        @sortedCommands << cmd
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            chatServer.sendMessage(user.handle, helpString)
        }, "#{cmd} - this text"]

        cmd = "home"
        @sortedCommands << cmd
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            user.currentModule = nil
            @pendingBills[user.handle] = nil
            chatServer.sendMessage(user.handle, "You have left bills mode.")
        }, "#{cmd} - Leave bills mode"]

        cmd = "owe"
        @sortedCommands << cmd
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            processOweChart(chatServer, user)
        }, "#{cmd} - See who owes you"]

        cmd = "bill"
        @sortedCommands << cmd
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            processBill(chatServer, user, text)
        }, "#{cmd} user amount comment - ex: \"#{cmd} Henry $1.00 Being a tool\""]

        cmd = "yes"
        # @sortedCommands << cmd # This command is silent
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            confirmBill(chatServer, user, text)
        }, ""]

        cmd = "no"
        # @sortedCommands << cmd # This command is silent
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            cancelBill(chatServer, user, text)
        }, ""]

        cmd = "split"
        @sortedCommands << cmd
        @commands[cmd] = [Proc.new { |chatServer, user, text|
            splitBill(chatServer, user, text)
        }, "#{cmd} user1[, user2] amount comment - ex: \"#{cmd} Henry, Walter $33.00 dinner for 3\""]


        @pendingBills = Hash.new

    end

    def loadBillHistory
        @billHistory = CGHistory.load_from_file(@@BILL_DATABASE_FILE)
    end

    def saveBillHistory
        @billHistory.writeToFile(@@BILL_DATABASE_FILE)
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def helpString
        string = "Commands:\n"
        @sortedCommands.each { |name|
            string << "> #{@commands[name][1]}\n"
        }
        string
    end

    def shortDescription
        "bills - manage cashgraph"
    end

    def confirmBill(chatServer, user, text)
        bill = @pendingBills[user.handle]
        if (bill.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Sorry, I don't understand that.")
            return
        end

        @billHistory.addBill(bill)
        @pendingBills[user.handle] = nil
        saveBillHistory
        chatServer.sendMessage(user.handle, "Bill added.")

        # Alert others involved
        cgUser = findCGUserForUser(user)
        bill.participantPayTriples.each { |triple|
            if (triple.user != cgUser)
                chatServer.sendMessage(triple.user.email, "#{cgUser.name} has added a bill for \"#{bill.comment}\" where you owe #{triple.amountOwe.moneyString}")
            end
        }
    end

    def cancelBill(chatServer, user, text)
        bill = @pendingBills[user.handle]
        if (bill.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Sorry, I don't understand that.")
            return
        end

        @pendingBills[user.handle] = nil
        chatServer.sendMessage(user.handle, "Bill cancelled.")
    end

    def splitBill(chatServer, user, text)
        cgUser = findCGUserForUser(user)
        if (cgUser.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Couldn't find your user :(")
            return
        end

        # Parse the text
        matches = /^split ([^\$\d]+?) \$?(\d+(?:\.\d{2})?)\s*?(?: (.+))?$/i.match(text)
        if (matches.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Sorry, I don't understand that.")
            return
        end

        otherNames = matches[1].split(/[, ]+/)
        otherCGUsers = []
        otherNames.each { |n|
            tempUsers = @billHistory.findUsersWithPrefixOrEmail(n, nil)
            if (tempUsers.nil? || (tempUsers.count == 0))
                chatServer.sendMessage(user.handle, "[#{@@NAME}] Sorry, I didn't find a user matching #{n}.")
                return
            end
            otherCGUsers << tempUsers[0]
        }

        if (otherCGUsers.include?(cgUser))
            chatServer.sendMessage(user.handle, "You can't bill yourself.")
            return
        end

        moneyString = matches[2]
        comment = "#{matches[3]}"
        amount = BigDecimal.new(moneyString)

        otherCGUsers << cgUser
        bill = CGBill.newEvenlySplitBill(comment, otherCGUsers, cgUser, amount)

        message = "Split \"#{comment}\":"
        bill.participantPayTriples.each { |triple|
            if (triple.user != cgUser)
                message << "\n #{triple.user.name} (#{triple.user.email}) owes #{triple.amountOwe.moneyString}"
            end
        }
        message << "\nAdd bill?"
        chatServer.sendMessage(user.handle, message)

        @pendingBills[user.handle] = bill
    end


    def processBill(chatServer, user, text)
        cgUser = findCGUserForUser(user)
        if (cgUser.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Couldn't find your user :(")
            return
        end

        # Parse the text
        matches = /^bill (\S+) \$?(\d+(?:\.\d{2})?)\s*?(?: (.+))?$/i.match(text)
        if (matches.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Sorry, I don't understand that.")
            return
        end

        otherName = matches[1]
        moneyString = matches[2]
        comment = "#{matches[3]}"

        # Try to find cguser with otherName
        otherCGUsers = @billHistory.findUsersWithPrefixOrEmail(otherName, nil)
        if (otherCGUsers.nil? || (otherCGUsers.count == 0))
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Sorry, I didn't find a user matching #{otherName}.")
            return
        end
        otherCGUser = otherCGUsers[0]

        if (otherCGUser == cgUser)
            chatServer.sendMessage(user.handle, "You can't bill yourself.")
            return
        end

        amount = BigDecimal.new(moneyString)
        chatServer.sendMessage(user.handle, "Bill #{otherCGUser.name} (#{otherCGUser.email}) #{amount.moneyString} for \"#{comment}\"?")

        triples = []
        triples << CGParticipantPayTriple.new(cgUser, amount, "0")
        triples << CGParticipantPayTriple.new(otherCGUser, "0", amount)
        bill = CGBill.new(comment, Time.now, triples)

        @pendingBills[user.handle] = bill
    end

    def processOweChart(chatServer, user)
        cgUser = findCGUserForUser(user)
        if (cgUser.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Couldn't find your user :(")
            return
        end

        oweChart = @billHistory.oweChartForUser(cgUser)
        if (oweChart.nil?)
            chatServer.sendMessage(user.handle, "[#{@@NAME}] Couldn't find your owe chart :(")
            return
        end

        message = ""
        comma = ""
        oweChart.each { |otherCGUser,oweAmount|
            if (oweAmount > 0) # otherCGUser owes cgUser
                message << "#{comma}#{otherCGUser.name} owes you #{oweAmount.moneyString}"
            else
                message << "#{comma}You owe #{otherCGUser.name} #{(-oweAmount).moneyString}"
            end
            comma = "\n"
        }
        chatServer.sendMessage(user.handle, message)
    end

    def findCGUserForUser(user)
        address = user.handle.split(":", 2)[1]
        users = @billHistory.findUsersWithPrefixOrEmail(nil, address)
        if (users.nil? || (users.count == 0))
            return nil
        end
        return users[0]
    end

    def process(chatServer, user, text)
        state = user.state[@@NAME]
        
        if (user.currentModule == @@NAME.downcase)
            firstWord = text.split(' ', 2)[0]
            if (!firstWord.nil?)
                cmd = @commands[firstWord.downcase]
                if (!cmd.nil?)
                    cmd[0].call(chatServer, user, text)
                    return
                end
            end

            chatServer.sendMessage(user.handle, "[#{@@NAME}] I don't recognize that command, try \"help\"")
            return
        end


        # See if the user is in any groups
        # if so, put them into bills mode

        # user.handle is of the format GUID:phonenumber
        address = user.handle.split(":", 2)[1]
        users = @billHistory.findUsersWithPrefixOrEmail(nil, address)
        if (users.nil? || (users.count == 0))
            chatServer.sendMessage(user.handle, "[#{@@NAME}] You don't have access to this service :(")
            return
        end

        groups = @billHistory.findUserGroupsContainingUser(users[0])
        if (groups.nil? || (groups.count == 0))
            chatServer.sendMessage(user.handle, "[#{@@NAME}] You don't have access to this service :(")
            return
        end

        user.currentModule = @@NAME.downcase
        message = "Now in bills mode.\n#{helpString}"
        
        chatServer.sendMessage(user.handle, message) 
    end
end

ModuleController.loadModule(Bills.name, Bills)
