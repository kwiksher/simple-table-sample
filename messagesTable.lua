local composer = require( "composer" )
local scene    = composer.newScene()
local widget   = require( "widget" )
-- Our modules
local myData = require("classes.mydata")
local myCtrl = require("classes.mycontrol").init(scene, myData)
local theme  = require( "classes.theme" )    -- Theme module
local UI     = require( "classes.ui" )       -- The TabBar and NavBar code. It sits above all composer scenes.
--------------------------------------------------
-- Forward declarations
local messageEntryField = nil-- holds the entry string
local searchTableView   = nil-- The tableView to hold our dynamic search results
local messagesTableView = nil-- The tableView to display the user's selected locations
local sceneBackground   = nil -- needs accessed in multiple functions for themimg reasons
--
local rightButton, rightButton2, rightButton3, rightButton4
-----constant for positioning
local SearchMsgY               = 72
local messageTableMarginBottom = 100
--
local function onSearchRowRender( event )
    local row = event.row
    local params = event.row.params
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth
    local rowTitle = display.newText( row, params.time.." "..params.message, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( theme.textColor ) )
    rowTitle.anchorX = 0
end
--
function scene.displayHits( )
    if searchTableView then
        searchTableView:removeSelf()
        searchTableView = nil
    end
    messagesTableView.isVisible = false
    searchTableView = widget.newTableView({
        left = 20,
        top = messageEntryField.y + 15,
        height = display.actualContentHeight - messageEntryField.y - 65,
        width = display.actualContentWidth - 40,
        onRowRender = onSearchRowRender,
        onRowTouch = myCtrl.onSearchRowTouch,
    })
    --
    scene.searchTableView = searchTableView
    --
    local isCategory = false
    local rowHeight = 40
    local rowColor = { default=theme.rowBackgroundColor, over=theme.rowBackgroundColor }
    local lineColor = { 0.5, 0.5, 0.5 }
    print("Before inserting rows into tableView")
    local t = system.getTimer()
    for i = 1, #myData.messageChoices do
        print( myData.messageChoices[i].name)
        searchTableView:insertRow({
            isCategory = isCategory,
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor,
            params = {
                time = myData.messageChoices[i].time,
                message = myData.messageChoices[i].message,
                id = i
            },
        })
    end
    print("After inserting rows into tableView", system.getTimer() - t)
end

-- Draw a row for the user's selcted locations. Data will be passed in as params in the insertRow() method
-- to emulate M-V-C design patterns.
local function onMessageRowRender( event )
    local row = event.row
    local params = event.row.params
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth
    local rowTitle = display.newText( row, params.time.." "..params.message, 20, rowHeight * 0.5, myData.font, 16 )
    rowTitle:setFillColor( unpack( theme.textColor ) )
    rowTitle.anchorX = 0
    if params.selected then
        local checkMark = display.newImageRect( row, "images/checkmark.png", 30, 30 )
        checkMark.x = rowWidth - 30
        checkMark.y = rowTitle.y
    end
    if not params.noDelete then
        local deleteButton = display.newGroup()
        local deleteButtonBackground = display.newRect( 25, 20 , 50, 40)
        deleteButtonBackground:setFillColor( 0.9, 0, 0 )
        deleteButton:insert( deleteButtonBackground )
        local deleteButtonText = display.newText( "Delete", 25, 20, myData.font, 11 )
        deleteButtonText:setFillColor( 1 )
        deleteButton:insert( deleteButtonText )
        deleteButton:addEventListener( "touch", myCtrl.deleteRow )
        deleteButton.x = rowWidth + 1
        deleteButton.y = 0
        deleteButton.id = params.id
        row.deleteButton = deleteButton
        row:insert( deleteButton )
    end
