#!/usr/bin/ruby
#

class Dice 
    @@NAME = "Dice"
    def Dice.name
        return @@NAME
    end

    def parseState(line)
        return line
    end

    def serialize(state)
        return state
    end

    def shortDescription
        return "dice [NdS] - roll 🎲"
    end

    def process(chatServer, user, text)
        diceString = text.split(' ', 2)[1]
        
        matches = /^(\d+)d(\d+)/i.match(diceString)
        amtDice = 1
        numSides = 6
        if (matches)
            inputAmtDice = matches[1].to_i
            if ((inputAmtDice >= 1) && (inputAmtDice <= 999))
                amtDice = inputAmtDice
            end

            inputNumSides = matches[2].to_i
            if ((inputNumSides >= 1) && (inputNumSides <= 999))
                numSides = inputNumSides
            end
        end

        message = "Rolled #{amtDice}d#{numSides}: "
        sum = 0
        comma = ""
        sumString = ""
        1.upto(amtDice) { |x|
            value = 1 + rand(numSides)
            sumString << "#{comma}#{value}"
            sum += value
            comma = "+"
        }

        if (amtDice > 1)
            message << "#{sumString}=#{sum}"
        else
            message << "#{sum}"
        end

        chatServer.sendMessage(user.handle, message)
    end
end

ModuleController.loadModule(Dice.name, Dice)

