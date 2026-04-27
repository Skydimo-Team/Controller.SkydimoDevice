--[[
  Skydimo HID Controller – Device Configuration Library

  Contains the device model database from SkydimoDeviceConfig.h,
  matrix layout builder, and image URL resolver.

  Layout types:
    Strip1       – Single linear strip
    Sides2       – Two sides (left/right) mapped onto a MATRIX (16:9 area)
    Perimeter3   – Three sides (right, top, left), bottom empty
    Perimeter4   – Four sides (right, top, left, bottom)
    MatrixSnake7 – 7×7 full matrix, serpentine row order
]]

local M = {}

local IMAGE_BASE_URL = "https://esa-dl.skydimo.com/assets/device/"

local IMAGE_SET = {
  ["SK01"] = true, ["SK02"] = true, ["SK03"] = true, ["SK04"] = true,
  ["SK0410"] = true, ["SK06"] = true, ["SK08"] = true, ["SK0802"] = true,
  ["SK09"] = true, ["SK0902"] = true, ["SK0E"] = true, ["SK0F"] = true, ["SK0H"] = true,
  ["SK0I"] = true, ["SK0J"] = true, ["SK0J01"] = true, ["SK0J02"] = true,
  ["SK0L"] = true, ["SK0M"] = true, ["SK0N03"] = true, ["SKA0"] = true,
  ["SKA1"] = true, ["SKB"] = true,
}

local IMAGE_EXTENSIONS = {
  ["SK0902"] = "png",
}

-- Default configuration for devices without a MODELS entry.
local DEFAULTS = {
  editable = true,
  default_led_count = 60,
  min_total_leds = 1,
  max_total_leds = 150,
  default_effect = "Rainbow",
}

-- Model database, matching SkydimoDeviceConfig.h
local MODELS = {
  -- 2-zone models (Sides2)
  ["SK0201"] = { layout = "Sides2",      zones = { 20, 20 },         total = 40  },
  ["SK0202"] = { layout = "Sides2",      zones = { 30, 30 },         total = 60  },
  ["SK0204"] = { layout = "Sides2",      zones = { 25, 25 },         total = 50  },
  ["SK0F01"] = { layout = "Sides2",      zones = { 29, 29 },         total = 58  },
  ["SK0F02"] = { layout = "Sides2",      zones = { 25, 25 },         total = 50  },

  -- 3-zone models (Perimeter3)
  ["SK0121"] = { layout = "Perimeter3",  zones = { 13, 25, 13 },     total = 51  },
  ["SK0124"] = { layout = "Perimeter3",  zones = { 14, 26, 14 },     total = 54  },
  ["SK0127"] = { layout = "Perimeter3",  zones = { 17, 31, 17 },     total = 65  },
  ["SK0132"] = { layout = "Perimeter3",  zones = { 20, 37, 20 },     total = 77  },
  ["SK0134"] = { layout = "Perimeter3",  zones = { 15, 41, 15 },     total = 71  },
  ["SK0149"] = { layout = "Perimeter3",  zones = { 19, 69, 19 },     total = 107 },

  -- 4-zone models (Perimeter4)
  ["SK0L21"] = { layout = "Perimeter4",  zones = { 13, 25, 13, 25 }, total = 76  },
  ["SK0L24"] = { layout = "Perimeter4",  zones = { 14, 26, 14, 26 }, total = 80  },
  ["SK0L27"] = { layout = "Perimeter4",  zones = { 17, 31, 17, 31 }, total = 96  },
  ["SK0L32"] = { layout = "Perimeter4",  zones = { 20, 37, 20, 37 }, total = 114 },
  ["SK0L34"] = { layout = "Perimeter4",  zones = { 15, 41, 15, 41 }, total = 112 },

  -- SKB series (Perimeter4)
  ["SKB124"] = { layout = "Perimeter4",  zones = { 18, 34, 18, 34 }, total = 104 },
  ["SKB127"] = { layout = "Perimeter4",  zones = { 20, 41, 20, 41 }, total = 122 },
  ["SKB132"] = { layout = "Perimeter4",  zones = { 25, 44, 25, 44 }, total = 138 },
  ["SKB134"] = { layout = "Perimeter4",  zones = { 21, 50, 21, 50 }, total = 142 },

  -- SKA series (Perimeter3)
  ["SKA124"] = { layout = "Perimeter3",  zones = { 18, 34, 18 },     total = 70  },
  ["SKA127"] = { layout = "Perimeter3",  zones = { 20, 41, 20 },     total = 81  },
  ["SKA132"] = { layout = "Perimeter3",  zones = { 25, 45, 25 },     total = 95  },
  ["SKA134"] = { layout = "Perimeter3",  zones = { 21, 51, 21 },     total = 93  },

  -- Single-zone strip models (Strip1)
  ["SK0402"] = { layout = "Strip1",      zones = { 72 },             total = 72   },
  ["SK0403"] = { layout = "Strip1",      zones = { 96 },             total = 96   },
  ["SK0404"] = { layout = "Strip1",      zones = { 144 },            total = 144  },
  ["SK0901"] = { layout = "Strip1",      zones = { 14 },             total = 14   },
  ["SK0801"] = { layout = "Strip1",      zones = { 2 },              total = 2    },
  ["SK0802"] = { layout = "Strip1",      zones = { 18 },             total = 18   },
  ["SK0803"] = { layout = "Strip1",      zones = { 10 },             total = 10   },
  ["SK0E01"] = { layout = "Strip1",      zones = { 16 },             total = 16   },
  ["SK0H01"] = { layout = "Strip1",      zones = { 2 },              total = 2    },
  ["SK0H02"] = { layout = "Strip1",      zones = { 4 },              total = 4    },
  ["SK0S01"] = { layout = "Strip1",      zones = { 32 },             total = 32   },
  ["SK0K01"] = { layout = "Strip1",      zones = { 120 },            total = 120  },
  ["SK0K02"] = { layout = "Strip1",      zones = { 15 },             total = 15   },
  ["SK0M01"] = { layout = "Strip1",      zones = { 24 },             total = 24   },
  ["SK0N01"] = { layout = "Strip1",      zones = { 256 },            total = 256  },
  ["SK0N02"] = { layout = "Strip1",      zones = { 1024 },           total = 1024 },
  ["SK0N03"] = { layout = "Strip1",      zones = { 253 },            total = 253  },

  -- Matrix models
  ["SK0902"] = { layout = "MatrixSnake7", zones = { 49 },            total = 49   },
  ["SK0N07"] = { layout = "MatrixSnake7", zones = { 49 },            total = 49   },

  -- Editable devices with custom limits
  ["SK0410"] = { max_total_leds = 300 },
}