end
-------------------------------------
-- Start the composer event handlers
--
function scene:create( event )
    local sceneGroup = self.view
    local statusBarPad = display.topStatusBarContentHeight
    -- make a rectangle for the backgrouned and color it to the current theme
    sceneBackground = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
    sceneGroup:insert( sceneBackground )
    -- it will be themed in the show() event before it comes on screen
    -- make sure that touches outside of places that expect them will hide the keyboard
    sceneBackground:addEventListener( "touch", myCtrl.dismisKeyboard )

    --
    rightButton = widget.newButton({
                id = "searchBtn",
                label = "Search",
                onEvent = myCtrl.onSearchEvent,
                font = myData.font,
                fontSize = 12,
                labelColor = { default={ 0, 0, 1 }, over={ 1, 0, 0, 0.5 } },
                labelAlign = "right",
            })
        --
        rightButton.x = display.contentWidth - rightButton.width*0.5
        rightButton.y = UI.navBar.height - 6
        UI.navBar:insert(rightButton)

    rightButton2 = widget.newButton({
                id = "selectBtn",
                label = "Select",
                onEvent = myCtrl.onSelectEvent,
                font = myData.font,
                fontSize = 12,
                labelColor = { default={ 0, 0, 1 }, over={ 1, 0, 0, 0.5 } },
                labelAlign = "right",
            })
        --
        rightButton2.x = rightButton.x - rightButton2.width*0.5
        rightButton2.y = rightButton.y
        UI.navBar:insert(rightButton2)

    rightButton3 = widget.newButton({
                id = "deleteBtn",
                label = "Delete",
                onEvent = myCtrl.onDeleteEvent,
                font = myData.font,
                fontSize = 12,
                labelColor = { default={ 0, 0, 1 }, over={ 1, 0, 0, 0.5 } },
                labelAlign = "right",
            })
        --
        rightButton3.x = rightButton2.x - rightButton3.width*0.5
        rightButton3.y = rightButton.y
        UI.navBar:insert(rightButton3)

    rightButton4 = widget.newButton({
                id = "insertBtn",
                label = "New",
                onEvent = myCtrl.onInsertEvent,
                font = myData.font,
                fontSize = 12,
                labelColor = { default={ 0, 0, 1 }, over={ 1, 0, 0, 0.5 } },
                labelAlign = "right",
            })
        --
        rightButton4.x = rightButton3.x -  rightButton4.width*0.5
        rightButton4.y = rightButton.y
        UI.navBar:insert(rightButton4)
    --
    local messageTableViewHeight = display.actualContentHeight - messageTableMarginBottom - statusBarPad
    messagesTableView = widget.newTableView({
        left = 20,
        top =  60 + statusBarPad,
        height = messageTableViewHeight,
        width = display.contentWidth - 40,
        onRowRender = onMessageRowRender,
        onRowTouch = myCtrl.onMessageRowTouch,
        hideBackground = true,
        listener = myCtrl.messageListener
    })
    self.messagesTableView = messagesTableView
    sceneGroup:insert( messagesTableView )
end
-------------------------------------
-- handle showing the scene. Here we will create text field, set the theme, open the DB, reload the
-- user's locations and set the navBar label
function scene:show( event )
    local sceneGroup = self.view
    if event.phase == "will" then
        myData.init()
        myCtrl.reloadData()
        UI.navBar:setLabel( "Messages" )
        sceneBackground:setFillColor( unpack( theme.backgroundColor ) )
        rightButton.isVisible = true
        rightButton2.isVisible = true
        rightButton3.isVisible = true
        rightButton4.isVisible = true
    else
        local statusBarPad = display.topStatusBarContentHeight
        -- after the scene is on the screen
        -- calcuate how wide the text entry field will be (leave 20 px padding on both sides)
        local fieldWidth = display.contentWidth - 40
        -- create the text field and handler. Doing this before the scene is on the screen looks weird.
        messageEntryField = native.newTextField( 20,  SearchMsgY + statusBarPad, fieldWidth, 30 )
        messageEntryField:addEventListener( "userInput", myCtrl.fieldHandler( function() return messageEntryField end ) )
        sceneGroup:insert( messageEntryField)
        messageEntryField.anchorX = 0
        messageEntryField.placeholder = "Message"
        messageEntryField.isVisible = false
        self.messageEntryField = messageEntryField
       -- self.hideTextField()
    end
end
-------------------------------------
-- handle features when we need to hide the scene
function scene:hide( event )
    local sceneGroup = self.view
    if event.phase == "will" then
        -- before we leave the screen, close the database, since it was opened in show()
        myData.close()
        -- remove the text field, since we created it in show().
        messageEntryField:removeSelf();
        messageEntryField = nil

        rightButton.isVisible  = false
        rightButton2.isVisible = false
        rightButton3.isVisible = false
        rightButton4.isVisible = false
    end
end
-------------------------------------
--
function scene:destroy( event )
    local sceneGroup = self.view
    -- place holder in case we need to destroy something later (not a usual thing if you created things correctly)
end
---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene
