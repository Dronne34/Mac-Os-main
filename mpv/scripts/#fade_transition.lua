-- fade_transition.lua
local mp = require("mp")
local fade_duration = 5 -- durata fade in/out in secunde
local fade_start_before_end = 15 -- cu cate secunde inainte de final sa inceapa fade out
local target_volume = 100
local steps = 20

local fade_timer = nil
local volume_timer = nil

local function fade_out()
	if volume_timer then
		volume_timer:kill()
	end

	local vol = mp.get_property_number("volume", target_volume)
	local step = vol / steps
	local interval = fade_duration / steps

	volume_timer = mp.add_periodic_timer(interval, function()
		vol = vol - step
		if vol <= 0 then
			vol = 0
			volume_timer:kill()
		end
		mp.set_property_number("volume", vol)
	end)
end

local function fade_in()
	if volume_timer then
		volume_timer:kill()
	end

	local vol = 0
	mp.set_property_number("volume", vol)
	local step = target_volume / steps
	local interval = fade_duration / steps

	volume_timer = mp.add_periodic_timer(interval, function()
		vol = vol + step
		if vol >= target_volume then
			vol = target_volume
			volume_timer:kill()
		end
		mp.set_property_number("volume", vol)
	end)
end

local function on_file_loaded()
	fade_in()

	if fade_timer then
		fade_timer:kill()
		fade_timer = nil
	end

	local function setup_fade_out(name, duration)
		if duration and duration > fade_start_before_end then
			fade_timer = mp.add_timeout(duration - fade_start_before_end, fade_out)
			mp.unobserve_property(setup_fade_out)
		end
	end

	-- folosim observer pentru a aștepta durata corectă
	mp.observe_property("duration", "number", setup_fade_out)
end

mp.register_event("file-loaded", on_file_loaded)
