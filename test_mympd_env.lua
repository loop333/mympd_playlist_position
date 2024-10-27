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
local ret = table_str("", mympd_env)
print("mympd_env: " .. ret)

return "mympd_env: " .. ret
