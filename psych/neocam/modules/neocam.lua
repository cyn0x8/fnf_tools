--[[ neocam ]]

luaDebugMode = true

local override
override = function(a, b)
	for k, v in pairs(b) do
		a[k] = (type(v) == "table" and type(a[k]) == "table") and override(a[k], v) or v
	end
	
	return a
end

local ret = {
	enable = function()
		nc_enable({})
	end,
	
	disable = function()
		nc_disable({})
	end,
	
	set_target = function(tag, target)
		nc_set_target({tag, target})
	end,
	
	override_target = function(tag, target)
		nc_override_target({tag, target})
	end,
	
	remove_target = function(tag)
		nc_remove_target({tag})
	end,
	
	snap_target = function(tag, lock)
		nc_snap_target({tag, lock})
	end,
	
	focus = function(tag, override_target, lock)
		nc_focus({tag, override_target, lock})
	end,
	
	set_note_offset = function(val)
		nc_set_note_offset({val})
	end
}

do
	local function setup_cam(name)
		local function setup_callbacks(tag)
			return {
				set_cur = function(val)
					_G[tag .. "set_cur"]({val})
				end,
				
				get_cur = function()
					return _G[tag .. "get_cur"]({})
				end,
				
				set_lerpto = function(val)
					_G[tag .. "set_lerpto"]({val})
				end,
				
				get_lerpto = function()
					return _G[tag .. "get_lerpto"]({})
				end,
				
				set_speed = function(val)
					_G[tag .. "set_speed"]({val})
				end,
				
				get_speed = function()
					return _G[tag .. "get_speed"]({})
				end,
				
				set_locked = function(val)
					_G[tag .. "set_locked"]({val})
				end,
				
				get_locked = function()
					return _G[tag .. "get_locked"]({})
				end,
				
				set_fps = function(val)
					_G[tag .. "set_fps"]({val})
				end,
				
				get_fps = function()
					return _G[tag .. "get_fps"]({})
				end,
				
				snap = function(val)
					_G[tag .. "snap"]({val})
				end,
				
				tween = function(start, goal, duration, ease)
					_G[tag .. "tween"]({start, goal, duration, ease})
				end
			}
		end
		
		local function movable_vec(prop)
			local tag = "nc_" .. name .. "_" .. prop .. "_"
			return override(setup_callbacks(tag), {
				x = override(setup_callbacks(tag .. "x_"), {
					shake = setup_callbacks(tag .. "x_shake_")
				}),
				
				y = override(setup_callbacks(tag .. "y_"), {
					shake = setup_callbacks(tag .. "y_shake_")
				}),
				
				shake = {
					x = setup_callbacks(tag .. "x_shake_"),
					y = setup_callbacks(tag .. "y_shake_")
				}
			})
		end
		
		local function movable(prop)
			local tag = "nc_" .. name .. "_" .. prop .. "_"
			return override(setup_callbacks(tag), {
				shake = setup_callbacks(tag .. "shake_")
			})
		end
		
		local tag = "nc_" .. name .. "_"
		return {
			pos = movable_vec("pos"),
			zoom = movable("zoom"),
			angle = movable("angle"),
			
			set_bump_pattern = function(pattern, section_offset)
				_G[tag .. "set_bump_pattern"]({pattern, section_offset})
			end,
			
			bump = function(amount)
				_G[tag .. "bump"]({amount})
			end,
			
			shaders = {
				create = function(shader_tag, shader_name)
					_G[tag .. "shaders_create"]({shader_tag, shader_name})
				end,
				
				set = function(shader_tags)
					_G[tag .. "shaders_set"]({shader_tags})
				end,
				
				add = function(shader_tags)
					_G[tag .. "shaders_add"]({shader_tags})
				end,
				
				remove = function(shader_tags)
					_G[tag .. "shaders_remove"]({shader_tags})
				end,
				
				set_uniform = function(shader_tag, uniform, val, uniform_type)
					_G[tag .. "shaders_set_uniform"]({shader_tag, uniform, val, uniform_type})
				end,
				
				get_uniform = function(shader_tag, uniform)
					return _G[tag .. "shaders_get_uniform"]({shader_tag, uniform})
				end
			}
		}
	end
	
	override(ret, {
		game = setup_cam("game"),
		
		hud = setup_cam("hud")
	})
end

return ret