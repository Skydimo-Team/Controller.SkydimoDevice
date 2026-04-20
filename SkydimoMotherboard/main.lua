local protocol = require("lib.protocol")

local plugin = {}

local state = {
  initialized = false,
}

local function send_all_channels(use_black)
  for channel = 1, protocol.CHANNEL_COUNT do
    local output_id = protocol.output_id(channel)
    local led_count = protocol.clamp_led_count(device:output_led_count(output_id) or 0)
    local rgb

    if use_black then
      rgb = protocol.black_rgb_bytes(led_count)
    else
      rgb = device:get_rgb_bytes(output_id) or ""
    end

    local packets = protocol.channel_packets(channel - 1, rgb, led_count)
    for _, packet in ipairs(packets) do
      device:write(packet)
    end
  end

  device:write(protocol.FLUSH_PACKET)
end

function plugin.on_validate()
  device:set_manufacturer("Skydimo")
  device:set_model("G857D CDC os2.1")
  device:set_description("Skydimo G857D CDC os2.1 serial lighting controller")
  device:set_serial_id("")
  device:log("Serial interface matching is currently limited to VID/PID; interface-number validation is unavailable for serial candidates.")
  return true
end

function plugin.on_init()
  for channel = 1, protocol.CHANNEL_COUNT do
    device:add_output({
      id = protocol.output_id(channel),
      name = "Channel " .. tostring(channel),
      type = "linear",
      size = protocol.MAX_LEDS_PER_CHANNEL,
      capabilities = {
        editable = true,
        min_total_leds = 0,
        max_total_leds = protocol.MAX_LEDS_PER_CHANNEL,
      },
    })
  end

  state.initialized = true
end

function plugin.on_tick(_dt)
  if not state.initialized then
    return
  end

  send_all_channels(false)
end

function plugin.on_shutdown()
  if not state.initialized then
    return
  end

  send_all_channels(true)
end

return plugin
