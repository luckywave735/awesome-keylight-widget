-------------------------------------------------
-- Keylight menu
-------------------------------------------------

local awful = require("awful");
local beautiful = require("beautiful")
local gears = require("gears")
local spawn = require("awful.spawn")
local wibox = require("wibox");

-- Set your specific location of the widget
local MY_THEME = "onedarkplusnord"

local KEYLIGHT_BASH_SCRIPT = string.format("~/.config/awesome/themes/onedarkplusnord/widgets/awesome-keylight-widget/keylight_bash.sh", MY_THEME)
local LIST_DEVICES_CMD = string.format([[sh -c "%s list"]], KEYLIGHT_BASH_SCRIPT)

function extract_list_devices(cmd_output)
    local devices = {}
    local device
    for line in cmd_output:gmatch("[^\r\n]+") do
        if string.match(line, '\"address\": \"([^\"]+)\"') then
            device = {
                address = line:match('\"address\": \"([^\"]+)\"'),
            }

            if string.match(line, '\"port\": (%d+)') then
                device['port'] = line:match('\"port\": (%d+)')
            end

            if string.match(line, '\"url\": \"([^\"]+)\"') then
                device['url'] = line:match('\"url\": \"([^\"]+)\"')
            end

            if string.match(line, '\"hostname\": \"([^\"]+)\"') then
                device['hostname'] = line:match('\"hostname\": \"([^\"]+)\"')
            end

            if string.match(line, '\"productName\": \"([^\"]+)\"') then
                device['productName'] = line:match('\"productName\": \"([^\"]+)\"')
            end

            if string.match(line, '\"hardwareBoardType\": (%d+)') then
                device['hardwareBoardType'] = line:match('\"hardwareBoardType\": (%d+)')
            end

            if string.match(line, '\"firmwareBuildNumber\": (%d+)') then
                device['firmwareBuildNumber'] = line:match('\"firmwareBuildNumber\": (%d+)')
            end

            if string.match(line, '\"firmwareVersion\": \"([^\"]+)\"') then
                device['firmwareVersion'] = line:match('\"firmwareVersion\": \"([^\"]+)\"')
            end

            if string.match(line, '\"firmwareVersion\": \"([^\"]+)\"') then
                device['firmwareVersion'] = line:match('\"firmwareVersion\": \"([^\"]+)\"')
            end

            if string.match(line, '\"serialNumber\": \"([^\"]+)\"') then
                device['serialNumber'] = line:match('\"serialNumber\": \"([^\"]+)\"')
            end

            if string.match(line, '\"displayName\": \"([^\"]+)\"') then
                device['displayName'] = line:match('\"displayName\": \"([^\"]+)\"')
            end

            if string.match(line, '\"lights\": %[ ([^%]]+) %]') then
                light_info = line:match('\"lights\": %[ ([^%]]+) %]')
                if string.match(light_info, '\"on\": (%d)') then
                    device['isOn'] = light_info:match('\"on\": (%d)')
                end

                if string.match(light_info, '\"brightness\": (%d+)') then
                    device['isBrightness'] = light_info:match('\"brightness\": (%d+)')
                end

                if string.match(light_info, '\"temperature\": (%d+)') then
                    device['isTemperature'] = light_info:match('\"temperature\": (%d+)')
                end
            end

            if string.match(line, '\"settings\": %{(.) %}') then
                settings_list = line:match('\"settings\": %{(.) %}')
                if string.match(settings_list, '\"powerOnBehavior\": (%d)') then
                    device['powerOnBehavior'] = settings_list:match('\"powerOnBehavior\": (%d)')
                end

                if string.match(settings_list, '\"powerOnBrightness\": (%d+)') then
                    device['powerOnBrightness'] = settings_list:match('\"powerOnBrightness\": (%d+)')
                end

                if string.match(settings_list, '\"powerOnTemperature\": (%d+)') then
                    device['powerOnTemperature'] = settings_list:match('\"powerOnTemperature\": (%d+)')
                end

                if string.match(settings_list, '\"switchOnDurationMs\": (%d+)') then
                    device['switchOnDurationMs'] = settings_list:match('\"switchOnDurationMs\": (%d+)')
                end

                if string.match(settings_list, '\"switchOffDurationMs\": (%d+)') then
                    device['switchOffDurationMs'] = settings_list:match('\"switchOffDurationMs\": (%d+)')
                end

                if string.match(settings_list, '\"colorChangeDurationMs\": (%d+)') then
                    device['colorChangeDurationMs'] = settings_list:match('\"colorChangeDurationMs\": (%d+)')
                end

                if string.match(settings_list, '\"battery\": %{(.) %}') then
                    battery_info = settings_list:match('\"battery\": %{(.) %}')

                    if string.match(settings_list, '\"energySaving\": %{(.) %}') then
                        energySaving_info = battery_info:match('\"energySaving\": %{(.) %}')

                        if string.match(energySaving_info, '\"enable\": (%d)') then
                            device['esEnable'] = energySaving_info:match('\"enable\": (%d)')
                        end

                        if string.match(energySaving_info, '\"minimumBatteryLevel\": (%d%+.%d+)') then
                            device['esMinimumBatteryLevel'] = energySaving_info:match('\"minimumBatteryLevel\": (%d%+.%d+)')
                        end

                        if string.match(energySaving_info, '\"disableWifi\": (%d)') then
                            device['esDisableWifi'] = energySaving_info:match('\"disableWifi\": (%d)')
                        end
                    end

                    if string.match(settings_list, '\"adjustBrightness\": %{(.) %}') then
                        adjustBrightness_info = battery_info:match('\"adjustBrightness\": %{(.) %}')

                        if string.match(adjustBrightness_info, '\"enable\": (%d)') then
                            device['esAdjustBrightnessEnable'] = adjustBrightness_info:match('\"enable\": (%d)')
                        end

                        if string.match(adjustBrightness_info, '\"brightness\": (%d%+.%d+)') then
                            device['esAdjustBrightnessBrightness'] = adjustBrightness_info:match('\"brightness\": (%d%+.%d+')
                        end
                    end
                    if string.match(battery_info, '\"bypass\": (%d)') then
                        device['bypass'] = battery_info:match('\"bypass\": (%d)')
                    end

                end
            end
        end

        table.insert(devices, device)
    end

    return devices
