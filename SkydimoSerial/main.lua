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

  local cfg = config.resolve_device_config(model)

  device:add_output({
    id = "out1",
    name = "Output 1",
    type = cfg.output_type,
    size = cfg.led_count,
    matrix = cfg.matrix,
    default_effect = cfg.default_effect,
    capabilities = {
      editable = cfg.editable,
      min_total_leds = cfg.min_total_leds,
      max_total_leds = cfg.max_total_leds,
      allowed_total_leds = cfg.allowed_total_leds,
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

