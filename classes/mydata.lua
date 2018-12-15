local myData = {}
local messagesDB = require("classes.messagesDB")

myData.platform = "iOS"
if "simulator" == system.getInfo("environment") and "iP" ~= string.sub( system.getInfo("model"), 1, 2 ) then
    myData.platform = "Android"
elseif "device" == system.getInfo("environment") and "Android" == system.getInfo("platformName" ) then
    myData.platform = "Android"
end

myData.init= function()
    messagesDB.open()
    myData.messages = {}
    messagesDB.nrows(function(row)
        row.selected = false
        row.noDelete = false
        table.insert(myData.messages, row)
        end)
end

myData.close = function()
   messagesDB.close()
end

return myData
