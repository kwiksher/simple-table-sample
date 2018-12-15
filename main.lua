function DidReceiveRemoteNotification(message, additionalData, isActive)
    native.showAlert("message:", message, { "OK" } )
end

display.setStatusBar( display.DefaultStatusBar )

local theme = require( "classes.theme" )    -- Theme module
local UI = require( "classes.ui" )          -- The TabBar and NavBar code. It sits above all composer scenes.
theme.setTheme( "light" )
UI.createNavBar()

local composer = require( "composer" )

composer.gotoScene("messagesTable")

