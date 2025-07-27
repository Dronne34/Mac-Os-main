-- rock_eq_toggle.lua
local mp = require("mp")

local eq_enabled = false
local eq_filter = table.concat({
	"equalizer=f=32:width_type=h:width=50:g=6", -- redus de la 10
	"equalizer=f=64:width_type=h:width=50:g=4", -- redus de la 8
	"equalizer=f=125:width_type=h:width=50:g=3", -- redus de la 6
	"equalizer=f=250:width_type=h:width=50:g=1", -- redus de la 3
	"equalizer=f=500:width_type=h:width=100:g=-1",
	"equalizer=f=1000:width_type=h:width=100:g=-2",
	"equalizer=f=2000:width_type=h:width=200:g=1",
	"equalizer=f=4000:width_type=h:width=400:g=5",
	"equalizer=f=8000:width_type=h:width=800:g=7",
	"equalizer=f=16000:width_type=h:width=2000:g=9",
}, ",")

local function toggle_rock_eq()
	if eq_enabled then
		mp.set_property("af", "")
		mp.osd_message("🎸 EQ Rock Oprit")
		eq_enabled = false
	else
		mp.commandv("af", "add", "lavfi=[" .. eq_filter .. "]")
		mp.osd_message("🎸 EQ Rock Activat")
		eq_enabled = true
	end
end

mp.add_key_binding("b", "toggle_rock_eq", toggle_rock_eq)
