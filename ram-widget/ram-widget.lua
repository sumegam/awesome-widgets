local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local ram_widget = {}
local min_swap = 100 * 1024

function round(number)
    return math.floor(10 * number / 1024^2 + 0.5) / 10
end

local function worker(args)
    local args = args or {}

    --- Ram widget
    ram_widget = wibox.widget.textbox()

    local total, used, free, shared, buff_cache, available, swap_total, swap_used, swap_free

    watch('bash -c "free | tail -n 2"', 1,
    	function(widget, stdout, stderr, exitreason, exitcode)
	    total, used, free, shared, buff_cache, available, swap_total, swap_used, swap_free =
	    	stdout:match('(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*Swap:%s*(%d+)%s*(%d+)%s*(%d+)')
	    if tonumber(swap_used) > min_swap then
		widget.text = string.format(" %.1f GiB %.1f GiB ", round(used), round(swap_used))
	    else
		widget.text = string.format(" %.1f GiB ", round(used))
	    end
	end,
	ram_widget
    )

    return ram_widget
end

return setmetatable(ram_widget, {__call = function(_, ...)
    return worker(...)
end })