end

lights = {}

local rows  = { layout = wibox.layout.fixed.vertical }

local popup = awful.popup{
    bg = beautiful.bg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = 400,
    offset = { y = 5 },
    widget = {}
}


local function build_rows(devices, on_checkbox_click)
    local device_rows  = { layout = wibox.layout.fixed.vertical }
    for _, device in pairs(devices) do

        local checkbox = wibox.widget {
            checked = device['isOn'],
            color = beautiful.fg_normal,
            paddings = 2,
            shape = gears.shape.circle,
            forced_width = 20,
            forced_height = 20,
            check_color = beautiful.fg_urgent,
            widget = wibox.widget.checkbox
        }

        local row = wibox.widget {
            {
                {
                    {
                        checkbox,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    {
                        {
                            text = device.displayName,
                            align = 'left',
                            widget = wibox.widget.textbox
                        },
                        left = 10,
                        layout = wibox.container.margin
                    },
                    spacing = 8,
                    layout = wibox.layout.align.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
        row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

        row:connect_signal("button::press", function()
            if device['isOn'] == "0" then
                spawn.easy_async(string.format([[sh -c "%s on %s %s"]], KEYLIGHT_BASH_SCRIPT, device['address'], device['port']), function()
                    device['isOn'] = "1"
                    on_checkbox_click()
                end)
            elseif device['isOn'] == "1" then
                spawn.easy_async(string.format([[sh -c "%s off %s %s"]], KEYLIGHT_BASH_SCRIPT, device['address'], device['port']), function()
                    device['isOn'] = "0"
                    on_checkbox_click()
                end)
            end
        end)

        table.insert(device_rows, row)

        --- Brightness (0-100 value range)
        local slider = wibox.widget{
            bar_shape           = gears.shape.rounded_rect,
            bar_height          = 3,
            bar_color           = beautiful.fg_normal,
            handle_color        = beautiful.fg_normal,
            handle_shape        = gears.shape.circle,
            handle_border_color = beautiful.border_normal,
            handle_border_width = 1,
            forced_width = 60,
            forced_height = 20,
            value               = tonumber(device.isBrightness),
            widget              = wibox.widget.slider,
        }

        slider:connect_signal("button::release", function(w,_,_,button)
            spawn.easy_async(string.format([[sh -c "%s brightness %s %s %s"]], KEYLIGHT_BASH_SCRIPT, device.address, device.port, w.value), function()
                device['isBrightness']=w.value
                on_checkbox_click()
            end)
        end)

        local row = wibox.widget {
            {
                {
                    {
                        {
                            text = "Brightness: " .. device.isBrightness,
                            align = 'left',
                            widget = wibox.widget.textbox
                        },
                        left = 10,
                        layout = wibox.container.margin
                    },
                    {
                        slider,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    spacing = 8,
                    layout = wibox.layout.align.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        table.insert(device_rows, row)

        --- Brightness +/- buttons
        inc_button = wibox.widget{
            {
                text = "+",
                font = "Liberation Sans 15",
                forced_height = 20,
                align = "center",
                widget = wibox.widget.textbox
            },
            shape = function(cr, width, height) 
                gears.shape.rounded_rect(cr, width, height, 4) 
            end,
            widget = wibox.container.background
        }
        inc_button:connect_signal("button::press", function(c)
            c:set_bg(beautiful.bg_normal);
            local new_value = math.max(0,math.min(tonumber(device['isBrightness'])+5,100))
            spawn.easy_async(string.format([[sh -c "%s brightness %s %s %s"]], KEYLIGHT_BASH_SCRIPT, device.address, device.port, new_value), function()
                device['isBrightness'] = new_value
                on_checkbox_click()
            end)
        end)
        inc_button:connect_signal("button::release", function(c) c:set_bg(beautiful.fg_normal) end)
        inc_button:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.fg_normal); c:set_fg(beautiful.bg_normal) end)
        inc_button:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal); c:set_fg(beautiful.fg_normal) end)

        dec_button = wibox.widget{
            {
                text = "-",
                font = "Liberation Sans 15",
                forced_height = 20,
                align = "center",
                widget = wibox.widget.textbox
            },
            shape = function(cr, width, height) 
                gears.shape.rounded_rect(cr, width, height, 4) 
            end,
            widget = wibox.container.background
        }
        dec_button:connect_signal("button::press", function(c)
            c:set_bg(beautiful.bg_normal);
            local new_value = math.max(0,math.min(tonumber(device['isBrightness'])-5,100))
            spawn.easy_async(string.format([[sh -c "%s brightness %s %s %s"]], KEYLIGHT_BASH_SCRIPT, device.address, device.port, new_value), function()
                device['isBrightness'] = new_value
                on_checkbox_click()
            end)
        end)
        dec_button:connect_signal("button::release", function(c) c:set_bg(beautiful.fg_normal) end)
        dec_button:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.fg_normal); c:set_fg(beautiful.bg_normal) end)
        dec_button:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal); c:set_fg(beautiful.fg_normal) end)

        local row = wibox.widget {
            {
                {
                    {
                        dec_button,
                        left = 10,
                        layout = wibox.container.margin
                    },
                    {
                        inc_button,
                        left = 10,
                        layout = wibox.container.margin
                    },
                    spacing = 8,
                    layout = wibox.layout.flex.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        table.insert(device_rows, row)

        --- Temperature (2900-7000 value range)
        local sliderT = wibox.widget{
            bar_shape           = gears.shape.rounded_rect,
            bar_height          = 3,
            bar_color           = beautiful.fg_normal,
            handle_color        = beautiful.fg_normal,
            handle_shape        = gears.shape.circle,
            handle_border_color = beautiful.border_normal,
            handle_border_width = 1,
            forced_width = 50,
            forced_height = 20,
            value               = math.floor((math.floor((1000000 * 1/tonumber(device.isTemperature)) + 0.5)-2900)/41),
            widget              = wibox.widget.slider,
        }

        sliderT:connect_signal("button::release", function(w,_,_,button)
            local new_k_value = math.floor(((w.value)*41+2900) + 0.5)
            local new_value = math.floor((987007 * 1.009/tonumber(new_k_value)) + 0.5)
            spawn.easy_async(string.format([[sh -c "%s temperature %s %s %s"]], KEYLIGHT_BASH_SCRIPT, device.address, device.port, new_value), function()
                on_checkbox_click()
            end)
        end)

        local row = wibox.widget {
            {
                {
                    {
                        {
                            text = "Temperature: " .. math.floor(math.floor((1000000 * 1/tonumber(device.isTemperature)) + 0.5)/100 + 0.5)*100,
                            align = 'left',
                            widget = wibox.widget.textbox
                        },
                        left = 10,
                        layout = wibox.container.margin
                    },
                    {
                        sliderT,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    spacing = 8,
                    layout = wibox.layout.align.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            widget = wibox.container.background
        }

        table.insert(device_rows, row)
    end

    return device_rows
end

local function build_header_row(text)
    return wibox.widget{
        {
            markup = "<b>" .. text .. "</b>",
            align = 'center',
            widget = wibox.widget.textbox
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }
end

local function rebuild_popup()
    spawn.easy_async(LIST_DEVICES_CMD, function(stdout)

        local devices = extract_list_devices(stdout)

        for i = 0, #rows do rows[i]=nil end

        table.insert(rows, build_header_row("Devices"))
        table.insert(rows, build_rows(devices, function() rebuild_popup() end))

        popup:setup(rows)
    end)
end


local worker = function(user_args)

	local args = user_args or {}

	local icon = args.icon;
	local font = args.font or "sans-serif 9";
	local step = args.step or 5
	local timeout = 2;
    local devices = {}
	
	lights.widget = wibox.widget{
		layout = wibox.layout.fixed.horizontal,
		spacing = args.space,
		{
			id = "icon",
			widget = wibox.widget.imagebox,
			image = icon
		},
		{
			id = "lights",
			font = font,
			widget = wibox.widget.textbox
		},
	}

	--- Adds mouse controls to the widget:
	--  - left click - Toggle all lights
	lights.widget:connect_signal("button::press", function(_, _, _, button)
			if button == 1 then
                spawn.easy_async(LIST_DEVICES_CMD, function(stdout)
                    local devices = extract_list_devices(stdout)
                    for _, device in pairs(devices) do
                        if device['isOn'] == "0" then
                            spawn.easy_async(string.format([[sh -c "%s on %s %s"]], KEYLIGHT_BASH_SCRIPT, device['address'], device['port']), function()
                                device['isOn'] = "1"
                            end)
                        elseif device['isOn'] == "1" then
                            spawn.easy_async(string.format([[sh -c "%s off %s %s"]], KEYLIGHT_BASH_SCRIPT, device['address'], device['port']), function()
                                device['isOn'] = "0"
                            end)
                        end
                    end
                end)
            end;
		end
	);


	lights.widget:buttons(
		awful.util.table.join(
				awful.button({}, 3, function()
					if popup.visible then
						popup.visible = not popup.visible
					else
						rebuild_popup()
						popup:move_next_to(mouse.current_widget_geometry)
					end
				end)
		)
	)

	return lights.widget;
end;

return setmetatable(lights, {	__call = function(_, ...)
		return worker(...);
	end
});
