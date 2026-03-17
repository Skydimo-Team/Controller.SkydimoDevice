local M = {}

local function bytes_to_hex(bytes)
  local out = {}
  for i = 1, #bytes do
    out[i] = string.format("%02X", string.byte(bytes, i))
  end
  return table.concat(out)
end

function M.query_info()
  -- Clear any pending data before sending the query.
  pcall(function()
    device:clear_input()
  end)

  device:write("Moni-A")

  -- Read response using retries and accumulate until \r or \n is received.
  local response = ""
  local max_retries = 10
  local max_len = 63
  for _ = 1, max_retries do
    if #response >= max_len then
      break
    end

    local chunk = device:read(64, 50)
    if chunk and #chunk > 0 then
      response = response .. chunk
    end

    local n = #response
    if n >= 1 then
      local last = response:byte(n)
      local prev = n >= 2 and response:byte(n - 1) or nil
      if last == 10 or last == 13 or prev == 13 then
        break
      end
    end
  end

  if #response == 0 then
    return nil
  end

  response = response:gsub("[\r\n]+$", "")
  if #response < 6 then
    return nil
  end

  if response:sub(1, 2):upper() ~= "SK" then
    return nil
  end

  local model = response:sub(1, 6):upper()
  local serial_id = "000000"

  local comma = response:find(",", 1, true)
  if comma then
    if comma < 7 then
      return nil
    end
    local serial_bytes = response:sub(comma + 1)
    serial_id = bytes_to_hex(serial_bytes)
  end

  return {
    model = model,
    serial_id = serial_id,
  }
end

function M.encode_frame(rgb_bytes)
  local count = math.floor(#rgb_bytes / 3)
  local hi = math.floor(count / 256) % 256
  local lo = count % 256
  return string.char(0x41, 0x64, 0x61, 0x00, hi, lo) .. rgb_bytes
end

function M.encode_black(count)
  count = math.max(0, math.floor(count))
  local hi = math.floor(count / 256) % 256
  local lo = count % 256
  return string.char(0x41, 0x64, 0x61, 0x00, hi, lo) .. string.rep("\0", count * 3)
end

return M

