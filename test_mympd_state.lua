-- {"order":1,"file":"","version":0,"arguments":[]}
local function table_str(offset, data)
  local ret = ""
  for k, v in pairs(data) do
    if type(v) == "boolean" then
      v = tostring(v)
    end
    if type(v) == "table" then
      v = table_str(offset .. "  ", v)
    end
    ret = ret .. offset .. "  " .. k .. ": " .. v .. ",\n"
  end

  return "{\n" .. ret .. offset .. "}"
end

-- main
mympd.init()
local ret = table_str("", mympd_state)
print("mympd_state: " .. ret)

return "mympd_state: " .. ret