-- ============================================================================
-- Helpers
-- ============================================================================

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Extract model ID from a device name like "Skydimo SK0127".
local function extract_model_from_device_name(device_name)
  local prefix = "Skydimo "
  local pos = device_name:find(prefix, 1, true)
  if not pos then
    return nil
  end
  local start = pos + #prefix
  if start > #device_name then
    return nil
  end
  return device_name:sub(start)
end

local function lookup_model(device_name)
  local model_id = extract_model_from_device_name(device_name)
  if model_id then
    local key = trim(model_id):upper()
    if MODELS[key] then
      return MODELS[key]
    end
  end
  local key = trim(device_name):upper()
  return MODELS[key]
end

-- ============================================================================
-- Image URL resolution
-- ============================================================================

--- Resolve the best-matching image URL for a device model.
--- @param device_name string The full device name (e.g. "Skydimo SK0127").
--- @return string|nil url The image URL or nil if unknown.
function M.resolve_image_url(device_name)
  local model_id = extract_model_from_device_name(device_name)
  if not model_id then
    model_id = device_name
  end
  model_id = trim(model_id):upper()

  -- Longest-prefix match against known image set
  for len = #model_id, 1, -1 do
    local prefix = model_id:sub(1, len)
    if IMAGE_SET[prefix] then
      local extension = IMAGE_EXTENSIONS[prefix] or "jpg"
      return IMAGE_BASE_URL .. prefix .. "." .. extension
    end
  end

  return nil
end

-- ============================================================================
-- Matrix layout builder
-- ============================================================================

