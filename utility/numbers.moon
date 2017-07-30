resty_random = require "resty.random"

-- 0 to 4294967296
random_number = ->
  -- a, b, c, d = string.byte resty_random.bytes(4), 1, 2, 3, 4
  -- return a + b * 256 + c * 65536 + d * 16777216
    a, b = string.byte resty_random.bytes(2), 1, 2
    return a + b * 256

{
  :random_number
}
