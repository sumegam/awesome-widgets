local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local disk_widget = {}
local main_filesystem = '/dev/sdb3'

local function round(number)
    return math.floor(10 * number / 1024^2 + 0.5) / 10
end

local function create_textbox(args)
    return wibox.widget{
        text = args.text,
        align = args.align or 'left',
        markup = args.markup,
        forced_width = args.forced_width or 40,
        widget = wibox.widget.textbox
    }
end

local function create_disk_header(params)
  local res = wibox.widget{
      create_textbox{markup = '<b>Filesystem</b>'},
      create_textbox{markup = '<b>Size</b>'},
      create_textbox{markup = '<b>Used</b>'},
      create_textbox{markup = '<b>Avail</b>'},
      create_textbox{markup = '<b>Mount</b>'},
      layout = wibox.layout.ratio.horizontal
  }
  res:ajust_ratio(1, 0, 0.2, 0.8)
  res:ajust_ratio(2, 0.2, 0.1, 0.7)
  res:ajust_ratio(3, 0.3, 0.1, 0.6)
  res:ajust_ratio(4, 0.4, 0.1, 0.5)

  return res
end

local function worker(args)
  local args = args or {}

  --- Disk widget
  disk_widget = wibox.widget.textbox()

  local popup = awful.popup{
      ontop = true,
      visible = false,
      shape = gears.shape.rect,
      border_width = 1,
      border_color = beautiful.bg_normal,
      maximum_width = 1000,
      offset = { y = 5 },
      widget = {},
      minimum_width = 500
  }

  local filesystem, size, used, avail, avail_percent, mount
  local main_avail
  local disk_rows = {
    layout = wibox.layout.fixed.vertical
  }

  disk_widget:connect_signal('button::press', function(c)
    if #disk_rows > 0 then
      popup.visible = not popup.visible
      if popup.visible then
        popup:move_next_to(mouse.current_widget_geometry)
      end
    end
  end)

  watch(
    'bash -c "df -h | tail -n+2"',
    1,
  	function(widget, stdout, stderr, exitreason, exitcode)
      disk_rows = {
        layout = wibox.layout.fixed.vertical
      }
      i = 0
      for line in stdout:gmatch("[^\r\n]+") do
        j = 0
        for w in line:gmatch("%S+") do
          if j == 0 then
            filesystem = w
          elseif j == 1 then
            size = w:sub(1, -2)
          elseif j == 2 then
            used = w:sub(1, -2)
          elseif j == 3 then
            avail = w:sub(1, -2)
          elseif j == 5 then
            mount = w
          end
          j = j + 1
        end

        if filesystem == main_filesystem then
          main_avail = avail
        end

        row_widget = wibox.widget{
          create_textbox{text = filesystem},
          create_textbox{text = size},
          create_textbox{text = used},
          create_textbox{text = avail},
          create_textbox{text = mount},
          layout = wibox.layout.ratio.horizontal
        }
        row_widget:ajust_ratio(1, 0, 0.2, 0.8)
        row_widget:ajust_ratio(2, 0.2, 0.1, 0.7)
        row_widget:ajust_ratio(3, 0.3, 0.1, 0.6)
        row_widget:ajust_ratio(4, 0.4, 0.1, 0.5)

        disk_rows[i] = wibox.widget {
          {
            row_widget,
            top = 4,
            bottom = 4,
            widget = wibox.container.margin
          },
          widget = wibox.container.background
        }
        i = i + 1
      end

      popup:setup {
        {
            create_disk_header(),
            disk_rows,
            layout = wibox.layout.fixed.vertical,
        },
        margins = 8,
        widget = wibox.container.margin,
      }
  		widget.text = string.format(" %.1f GiB ", tonumber(main_avail))
	  end,
  	disk_widget
  )

  return disk_widget
end

return setmetatable(disk_widget, {__call = function(_, ...)
    return worker(...)
end })
