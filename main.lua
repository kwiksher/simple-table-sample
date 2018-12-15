function DidReceiveRemoteNotification(message, additionalData, isActive)
    native.showAlert("message:", message, { "OK" } )
end

display.setStatusBar( display.DefaultStatusBar )

local theme = require( "classes.theme" )
local UI = require( "classes.ui" )
theme.setTheme( "light" )
UI.createNavBar()

local composer = require( "composer" )
composer.gotoScene("messagesTable")

