local protocol = {}

protocol.CHANNEL_COUNT = 8
protocol.MAX_LEDS_PER_CHANNEL = 126
protocol.LEDS_PER_PACKET = 21
protocol.BYTES_PER_LED = 3
protocol.PAYLOAD_BYTES_PER_PACKET = protocol.LEDS_PER_PACKET * protocol.BYTES_PER_LED
protocol.PACKETS_PER_CHANNEL = math.ceil(protocol.MAX_LEDS_PER_CHANNEL / protocol.LEDS_PER_PACKET)

local ZERO_PAYLOAD = string.rep(string.char(0), protocol.PAYLOAD_BYTES_PER_PACKET)
protocol.FLUSH_PACKET = string.char(0xFF) .. string.rep(string.char(0), 63)

function protocol.output_id(channel)
  return "ch" .. tostring(channel)
end

function protocol.clamp_led_count(count)
  count = math.floor(tonumber(count) or 0)
  if count < 0 then
    return 0
  end
  if count > protocol.MAX_LEDS_PER_CHANNEL then
    return protocol.MAX_LEDS_PER_CHANNEL
  end
  return count
end

function protocol.black_rgb_bytes(led_count)
  return string.rep(string.char(0, 0, 0), protocol.clamp_led_count(led_count))
end

local function rgb_to_grb_bytes(rgb, led_count)
  local out = {}
  led_count = protocol.clamp_led_count(led_count)

  for led = 1, led_count do
    local offset = (led - 1) * 3
    local r = rgb:byte(offset + 1) or 0
    local g = rgb:byte(offset + 2) or 0
    local b = rgb:byte(offset + 3) or 0
    out[#out + 1] = string.char(g, r, b)
  end

  return table.concat(out)
end

-- Returns a list of individual 64-byte packets for one channel (mirrors JS SendChannel).
function protocol.channel_packets(channel_index, rgb, led_count)
  led_count = protocol.clamp_led_count(led_count)
  if led_count <= 0 then
    return {}
  end

  local grb = rgb_to_grb_bytes(rgb or "", led_count)
  local packet_count = math.ceil(led_count / protocol.LEDS_PER_PACKET)
  local packets = {}
  local payload_offset = 1

  for packet_index = 0, packet_count - 1 do
    local block_index = packet_index + channel_index * protocol.PACKETS_PER_CHANNEL
    local chunk = grb:sub(payload_offset, payload_offset + protocol.PAYLOAD_BYTES_PER_PACKET - 1)
    payload_offset = payload_offset + protocol.PAYLOAD_BYTES_PER_PACKET

    local padding = protocol.PAYLOAD_BYTES_PER_PACKET - #chunk
    if padding > 0 then
      chunk = chunk .. ZERO_PAYLOAD:sub(1, padding)
    end

    packets[#packets + 1] = string.char(block_index) .. chunk
  end

  return packets
end

return protocol
