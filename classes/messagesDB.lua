local M = {}

require "sqlite3"
print( "version " .. sqlite3.version() )

--Open messages.db.  If the file doesn't exist it will be created
local path = system.pathForFile("messages.db", system.DocumentsDirectory)
local db = nil

--Handle the applicationExit event to close the db
local function onSystemEvent( event )
        if( event.type == "applicationExit" ) then
            db:close()
        end
end

M.open = function()
    db = sqlite3.open( path )
    local tablesetup = [[CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY, time, message);]]
    print(tablesetup)
    db:exec( tablesetup )
    return db
end

M.close = function()
    db:close()
end

--Setup the table if it doesn't exist

M.insert = function(time, msg)
    local tablefill =[[INSERT INTO messages VALUES (NULL, ']]..time..[[',']]..msg..[['); ]]
    db:exec( tablefill )
end

M.delete = function(id)
    local tablefill =[[DELETE FROM messages WHERE id= ]]..id..[[; ]]
    db:exec( tablefill )
end

M.update = function(id, time, msg)
    local tablefill =[[UPDATE messages SET time='']]..time..[[' message=']]..msg..[[', WHERE id= ]]..id..[[; ]]
    db:exec( tablefill )
end

M.nrows = function(callback)
   if callback then
    for row in db:nrows("SELECT * FROM messages") do
        local text = row.time.." "..row.message
        print(row.id, text)
        callback(row)
    end
   else
       return db:nrows("SELECT * FROM messages")
   end
end

M.search = function(value, callback)
    for row in db:nrows("SELECT * FROM messages WHERE LOWER(message) LIKE '" .. value .. "%' ORDER BY time") do
        callback(row)
    end
end

--setup the system listener to catch applicationExit
Runtime:addEventListener( "system", onSystemEvent )

return M