local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local disk_widget = {}

local function round_to_gib(number)
    return math.floor(10 * number / 1024 + 0.5) / 10
end

local function create_textbox(args)
    local text_widget = wibox.widget{
        text = args.text,
        align = args.align or 'left',
        markup = args.markup,
        forced_width = args.forced_width or 10,
        widget = wibox.widget.textbox,
    }
    return wibox.widget{
        {
            text_widget,
            left = args.left_margin or 10,
            widget = wibox.container.margin
        },
        widget = wibox.container.background
    }
end

local function create_disk_header(params)
  local res = wibox.widget{
      create_textbox{markup = '<b>Filesystem</b>', align = 'left', left_margin = 0},
      create_textbox{markup = '<b>Size (GiB)</b>', align = 'right', left_margin = 0},
      create_textbox{markup = '<b>Used (GiB)</b>', align = 'right'},
      create_textbox{markup = '<b>Avail (GiB)</b>', align = 'right'},
      create_textbox{markup = '<b>Mount</b>', align = 'left', left_margin = 20},
      layout = wibox.layout.ratio.horizontal
  }
  res:set_ratio(5, 0.4)

  return res
end

local function worker(args)
  local args = args or {}

  local width = 500
  if args.width ~= nil then
      width = args.width
  end

  local main_filesystem = '/dev/sdb3'
  if args.main_filesystem ~= nil then
      main_filesystem = args.main_filesystem
  end

  --- Disk widget
  disk_widget = wibox.widget.textbox()

  local popup = awful.popup{
      ontop = true,
      visible = false,
      shape = gears.shape.rect,
      border_width = 1,
      border_color = beautiful.bg_normal,
      maximum_width = width,
      offset = { y = 5 },
      widget = {},
      minimum_width = width
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
    'bash -c "df -h -BM | tail -n+2"',
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
            size = round_to_gib(w:sub(1, -2))
          elseif j == 2 then
            used = round_to_gib(w:sub(1, -2))
          elseif j == 3 then
            avail = round_to_gib(w:sub(1, -2))
          elseif j == 5 then
            mount = w:gsub("[\n\r]", "")
          end
          j = j + 1
        end

        if filesystem == main_filesystem then
          main_avail = avail
        end

        row_widget = wibox.widget{
          create_textbox{text = filesystem, align = 'left', left_margin = 0},
          create_textbox{text = size, align = 'right', left_margin = 0},
          create_textbox{text = used, align = 'right'},
          create_textbox{text = avail, align = 'right'},
          create_textbox{text = mount, align = 'left', left_margin = 20},
          layout = wibox.layout.ratio.horizontal
        }
        row_widget:set_ratio(5, 0.4)

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
