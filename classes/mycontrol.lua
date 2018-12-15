local M = {}

local scene  = nil
local myData = nil
local messagesDB = require("messagesDB")

function M.init(_scene, _myData)
    scene                 = _scene
    myData                = _myData
    myData.messageChoices = {}
    scene.hideTextField = M.hideTextField
    scene.showTextField = M.showTextField
    return M
end

function M.hideTextField()
    print("hiding text field")
    scene.messageEntryField.isVisible = false
    scene.messageEntryField.x = scene.messageEntryField.x + 200
end

-- function to show the text field.
function M.showTextField()
    print("showing text field")
    scene.messageEntryField.isVisible = true
    scene.messageEntryField.x = scene.messageEntryField.x - 200
end

function M.reloadData()
    scene.messagesTableView:deleteAllRows()
    local isCategory = false
    local rowHeight = 40
    local rowColor = { default={ 1, 1, 1 }, over={ 0.9, 0.9, 0.9 } }
    local lineColor = { 0.95, 0.95, 0.95 }
    for i = 1, #myData.messages do
        scene.messagesTableView:insertRow({
            isCategory = isCategory,
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor,
            params = {
                time = myData.messages[i].time,
                message = myData.messages[i].message,
                selected = myData.messages[i].selected,
                noDelete = myData.messages[i].noDelete,
                id = i
            },
        })
    end
end

-- Searching
function M.onSearchRowTouch( event )
    if event.row then
        if "tap" == event.phase or "release" == event.phase then
            local idx = event.row.id
            for i = 1, #myData.messages do
                myData.messages[i].selected = false
            end
            native.showAlert("message:", myData.messageChoices[idx].message, { "OK" } )
        end
    end
    native.setKeyboardFocus( nil )
    return true
end

function M.lookupMessage( text )
    table.remove( myData.messageChoices )
    myData.messageChoices = nil
    myData.messageChoices = {}
    print("Before Query" )
    local t = system.getTimer( )
    messagesDB.search(text, function(row)
        myData.messageChoices[ #myData.messageChoices + 1 ] = { time = row.time, message = row.message }
        print(row.id)
    end)
    print("After Query", system.getTimer() - t)
    if #myData.messageChoices <= 100 then
        scene.displayHits()
    end
end

local executeFunc = nil
-- handle the user input
function M.fieldHandler( textField )
    return function( event )
        print( event.phase, textField().text )
        if ( "began" == event.phase ) then
            -- This is the "keyboard has appeared" event
            -- Since we are just starting to type, indicate we haven't done a DB lookup yet.
            --hasFetchedLocationList = false
        elseif ( "ended" == event.phase ) then
            -- This event is called when the user stops editing a field: for example, when they touch a different field
        elseif ( "editing" == event.phase ) then
            -- don't query the database for one or two letters.
            if string.len( textField().text ) > 2 then
                executeFunc( textField().text, event.phase )
            else
                if scene.searchTableView then
                    scene.searchTableView:removeSelf()
                    scene.searchTableView = nil
                end
            end
        elseif ( "submitted" == event.phase ) then
            -- This event occurs when the user presses the "return" key (if available) on the onscreen keyboard
            -- There are two ways to select the location. Tapping the table row, or hitting the submit/enter key.
            -- This handles the enter key scenerio.
            print( textField().text )
            executeFunc( textField().text, event.phase )
            -- Hide keyboard
            native.setKeyboardFocus( nil )
        end
    end
end

-- Handle deleting a row button.
function M.deleteRow( event )
    if "ended" == event.phase then
        if myData.messages[ event.target.id ].selected then
            myData.messages[ 1 ].selected = true
        end
        table.remove( myData.messages, event.target.id )
        messagesDB.delete(myData.messages[ event.target.id ].id)
        M.reloadData()
    end
    return true
end

function M.onDeleteEvent( event )
    if "ended" == event.phase then
           for i = #myData.messages, 1, -1 do
              if myData.messages[i].selected then
                messagesDB.delete(myData.messages[i].id)
                table.remove( myData.messages, i )
              end
           end
        M.reloadData()
    end
    return true
end

function M.onSelectEvent( event )
    if "ended" == event.phase then
           for i = 1, #myData.messages do
              if  myData.messages[i].selected then
                  myData.messages[i].selected = false
              else
                  myData.messages[i].selected = true
              end
           end
        M.reloadData()
    end
    return true
end

local wasSwiped                 -- Flag to help separate touch events
-- function to handle the row touch events
function M.onMessageRowTouch( event )
    local row = event.row
    print(event.phase)
    if "tap" == event.phase then
       -- event.phase = "release"
    end
    if "press" == event.phase then
        wasSwiped = false
    elseif "swipeLeft" == event.phase and event.row.deleteButton and not event.row.deleteIsShowing then
        wasSwiped = true
        if row and event.row.deleteButton then
            transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x - 51 })
            event.row.deleteIsShowing = true
        end
    elseif "swipeRight" == event.phase and event.row.deleteButton and event.row.deleteIsShowing then
        wasSwiped = true
        if row and event.row.deleteButton then
            transition.to( event.row.deleteButton, { time=250, x = event.row.deleteButton.x + 51 })
            event.row.deleteIsShowing = false
        end
    elseif "release" == event.phase then
        if row then
            if not wasSwiped then
                if row.deleteButton and row.deleteIsShowing then
                    transition.to( row.deleteButton, { time=250, x = row.deleteButton.x + 51 })
                    row.deleteIsShowing = false
                end
                -- clear any other selected rows
               -- for i = 1, #myData.messages do
                   -- myData.messages[i].selected = false
               -- end
                -- select the current row
                if myData.messages[row.id].selected ~=true then
                    myData.messages[row.id].selected = true
                else
                    myData.messages[row.id].selected = false
                end
                M.reloadData()
                native.showAlert("message:", myData.messages[row.id].message, { "OK" } )
            end
        end
        -- we are done so clear the swipe flag
        wasSwiped = false
    end
    -- hide the keyboard
    native.setKeyboardFocus( nil )
end

function M.messageListener( event )
    -- stub out for now
end

function M.dismisKeyboard( event )
    if "ended" == event.phase then
        native.setKeyboardFocus( nil )
    end
    return true
end

function M.onSearchEvent(event)
    executeFunc = M.lookupMessage
    if "ended" == event.phase then
        if scene.messageEntryField.isVisible then
            scene.messagesTableView:translate(0, -scene.messageEntryField.height - 6)
            scene.messageEntryField.isVisible = false
            scene.searchTableView.isVisible = false
            scene.messagesTableView.isVisible = true
            M.reloadData()
        else
            scene.messagesTableView:translate(0, scene.messageEntryField.height + 6)
            scene.messageEntryField.isVisible = true
        end
    end
end

function M.onInsertEvent( event )
    executeFunc = M.insertMessage
    if "ended" == event.phase then
        if scene.messageEntryField.isVisible then
            scene.messagesTableView:translate(0, -scene.messageEntryField.height - 6)
            scene.messageEntryField.isVisible = false
            M.reloadData()
        else
            scene.messagesTableView:translate(0, scene.messageEntryField.height + 6)
            scene.messageEntryField.isVisible = true
        end
    end

    return true
end

function M.insertMessage(text, phase)
    if "submitted" == phase then
        local t = os.date()
        local id = messagesDB.insert(t, text)
        scene.messagesTableView:translate(0, -scene.messageEntryField.height - 6)
        scene.messageEntryField.isVisible = false
        table.insert( myData.messages, {id=id, time=t, message=text} )
        M.reloadData()
    end
end
--
return M