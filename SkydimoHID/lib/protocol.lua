--[[
  Skydimo HID Controller – Protocol Library

  HID communication protocol for Skydimo LED strips (VID 0x1A86, PID 0xE316).

  Packet format:
    RGB:  [CMD=0x01] [OFFSET_LO] [OFFSET_HI] [GRB_DATA... (60 bytes)] [CRC8]
    End:  [CMD=0x01] [0xFF] [0xFF] [TOTAL_LO] [TOTAL_HI] [0x00 padding...] [CRC8]

  - RGB data is sent in GRB byte order.
  - Data is sent in batches of 20 LEDs (60 bytes of GRB).
  - CRC8 uses the MAXIM polynomial (0x07).

  Reference: SkydimoHIDController.cpp
]]

local protocol = {}

-- Protocol constants
local CMD_BYTE      = 0x01
local MAX_RGB_BYTES = 60    -- max RGB bytes per HID report
local BATCH_LEDS    = 20    -- LEDs per batch
local CRC8_POLY     = 0x07

-- ============================================================================
-- CRC8 (MAXIM polynomial 0x07)
-- ============================================================================

--- Calculate CRC8-MAXIM checksum over a byte string.
--- @param data string The data bytes to checksum.
--- @return number crc The 8-bit CRC value.
function protocol.crc8(data)
  local crc = 0x00
  for i = 1, #data do
    crc = crc ~ data:byte(i)
    for _ = 1, 8 do
      if (crc & 0x80) ~= 0 then
        crc = ((crc << 1) & 0xFF) ~ CRC8_POLY
      else
        crc = (crc << 1) & 0xFF
      end
    end
  end
  return crc & 0xFF
end

-- ============================================================================
-- Packet builders
-- ============================================================================

--- Build a single RGB data packet (batch of up to 20 LEDs).
--- @param grb_data string GRB byte data (up to 60 bytes).
--- @param offset number The starting LED offset.
--- @return string packet The complete HID report to write.
function protocol.build_rgb_packet(grb_data, offset)
  local header = string.char(
    CMD_BYTE,
    offset & 0xFF,
    (offset >> 8) & 0xFF
  )

  -- Pad grb_data to exactly MAX_RGB_BYTES
  local padded = grb_data
  if #padded < MAX_RGB_BYTES then
    padded = padded .. string.rep("\0", MAX_RGB_BYTES - #padded)
  elseif #padded > MAX_RGB_BYTES then
    padded = padded:sub(1, MAX_RGB_BYTES)
  end

  local payload = header .. padded
  local crc = protocol.crc8(payload)
  return payload .. string.char(crc)
end

--- Build the end-of-frame command packet.
--- @param total_leds number Total number of LEDs sent.
--- @return string packet The complete HID end report to write.
function protocol.build_end_packet(total_leds)
  local header = string.char(
    CMD_BYTE,
    0xFF,
    0xFF,
    total_leds & 0xFF,
    (total_leds >> 8) & 0xFF
  )

  local payload = header .. string.rep("\0", MAX_RGB_BYTES - #header)
  local crc = protocol.crc8(payload)
  return payload .. string.char(crc)
end

-- ============================================================================
-- Color conversion
-- ============================================================================

--- Convert an RGB byte string to GRB byte string.
--- @param rgb string RGB byte string (3 bytes per LED: R G B).
--- @return string grb GRB byte string.
function protocol.rgb_to_grb(rgb)
  local led_count = math.floor(#rgb / 3)
  if led_count <= 0 then
    return ""
  end

  local parts = {}
  for i = 0, led_count - 1 do
    local base = i * 3
    local r = rgb:byte(base + 1) or 0
    local g = rgb:byte(base + 2) or 0
    local b = rgb:byte(base + 3) or 0
    parts[#parts + 1] = string.char(g, r, b) -- GRB order
  end

  return table.concat(parts)
end

-- ============================================================================
-- Frame sending
-- ============================================================================

--- Send a complete LED frame to the device.
--- Converts RGB to GRB, splits into batches, and sends the end command.
--- @param rgb string RGB byte string from the host (3 bytes per LED).
function protocol.send_frame(rgb)
  local grb = protocol.rgb_to_grb(rgb)
  local led_count = math.floor(#grb / 3)
  if led_count <= 0 then
    return
  end

  -- Send in batches of BATCH_LEDS
  for idx = 0, led_count - 1, BATCH_LEDS do
    local batch_start = idx * 3 + 1
    local batch_size = math.min(BATCH_LEDS, led_count - idx)
    local batch_data = grb:sub(batch_start, batch_start + batch_size * 3 - 1)
    local pkt = protocol.build_rgb_packet(batch_data, idx)
    device:write(pkt)
  end

  -- Send end command
  device:write(protocol.build_end_packet(led_count))
end

--- Send an all-black frame (turn off LEDs).
--- @param led_count number Number of LEDs.
function protocol.send_black(led_count)
  local black_rgb = string.rep("\0", led_count * 3)
  protocol.send_frame(black_rgb)
end

return protocol
