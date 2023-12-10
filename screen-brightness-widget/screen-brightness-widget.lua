local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")

local path_to_icon = '/usr/share/icons/Adwaita/symbolic/status/display-brightness-symbolic.svg'
local brightness_widget = wibox.widget {
    {
        {
            id = 'icon',
            image = path_to_icon,
            resize = false,
            widget = wibox.widget.imagebox,
        },
        valign = 'center',
        layout = wibox.container.place
    },
    {
        id = 'brightness',
        widget = wibox.widget.textbox
    },
    spacing = 4,
    layout = wibox.layout.fixed.horizontal,
    set_value = function(self, display_level)
        self:get_children_by_id('txt')[1]:set_text(display_level)
    end
}
local brightness_child = brightness_widget:get_children_by_id("brightness")[1]

local function worker(user_args)
	  local args = user_args or {}
    
    local current_level = 0
    local brightness_delta = 2
    if args.brightness_delta ~= nil then
       brightness_delta = args.brightness_delta
    end

    local GET_BRIGHTNESS = 'xbacklight -get'
    local INCREASE_BRIGHTNESS = 'xbacklight -inc ' .. brightness_delta
    local DECREASE_BRIGHTNESS = 'xbacklight -dec ' .. brightness_delta

    local function update_widget(output)
        brightness_child:set_text(output)
        current_level = tonumber(output)
    end

    function brightness_widget:increase_brightness()
        spawn.easy_async(INCREASE_BRIGHTNESS, function(stdout)
            spawn.easy_async(GET_BRIGHTNESS, function(stdout) update_widget(stdout) end)
        end)
    end

    function brightness_widget:decrease_brightness()
        spawn.easy_async(DECREASE_BRIGHTNESS, function(stdout)
            spawn.easy_async(GET_BRIGHTNESS, function(stdout) update_widget(stdout) end)
        end)
    end

    --- Update widget every second in case something except keyboard shortcut changed brightness 
    watch(GET_BRIGHTNESS, 1, function(brightness_widget, stdout)
        update_widget(stdout)
    end, brightness_widget)

    return brightness_widget
end

return setmetatable(brightness_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
