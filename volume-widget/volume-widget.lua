local wibox = require("wibox")
local watch = require("awful.widget.watch")
local spawn = require("awful.spawn")
local naughty = require("naughty")
local gfs = require("gears.filesystem")
local dpi = require('beautiful').xresources.apply_dpi

local PATH_TO_ICONS = "/usr/share/icons/Adwaita/symbolic/status/"
local volume_icon_name="audio-volume-medium-symbolic"


function get_volume_from_output(output)
    local volume = string.match(string.match(output, "Playback %d+ %[%d+%%]"), "%[%d+%%]")
    volume = string.match(volume, "%d+")
    local muted = string.match(output:sub(-6, -1), 'off') ~= nil
    return tonumber(volume), muted
end

function set_image(volume, muted)
    if muted or volume == 0 then
        volume_icon_name = "audio-volume-muted-symbolic"
    else
        if volume < 25 then
            volume_icon_name = "audio-volume-low-symbolic"
        elseif volume < 50 then
            volume_icon_name = "audio-volume-medium-symbolic"
        elseif volume < 75 then
            volume_icon_name = "audio-volume-high-symbolic"
        else
            volume_icon_name = "audio-volume-overamplified-symbolic"
        end
    end
end

--- Volume widget
local volume_widget = wibox.widget {
    {
        {
            id = "icon",
            resize = false,
            widget = wibox.widget.imagebox,
        },
        valign = 'center',
        layout = wibox.container.place
    },
    {
        id = "volume",
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.horizontal,
}

local volume_child = volume_widget:get_children_by_id("volume")[1]
local image_child = volume_widget:get_children_by_id("icon")[1]

local function worker(args)
    local args = args or {}

    local volume_delta = 2
    if args.volume_delta ~= nil then
        volume_delta = args.volume_delta
    end

    local GET_VOLUME = 'amixer sget Master -M'
    local INCREASE_VOLUME = 'amixer sset Master ' ..volume_delta.. '%+ -M'
    local DECREASE_VOLUME = 'amixer sset Master ' ..volume_delta.. '%- -M'
    local TOGGLE_VOLUME = 'amixer sset Master toggle'

    local function update_widget(output)
        lvl, muted = get_volume_from_output(output)
        volume_child:set_text(lvl)

        set_image(lvl, muted)
        image_child:set_image(PATH_TO_ICONS .. volume_icon_name .. ".svg")
    end

    function volume_widget:increase_volume()
        spawn.easy_async(INCREASE_VOLUME, function(stdout) update_widget(stdout) end)
    end

    function volume_widget:decrease_volume()
        spawn.easy_async(DECREASE_VOLUME, function(stdout) update_widget(stdout) end)
    end

    function volume_widget:toggle_volume()
        spawn.easy_async(TOGGLE_VOLUME, function(stdout) update_widget(stdout) end)
    end

    --- Update widget every second in case something except keyboard shortcut changed volume
    watch(GET_VOLUME, 1, function(volume_widget, stdout)
        update_widget(stdout)
    end, volume_widget)

    return volume_widget
end

return setmetatable(volume_widget, { __call = function(_, ...)
    return worker(...)
end})
