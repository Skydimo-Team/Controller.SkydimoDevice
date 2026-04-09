--[[
  Skydimo HID Controller – Lua controller plugin entry

  Drives Skydimo-branded HID LED strips (VID 0x1A86, PID 0xE316).
  Uses runtime-provided HID USB strings to mirror the original C++ naming behavior.
  Supports all official Skydimo device models with configurable layouts.

  Protocol reference: reference/SkydimoController/SkydimoHIDController/

  Notes:
  - Device communication uses HID write (not feature reports).
  - RGB data is sent in GRB byte order in batches of 20 LEDs.
  - Each batch packet includes a CRC8-MAXIM checksum.
  - Serial numbers in decimal format are converted to uppercase hex.
]]

local protocol = require("lib.protocol")
local config   = require("lib.config")

local plugin = {}

local state = {
  initialized = false,
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Convert a decimal serial string to uppercase hex.
local function decimal_serial_to_hex(serial)
  if not serial or serial == "" then
    return serial
  end
  -- Check if all characters are decimal digits
  if not serial:match("^%d+$") then
    return serial
  end
  -- Convert to number and then to uppercase hex
  local value = tonumber(serial)
  if not value then
    return serial
  end
  return string.format("%X", value)
end

---------------------------------------------------------------------------
-- Lifecycle callbacks
---------------------------------------------------------------------------

local function compose_device_name(manufacturer, product)
  if manufacturer ~= "" and product ~= "" then
    return manufacturer .. " " .. product
  end
  if product ~= "" then
    return product
  end
  if manufacturer ~= "" then
    return manufacturer
  end
  return "Skydimo LED Strip"
end

function plugin.on_validate()
  local manufacturer = device:manufacturer() or ""
  local product = device:model() or ""

  -- Follow the original C++ naming behavior exactly:
  -- manufacturer + product, else product, else manufacturer, else fallback.
  local device_name = compose_device_name(manufacturer, product)

  -- Convert serial: decimal → uppercase hex
  local serial = device:serial_id() or "000000"
  serial = decimal_serial_to_hex(serial)

  device:set_manufacturer("Skydimo")
  device:set_model(device_name)
  device:set_device_type("light")
  device:set_serial_id(serial)

  -- Quick protocol test: send a small black frame to confirm the device can communicate
  local ok, err = pcall(function()
    local test_grb = string.rep("\0", 60) -- 20 black LEDs
    device:write(protocol.build_rgb_packet(test_grb, 0))
    device:write(protocol.build_end_packet(20))
  end)
  if not ok then
    device:error("Skydimo HID: protocol test failed – " .. tostring(err))
    return false
  end

  device:log("Skydimo HID: validated '" .. device_name .. "' serial=" .. serial)
  return true
end

function plugin.on_init()
  local model_name = device:model() or ""

  -- Resolve image URL based on model
  local image_url = config.resolve_image_url(model_name)
  if image_url then
    device:set_image_url(image_url)
  end

  -- Build layout from model name
  local layout = config.build_layout_from_device_name(model_name)

  if layout then
    -- Known model with fixed layout
    device:add_output({
      id   = "out1",
      name = "Output 1",
      type = layout.segment_type,
      size = layout.total_leds,
      matrix = layout.matrix,
      capabilities = {
        editable = false,
        min_total_leds = layout.total_leds,
        max_total_leds = layout.total_leds,
        allowed_total_leds = { layout.total_leds },
      },
    })

    device:log(string.format(
      "Skydimo HID: initialized '%s' — %d LEDs, type=%s",
      model_name, layout.total_leds, layout.segment_type
    ))
  else
    -- Unknown Skydimo model: resizable linear strip
    device:add_output({
      id   = "out1",
      name = "LED Strip",
      type = "linear",
      size = 60,
      capabilities = {
        editable = true,
        min_total_leds = 1,
        max_total_leds = 150,
      },
    })

    device:log("Skydimo HID: initialized unknown model '" .. model_name .. "' as resizable strip")
  end

  -- Configure device: turn off LEDs when the host stops sending data.
  -- Firmware will auto-black-out ~3 s after the last packet.
  protocol.send_offline_cfg(0, 0, true)

  state.initialized = true
end

function plugin.on_tick(_dt)
  if not state.initialized then
    return
  end
  local rgb = device:get_rgb_bytes("out1")
  if rgb and #rgb > 0 then
    protocol.send_frame(rgb)
  end
end

function plugin.on_shutdown()
  if not state.initialized then
    return
  end
  local count = device:output_led_count("out1") or 0
  if count > 0 then
    protocol.send_black(count)
  end
  device:log("Skydimo HID: shutdown, LEDs cleared")
end

return plugin
