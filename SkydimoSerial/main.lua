local protocol = require("lib.protocol")
local config = require("lib.config")

local plugin = {}

function plugin.on_validate()
  local info = protocol.query_info()
  if not info then
    return false
  end

  local model = info.model or "UNKNOWN"
  local full_model = model
  if full_model:sub(1, 7):upper() ~= "SKYDIMO" then
    full_model = "Skydimo " .. model
  end

  device:set_manufacturer("Skydimo")
  device:set_model(full_model)
  device:set_serial_id(info.serial_id or "000000")
  device:set_description("Skydimo Serial Device")
  return true
end

function plugin.on_init()
  local model = device:model()
  local image_url = config.resolve_image_url(model)
  if image_url then
    device:set_image_url(image_url)
  end

  local layout = config.build_layout_from_device_name(model)

  local output_type = "linear"
  local led_count = 1
  local min_total_leds = 1
  local max_total_leds = 300
  local allowed_total_leds = nil
  local matrix = nil

  if layout then
    output_type = layout.segment_type or output_type
    led_count = layout.total_leds or led_count
    matrix = layout.matrix

    -- Built-in model layouts describe fixed hardware and should not be user-editable.
    min_total_leds = led_count
    max_total_leds = led_count
    allowed_total_leds = { led_count }
  end

  local editable = layout == nil

  device:add_output({
    id = "out1",
    name = "Output 1",
    type = output_type,
    size = led_count,
    matrix = matrix,
    capabilities = {
      editable = editable,
      min_total_leds = min_total_leds,
      max_total_leds = max_total_leds,
      allowed_total_leds = allowed_total_leds,
    },
  })
end

function plugin.on_tick(_dt)
  local rgb = device:get_rgb_bytes("out1")
  device:write(protocol.encode_frame(rgb))
end

function plugin.on_shutdown()
  local count = device:output_led_count("out1") or 0
  if count > 0 then
    device:write(protocol.encode_black(count))
  end
end

return plugin