--- Build a matrix map from a model config.
--- Implements the same mapping logic as BuildSkydimoMatrixZone in SkydimoDeviceConfig.h.
--- @param cfg table Model config entry from MODELS table.
--- @return table|nil layout { total_leds, segment_type, matrix? }
local function build_matrix_for_config(cfg)
  local zones = cfg.zones or {}
  local z1 = zones[1] or 0
  local z2 = zones[2] or 0
  local z3 = zones[3] or 0
  local z4 = zones[4] or 0

  local total_leds = cfg.total or 0

  if cfg.layout == "Strip1" then
    return { total_leds = total_leds, segment_type = "linear", matrix = nil }
  end

  if cfg.layout == "MatrixSnake7" then
    -- 7×7 serpentine matrix
    local height = 7
    local width = 7
    local cell_count = height * width
    local map = {}
    local idx = 0

    for y = 0, height - 1 do
      if (y % 2) == 0 then
        -- Even row: left → right
        for x = 0, width - 1 do
          map[y * width + x + 1] = idx
          idx = idx + 1
        end
      else
        -- Odd row: right → left
        for x = width - 1, 0, -1 do
          map[y * width + x + 1] = idx
          idx = idx + 1
        end
      end
    end

    return {
      total_leds   = total_leds,
      segment_type = "matrix",
      matrix       = { width = width, height = height, map = map },
    }
  end

  -- Compute matrix dimensions
  local height, width

  if cfg.layout == "Perimeter4" then
    height = math.max(z1, z3) + 2
    width  = math.max(z2, z4) + 2
  elseif cfg.layout == "Perimeter3" then
    height = math.max(z1, z3) + 1
    width  = z2 + 2
  elseif cfg.layout == "Sides2" then
    height = math.max(z1, z2) + 2
    local w_f = math.floor((16 / 9) * height + 0.5)
    if w_f < 3 then
      w_f = 3
    end
    width = w_f
  else
    return nil
  end

  local cell_count = height * width
  local map = {}
  for i = 1, cell_count do
    map[i] = -1 -- NA (empty cell)
  end

  local idx = 0
  local function set_cell(y, x)
    if y < 0 or x < 0 or y >= height or x >= width then
      return
    end
    map[y * width + x + 1] = idx
    idx = idx + 1
  end

  -- Z1 mapping
  if cfg.layout == "Sides2" then
    -- Left side: bottom → top (skip corners)
    local placed = 0
    local y = height - 2
    while placed < z1 and y >= 1 do
      set_cell(y, 0)
      placed = placed + 1
      y = y - 1
    end
  else
    -- Right side: bottom → top (skip corners)
    local start_y = (cfg.layout == "Perimeter3") and (height - 1) or (height - 2)
    local placed = 0
    local y = start_y
    while placed < z1 and y >= 1 do
      set_cell(y, width - 1)
      placed = placed + 1
      y = y - 1
    end
  end

  -- Z2 mapping
  if cfg.layout == "Perimeter3" or cfg.layout == "Perimeter4" then
    -- Top row: right → left (skip corners)
    local placed = 0
    local x = width - 2
    while placed < z2 and x >= 1 do
      set_cell(0, x)
      placed = placed + 1
      x = x - 1
    end
  elseif cfg.layout == "Sides2" then
    -- Right side: top → bottom (skip corners)
    local placed = 0
    local y = 1
    while placed < z2 and y <= (height - 2) do
      set_cell(y, width - 1)
      placed = placed + 1
      y = y + 1
    end
  end

  -- Z3: left side, top → bottom (skip corners)
  do
    local end_y = (cfg.layout == "Perimeter3") and (height - 1) or (height - 2)
    local placed = 0
    local y = 1
    while placed < z3 and y <= end_y do
      set_cell(y, 0)
      placed = placed + 1
      y = y + 1
    end
  end

  -- Z4: bottom row, left → right (skip corners) — only Perimeter4
  if cfg.layout == "Perimeter4" then
    local placed = 0
    local x = 1
    while placed < z4 and x <= (width - 2) do
      set_cell(height - 1, x)
      placed = placed + 1
      x = x + 1
    end
  end

  return {
    total_leds   = total_leds,
    segment_type = "matrix",
    matrix       = { width = width, height = height, map = map },
  }
end

--- Build a layout description from a device name.
--- @param device_name string Full device name (e.g. "Skydimo SK0127").
--- @return table|nil layout { total_leds, segment_type, matrix? } or nil for unknown.
function M.build_layout_from_device_name(device_name)
  local entry = lookup_model(device_name)
  if entry and entry.layout then
    return build_matrix_for_config(entry)
  end
  return nil
end

--- Resolve full device configuration from a device name.
--- Returns a unified config table (same structure as SkydimoSerial).
--- @param device_name string Full device name (e.g. "Skydimo SK0127").
--- @return table config { output_type, led_count, matrix, editable, min/max_total_leds, allowed_total_leds, default_effect }
function M.resolve_device_config(device_name)
  local entry = lookup_model(device_name)

  -- Fixed layout device
  if entry and entry.layout then
    local layout = build_matrix_for_config(entry)
    if layout then
      return {
        output_type = layout.segment_type,
        led_count = layout.total_leds,
        matrix = layout.matrix,
        editable = false,
        min_total_leds = layout.total_leds,
        max_total_leds = layout.total_leds,
        allowed_total_leds = { layout.total_leds },
        default_effect = (entry and entry.default_effect) or DEFAULTS.default_effect,
      }
    end
  end

  -- Editable device (per-model overrides merged onto defaults)
  local editable = DEFAULTS.editable
  if entry and entry.editable ~= nil then
    editable = entry.editable
  end

  return {
    output_type = "linear",
    led_count = DEFAULTS.default_led_count,
    matrix = nil,
    editable = editable,
    min_total_leds = (entry and entry.min_total_leds) or DEFAULTS.min_total_leds,
    max_total_leds = (entry and entry.max_total_leds) or DEFAULTS.max_total_leds,
    allowed_total_leds = entry and entry.allowed_total_leds or nil,
    default_effect = (entry and entry.default_effect) or DEFAULTS.default_effect,
  }
end

return M
