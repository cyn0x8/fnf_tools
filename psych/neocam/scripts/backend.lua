--[[ neocam ]]

luaDebugMode = true

local function is_table(t)
	return type(t) == "table"
end

local override
override = function(a, b)
	for k, v in pairs(b) do
		a[k] = (is_table(v) and is_table(a[k])) and override(a[k], v) or v
	end
	
	return a
end

local copy
copy = function(t)
	local ret = {}
	for k, v in pairs(t) do
		ret[k] = is_table(v) and copy(v) or v
	end
	
	return ret
end

local function nospace(str)
	return str:gsub(" ", "")
end

local inf = math.huge

local sqrt = math.sqrt
local exp = math.exp

local sin = math.sin
local cos = math.cos

local min = math.min
local max = math.max

local floor = math.floor
local ceil = math.ceil

local pi = math.pi
local rad = math.rad

local function fract(x)
	return x - floor(x)
end

local function lerp(a, b, t)
	return a + t * (b - a)
end

local function clamp(x, a, b)
	return min(max(x, a), b)
end

local function rand(r)
	return getRandomFloat(-r, r)
end

local diagonal = sqrt(1280 ^ 2 + 720 ^ 2) / 720

local function bounce(t)
	t = t ^ 2 * 3.5 + 0.5
	
	return 1 - (1 - (2 * fract(t) - 1) ^ 2) / ceil(t) ^ 2.5
end

local tween = {
	eases = {
		linear = function(t)
			return t
		end,
		
		quadin = function(t)
			return t ^ 2
		end,
		
		quadout = function(t)
			return 1 - (1 - t) ^ 2
		end,
		
		quadinout = function(t)
			if t < 0.5 then
				return 2 * t ^ 2
			else
				return 1 - 2 * (t - 1) ^ 2
			end
		end,
		
		cubein = function(t)
			return t ^ 3
		end,
		
		cubeout = function(t)
			return 1 + (t - 1) ^ 3
		end,
		
		cubeinout = function(t)
			if t < 0.5 then
				return 4 * t ^ 3
			else
				return 1 + 4 * (t - 1) ^ 3
			end
		end,
		
		quartin = function(t)
			return t ^ 4
		end,
		
		quartout = function(t)
			return 1 - (t - 1) ^ 4
		end,
		
		quartinout = function(t)
			if t < 0.5 then
				return 8 * t ^ 4
			else
				return 1 - 8 * (t - 1) ^ 4
			end
		end,
		
		quintin = function(t)
			return t ^ 5
		end,
		
		quintout = function(t)
			return 1 + (t - 1) ^ 5
		end,
		
		quintinout = function(t)
			if t < 0.5 then
				return 16 * t ^ 5
			else
				return 1 + 16 * (t - 1) ^ 5
			end
		end,
		
		smoothstepin = function(t)
			return (t + 1) ^ 2 * (2 - t) / 2 + 1
		end,
		
		smoothstepout = function(t)
			return t ^ 2 * (3 - t) / 2
		end,
		
		smoothstepinout = function(t)
			return t ^ 2 * (3 - 2 * t)
		end,
		
		sinein = function(t)
			return 1 - cos(t * pi / 2)
		end,
		
		sineout = function(t)
			return sin(t * pi / 2)
		end,
		
		sineinout = function(t)
			return (1 - cos(t * pi)) / 2
		end,
		
		bouncein = function(t)
			return 1 - bounce(1 - t)
		end,
		
		bounceout = function(t)
			return bounce(t)
		end,
		
		bounceinout = function(t)
			if t < 0.5 then
				return (1 - bounce(1 - 2 * t)) / 2
			else
				return (bounce(2 * t - 1) + 1) / 2
			end
		end,
		
		circin = function(t)
			return 1 - sqrt(1 - t ^ 2)
		end,
		
		circout = function(t)
			return sqrt(1 - (t - 1) ^ 2)
		end,
		
		circinout = function(t)
			if t < 0.5 then
				return (1 - sqrt(1 - 4 * t ^ 2)) / 2
			else
				return (1 + sqrt(1 - 4 * (1 - t) ^ 2)) / 2
			end
		end,
		
		expoin = function(t)
			return t * 2 ^ (8 * (t - 1))
		end,
		
		expoout = function(t)
			return 1 + (t - 1) / 2 ^ (8 * t)
		end,
		
		expoinout = function(t)
			if t < 0.5 then
				return t * 2 ^ (8 * (2 * t - 1))
			else
				return 1 - (1 - t) * 2 ^ (8 * (1 - 2 * t))
			end
		end,
		
		backin = function(t)
			return 3 * t ^ 3 - 2 * t ^ 2
		end,
		
		backout = function(t)
			return 1 - 3 * (1 - t) ^ 3 + 2 * (1 - t) ^ 2
		end,
		
		backinout = function(t)
			if t < 0.5 then
				return 4 * (3 * t ^ 3 - t ^ 2)
			else
				return 1 - 4 * (3 * (1 - t) ^ 3 + (1 - t) ^ 2)
			end
		end,
		
		elasticin = function(t)
			return 1 - (1 - t) ^ 5 * cos(5 * pi * t)
		end,
		
		elasticout = function(t)
			return t ^ 5 * cos(5 * pi * (t - 1))
		end,
		
		elasticinout = function(t)
			if t < 0.5 then
				return 16 * t ^ 5 * cos(5 * pi * (2 * t - 1))
			else
				return 1 - ((2 * (1 - t)) ^ 5 * cos(5 * pi * (1 - 2 * t))) / 2
			end
		end
	},
	
	active = {},
	
	get = function(lib, tag)
		return lib.active[tag] and lib.active[tag].cur
	end,
	
	new = function(lib, tag, start, goal, duration, ease)
		start = tonumber(start)
		if not start then
			return
		end
		
		goal = tonumber(goal) or 0
		
		duration = max(tonumber(duration) or 0, 0)
		
		if type(ease) ~= "function" then
			ease = lib.eases[nospace(tostring(ease)):lower()] or lib.eases.linear
		end
		
		lib.active[tag] = {
			cur = start,
			elapsed = 0,
			
			start = start,
			goal = goal,
			
			duration = duration,
			ease = ease,
			
			completed = false
		}
	end,
		
	update = function(lib, elapsed)
		for tag, data in pairs(lib.active) do
			if data.completed then
				lib.active[tag] = nil
				return
			end
			
			data.elapsed = data.elapsed + elapsed
			if data.elapsed >= data.duration then
				data.cur = data.goal
				
				data.completed = true
			else
				data.cur = lerp(data.start, data.goal, tonumber(data.ease(data.elapsed / data.duration)) or 0)
			end
		end
	end
}

local movable = {
	unit = {
		cur = 0,
		
		set_cur = function(self, val)
			if self.locked then
				return
			end
			
			self.cur = tonumber(val) or 0
		end,
		
		get_cur = function(self)
			return self.cur
		end,
		
		lerpto = 0,
		
		set_lerpto = function(self, val)
			if self.locked then
				return
			end
			
			self.lerpto = tonumber(val) or 0
		end,
		
		get_lerpto = function(self)
			return self.lerpto
		end,
		
		speed = 0,
		
		set_speed = function(self, val)
			if self.locked then
				return
			end
			
			self.speed = tonumber(val) or 0
		end,
		
		get_speed = function(self)
			return self.speed
		end,
		
		locked = false,
		
		set_locked = function(self, val)
			self.locked = type(val) == "boolean" and val or false
		end,
		
		get_locked = function(self)
			return self.locked
		end,
		
		applied = 0,
		fps = inf,
		mod = 0,
		
		set_fps = function(self, val)
			if self.locked then
				return
			end
			
			self.fps = tonumber(val) or inf
		end,
		
		get_fps = function(self)
			return self.fps
		end,
		
		snap = function(self, val)
			self:set_cur(val)
			self:set_lerpto(val)
		end,
		
		tween = function(self, start, goal, duration, ease)
			if self.locked then
				return
			end
			
			tween:new(self.tag, start or self.lerpto, goal, duration, ease)
		end,
		
		update = function(self, elapsed)
			if self.locked then
				return
			end
			
			local data = tween:get(self.tag)
			if data then
				self.lerpto = data
			end
			
			self.cur = lerp(self.lerpto, self.cur, exp(-elapsed * self.speed))
			
			self.mod = self.mod + elapsed
			if self.mod >= 1 / self.fps then
				self.mod = 0
				
				self.applied = self.cur
			end
		end
	},
	
	new = function(lib, tag, init, speed)
		if is_table(init) then
			local ret = {
				x = override(copy(lib.unit), {
					tag = tag .. "_x",
					
					cur = init.x,
					lerpto = init.x,
					
					speed = speed
				}),
				
				y = override(copy(lib.unit), {
					tag = tag .. "_y",
					
					cur = init.y,
					lerpto = init.y,
					
					speed = speed
				}),
				
				set_cur = function(self, val)
					if not is_table(val) then
						val = {x = val, y = val}
					end
					
					self.x:set_cur(val.x)
					self.y:set_cur(val.y)
				end,
				
				get_cur = function(self)
					return {
						x = self.x:get_cur(),
						y = self.y:get_cur()
					}
				end,
				
				set_lerpto = function(self, val)
					if not is_table(val) then
						val = {x = val, y = val}
					end
					
					self.x:set_lerpto(val.x)
					self.y:set_lerpto(val.y)
				end,
				
				get_lerpto = function(self)
					return {
						x = self.x:get_lerpto(),
						y = self.y:get_lerpto()
					}
				end,
				
				set_speed = function(self, val)
					if not is_table(val) then
						val = {x = val, y = val}
					end
					
					self.x:set_speed(val.x)
					self.y:set_speed(val.y)
				end,
				
				get_speed = function(self)
					return {
						x = self.x:get_speed(),
						y = self.y:get_speed()
					}
				end,
				
				set_locked = function(self, val)
					if not is_table(val) then
						val = {x = val, y = val}
					end
					
					self.x:set_locked(val.x)
					self.y:set_locked(val.y)
				end,
				
				get_locked = function(self)
					return {
						x = self.x:get_locked(),
						y = self.y:get_locked()
					}
				end,
				
				set_fps = function(self, val)
					if not is_table(val) then
						val = {x = val, y = val}
					end
					
					self.x:set_fps(val.x)
					self.y:set_fps(val.y)
				end,
				
				get_fps = function(self)
					return {
						x = self.x:get_fps(),
						y = self.y:get_fps()
					}
				end,
				
				snap = function(self, val)
					if not is_table(val) then
						val = {x = val, y = val}
					end
					
					self.x:snap(val.x)
					self.y:snap(val.y)
				end,
				
				tween = function(self, start, goal, duration, ease)
					if not is_table(start) then
						start = {x = start, y = start}
					end
					
					if not is_table(goal) then
						goal = {x = goal, y = goal}
					end
					
					self.x:tween(start.x, goal.x, duration, ease)
					self.y:tween(start.y, goal.y, duration, ease)
				end,
				
				update = function(self, elapsed)
					self.x:update(elapsed)
					self.y:update(elapsed)
				end
			}
			
			override(ret, {
				shake = override(copy(ret), {
					x = override(copy(ret.x), {
						tag = tag .. "_shake_x",
						
						speed = 10,
						
						update = function(self, elapsed)
							if self.locked then
								return
							end
							
							local data = tween:get(self.tag)
							if data then
								self.lerpto = data
							end
							
							self.cur = lerp(self.lerpto, self.cur, exp(-elapsed * self.speed))
							
							self.mod = self.mod + elapsed
							if self.mod >= 1 / self.fps then
								self.mod = 0
								
								self.applied = rand(self.cur)
							end
						end
					}),
					
					y = override(copy(ret.y), {
						tag = tag .. "_shake_y",
						
						speed = 10,
						
						update = function(self, elapsed)
							if self.locked then
								return
							end
							
							local data = tween:get(self.tag)
							if data then
								self.lerpto = data
							end
							
							self.cur = lerp(self.lerpto, self.cur, exp(-elapsed * self.speed))
							
							self.mod = self.mod + elapsed
							if self.mod >= 1 / self.fps then
								self.mod = 0
								
								self.applied = rand(self.cur)
							end
						end
					})
				})
			})
			
			override(ret.x, {
				shake = ret.shake.x
			})
			
			override(ret.y, {
				shake = ret.shake.y
			})
			
			return ret
		else
			return override(copy(lib.unit), {
				tag = tag,
				
				cur = init,
				lerpto = init,
				
				speed = speed,
				
				shake = override(copy(lib.unit), {
					tag = tag .. "_shake",
					
					speed = 10
				})
			})
		end
	end
}

runHaxeCode([[
	import haxe.ds.StringMap;
	
	import flixel.addons.display.FlxRuntimeShader;
	
	using StringTools;
	
	function check_type(val, type) {
		return Std.isOfType(val, Type.resolveClass(type));
	}
	
	var to_stringmap;
	to_stringmap = function(val) {
		var ret = new StringMap<Dynamic>();
		
		if (val == null) {return ret;}
		
		for (k in Reflect.fields(val)) {
			var temp = Reflect.field(val, k);
			if (check_type(temp, "Int") || check_type(temp, "Float") || check_type(temp, "Bool") || check_type(temp, "String")) {
				ret.set(k, temp);
			} else if (Reflect.isObject(temp)) {
				ret.set(k, to_stringmap(temp));
			} else {
				ret.set(k, temp);
			}
		}
		
		return ret;
	};
	
	function to_array(val) {
		if (check_type(val, "Array")) {return val;}
		
		var ret = [];
		if (val == null) {return ret;}
		val = to_stringmap(val);
		
		var keys = [];
		for (key in val.keys()) {
			var ind = Std.parseInt(key);
			if (ind == null) {
				continue;
			}
			
			keys.push(ind);
		}
		
		keys.sort(function(a, b) {return a - b;});
		
		for (key in keys) {
			ret.push(val.get(Std.string(key)));
		}
		
		return ret;
	};
	
	var cam_scale = Math.sqrt(Math.pow(1280, 2) + Math.pow(720, 2)) / 720;
	
	var rotate_frag = "
		#pragma header
		
		uniform float u_angle;
		
		void main() {
			vec2 uv = openfl_TextureCoordv - 0.5;
			vec2 ratio = openfl_TextureSize.xy / max(openfl_TextureSize.x, openfl_TextureSize.y);
			
			uv *= ratio;
			
			vec2 rot = vec2(cos(u_angle), sin(u_angle));
			uv = vec2(
				uv.x * rot.x - uv.y * rot.y,
				uv.x * rot.y + uv.y * rot.x
			);
			
			uv /= ratio;
			
			gl_FragColor = flixel_texture2D(bitmap, uv + 0.5);
		}
	";
	
	var pragma_custom = ("
		#pragma version
		#pragma precision
		
		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;
		
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;
		
		uniform bool hasTransform;
		uniform bool hasColorTransform;
		
		vec4 flixel_texture2D(sampler2D bitmap, vec2 uv) {
			uv = (uv - 0.5) / _scale + 0.5;
			
			vec4 tex = texture2D(bitmap, uv);
			
			if (!hasTransform) {
				return tex;
			}
			
			if (tex.a == 0.0) {
				return vec4(0.0);
			}
			
			if (!hasColorTransform) {
				return tex * openfl_Alphav;
			}
			
			tex = clamp(vec4(tex.rgb / tex.a, tex.a) * openfl_ColorMultiplierv + openfl_ColorOffsetv, 0.0, 1.0);
			
			if (tex.a > 0.0) {
				return vec4(tex.rgb, 1.0) * tex.a * openfl_Alphav;
			}
			
			return vec4(0.0);
		}
		
		#define _uv ((openfl_TextureCoordv - 0.5) * _scale + 0.5)
	").replace("_scale", Std.string(cam_scale));
	
	var game_shaders = new StringMap<Dynamic>();
	var game_filters = new Array<ShaderFilter>();
	
	function game_shaders_create(shader_tag, shader_name) {
		if (shader_tag == "nc_rotate") {
			return;
		}
			
		if (game_shaders.exists(shader_tag)) {
			return;
		}
		
		var sprite_tag = "nc_game_shaders_" + shader_tag;
		parentLua.call("removeLuaSprite", [sprite_tag]);
		parentLua.call("makeLuaSprite", [sprite_tag]);
		
		game.initLuaShader(shader_name);
		var args = game.runtimeShaders.get(shader_name);
		if (args[0] != null) {
			args = [
				args[0].replace("#pragma header", pragma_custom),
				args[1]
			];
			
			game.runtimeShaders.set(shader_tag, args);
		}
		
		var shader = new FlxRuntimeShader(args[0], args[1]);
		game.getLuaObject(sprite_tag).shader = shader;
		
		game_shaders.set(shader_tag, {
			shader: shader,
			filter: new ShaderFilter(shader),
			
			uniforms: new StringMap<String>()
		});
	}
	
	function game_shaders_add(shader_tags) {
		for (shader_tag in to_array(shader_tags)) {
			if (shader_tag == "nc_rotate") {
				continue;
			}
			
			if (!game_shaders.exists(shader_tag)) {
				continue;
			}
			
			var add = false;
			for (filter in game_filters) {
				if (filter == game_shaders.get(shader_tag).filter) {
					add = true;
					break;
				}
			}
			
			if (!add) {
				game_filters.push(game_shaders.get(shader_tag).filter);
			}
		}
		
		game.camGame.setFilters(game_shaders.get("nc_rotate").concat(game_filters));
	}
	
	function game_shaders_set(shader_tags) {
		game_filters = [];
		
		game_shaders_add(shader_tags);
	}
	
	function game_shaders_remove(shader_tags) {
		for (shader_tag in to_array(shader_tags)) {
			if (shader_tag == "nc_rotate") {
				continue;
			}
			
			if (!game_shaders.exists(shader_tag)) {
				continue;
			}
			
			var index = -1;
			for (i in 0 ... game_filters.length) {
				if (game_filters[i] == game_shaders.get(shader_tag).filter) {
					index = i;
					break;
				}
			}
			
			if (index != -1) {
				game_filters.splice(index, 1);
			}
		}
		
		game.camGame.setFilters(game_shaders.get("nc_rotate").concat(game_filters));
	}
	
	function game_shaders_set_uniform(shader_tag, uniform, val, type) {
		if (shader_tag == "nc_rotate") {
			return;
		}
		
		if (!game_shaders.exists(shader_tag)) {
			return;
		}
		
		var sprite_tag = "nc_game_shaders_" + shader_tag;
		var ret = false;
		switch (type) {
			case "bool": {
				parentLua.call("setShaderBool", [sprite_tag, uniform, val]);
			}
			
			case "bool_array": {
				parentLua.call("setShaderBoolArray", [sprite_tag, uniform, val]);
			}
			
			case "int": {
				parentLua.call("setShaderInt", [sprite_tag, uniform, val]);
			}
			
			case "int_array": {
				parentLua.call("setShaderIntArray", [sprite_tag, uniform, val]);
			}
			
			case "float": {
				parentLua.call("setShaderFloat", [sprite_tag, uniform, val]);
			}
			
			case "float_array": {
				parentLua.call("setShaderFloatArray", [sprite_tag, uniform, val]);
			}
			
			case "sampler2d": {
				parentLua.call("setShaderSampler2D", [sprite_tag, uniform, val]);
			}
			
			default: {
				ret = true;
			}
		}
		
		if (ret) {
			return;
		}
		
		game_shaders.get(shader_tag).uniforms.set(uniform, type);
	}
	
	function game_shaders_get_uniform_type(shader_tag, uniform) {
		if (!game_shaders.exists(shader_tag)) {
			return;
		}
		
		if (!game_shaders.exists(shader_tag)) {
			return;
		}
		
		return game_shaders.get(shader_tag).uniforms.get(uniform);
	}
	
	var hud_shaders = new StringMap<Dynamic>();
	var hud_filters = new Array<ShaderFilter>();
	
	function hud_shaders_create(shader_tag, shader_name) {
		if (shader_tag == "nc_rotate") {
			return;
		}
			
		if (hud_shaders.exists(shader_tag)) {
			return;
		}
		
		var sprite_tag = "nc_hud_shaders_" + shader_tag;
		parentLua.call("removeLuaSprite", [sprite_tag]);
		parentLua.call("makeLuaSprite", [sprite_tag]);
		
		game.initLuaShader(shader_name);
		var args = game.runtimeShaders.get(shader_name);
		if (args[0] != null) {
			args = [
				args[0].replace("#pragma header", pragma_custom),
				args[1]
			];
			
			game.runtimeShaders.set(shader_tag, args);
		}
		
		var shader = new FlxRuntimeShader(args[0], args[1]);
		game.getLuaObject(sprite_tag).shader = shader;
		
		hud_shaders.set(shader_tag, {
			shader: shader,
			filter: new ShaderFilter(shader),
			
			uniforms: new StringMap<String>()
		});
	}
	
	function hud_shaders_add(shader_tags) {
		for (shader_tag in to_array(shader_tags)) {
			if (shader_tag == "nc_rotate") {
				continue;
			}
			
			if (!hud_shaders.exists(shader_tag)) {
				continue;
			}
			
			var add = false;
			for (filter in hud_filters) {
				if (filter == hud_shaders.get(shader_tag).filter) {
					add = true;
					break;
				}
			}
			
			if (!add) {
				hud_filters.push(hud_shaders.get(shader_tag).filter);
			}
		}
		
		game.camHUD.setFilters(hud_shaders.get("nc_rotate").concat(hud_filters));
	}
	
	function hud_shaders_set(shader_tags) {
		hud_filters = [];
		
		hud_shaders_add(shader_tags);
	}
	
	function hud_shaders_remove(shader_tags) {
		for (shader_tag in to_array(shader_tags)) {
			if (shader_tag == "nc_rotate") {
				continue;
			}
			
			if (!hud_shaders.exists(shader_tag)) {
				continue;
			}
			
			var index = -1;
			for (i in 0 ... hud_filters.length) {
				if (hud_filters[i] == hud_shaders.get(shader_tag).filter) {
					index = i;
					break;
				}
			}
			
			if (index != -1) {
				hud_filters.splice(index, 1);
			}
		}
		
		game.camHUD.setFilters(hud_shaders.get("nc_rotate").concat(hud_filters));
	}
	
	function hud_shaders_set_uniform(shader_tag, uniform, val, type) {
		if (shader_tag == "nc_rotate") {
			return;
		}
		
		if (!hud_shaders.exists(shader_tag)) {
			return;
		}
		
		var sprite_tag = "nc_hud_shaders_" + shader_tag;
		var ret = false;
		switch (type) {
			case "bool": {
				parentLua.call("setShaderBool", [sprite_tag, uniform, val]);
			}
			
			case "bool_array": {
				parentLua.call("setShaderBoolArray", [sprite_tag, uniform, val]);
			}
			
			case "int": {
				parentLua.call("setShaderInt", [sprite_tag, uniform, val]);
			}
			
			case "int_array": {
				parentLua.call("setShaderIntArray", [sprite_tag, uniform, val]);
			}
			
			case "float": {
				parentLua.call("setShaderFloat", [sprite_tag, uniform, val]);
			}
			
			case "float_array": {
				parentLua.call("setShaderFloatArray", [sprite_tag, uniform, val]);
			}
			
			case "sampler2d": {
				parentLua.call("setShaderSampler2D", [sprite_tag, uniform, val]);
			}
			
			default: {
				ret = true;
			}
		}
		
		if (ret) {
			return;
		}
		
		hud_shaders.get(shader_tag).uniforms.set(uniform, type);
	}
	
	function hud_shaders_get_uniform_type(shader_tag, uniform) {
		if (shader_tag == "nc_rotate") {
			return;
		}
		
		if (!hud_shaders.exists(shader_tag)) {
			return;
		}
		
		return hud_shaders.get(shader_tag).uniforms.get(uniform);
	}
	
	function setup_shader_cams() {
		game.runtimeShaders.set("nc_rotate", [rotate_frag, null]);
		
		var game_rotate_shader = new FlxRuntimeShader(rotate_frag);
		
		parentLua.call("removeLuaSprite", ["nc_game_shaders_nc_rotate"]);
		parentLua.call("makeLuaSprite", ["nc_game_shaders_nc_rotate"]);
		
		game.getLuaObject("nc_game_shaders_nc_rotate").shader = game_rotate_shader;
		parentLua.call("setShaderFloat", ["nc_game_shaders_nc_rotate", "u_angle", 0]);
		
		game_shaders.set("nc_rotate", [new ShaderFilter(game_rotate_shader)]);
		game_shaders_add(["nc_rotate"]);
		
		var hud_rotate_shader = new FlxRuntimeShader(rotate_frag);
		
		parentLua.call("removeLuaSprite", ["nc_hud_shaders_nc_rotate"]);
		parentLua.call("makeLuaSprite", ["nc_hud_shaders_nc_rotate"]);
		
		game.getLuaObject("nc_hud_shaders_nc_rotate").shader = hud_rotate_shader;
		parentLua.call("setShaderFloat", ["nc_hud_shaders_nc_rotate", "u_angle", 0]);
		
		hud_shaders.set("nc_rotate", [new ShaderFilter(hud_rotate_shader)]);
		hud_shaders_add(["nc_rotate"]);
	}
	
	function check_gf() {
		return game.gf != null;
	}
	
	function first_musthit() {
		if (PlayState.SONG == null) {
			return true;
		}
		
		if (PlayState.SONG.notes[0] == null) {
			return true;
		}
		
		return PlayState.SONG.notes[0].mustHitSection;
	}
	
	createCallback("nc_make_callback", function(name) {
		createGlobalCallback("nc_" + name, function(args) {
			parentLua.call(name, [args]);
		});
	});
]])

local settings = {
	note_offset = getModSetting("nc_note_offset", "neocam"),
	start_centered = getModSetting("nc_start_centered", "neocam"),
	vanilla_camera = getModSetting("nc_vanilla_camera", "neocam"),
}

local enabled = false

local section_step = 0

local targets = {}

local cams = {
	game = {},
	hud = {}
}

local function make_callback(name, func)
	_G[name] = function(args)
		return func(unpack(args))
	end
	
	nc_make_callback(name)
	
	return func
end

make_callback("enable", function()
	if not enabled then
		setProperty("isCameraOnForcedPos", true)
		setProperty("camGame.followLerp", 0)
		
		setProperty("camGame.flashSprite.scaleX", diagonal)
		setProperty("camGame.flashSprite.scaleY", diagonal)
		
		setProperty("camHUD.flashSprite.scaleX", diagonal)
		setProperty("camHUD.flashSprite.scaleY", diagonal)
	end
	
	enabled = true
end)

make_callback("disable", function()
	if enabled then
		setProperty("isCameraOnForcedPos", false)
		
		setProperty("camGame.flashSprite.scaleX", 1)
		setProperty("camGame.flashSprite.scaleY", 1)
		setProperty("camGame.zoom", getProperty("defaultCamZoom"))
		
		runHaxeFunction("game_shaders_set", {"nc_rotate"})
		setShaderFloat("nc_game_shaders_nc_rotate", "u_angle", 0)
		
		setProperty("camHUD.flashSprite.scaleX", 1)
		setProperty("camHUD.flashSprite.scaleY", 1)
		setProperty("camHUD.zoom", 1)
		
		runHaxeFunction("hud_shaders_set", {"nc_rotate"})
		setShaderFloat("nc_hud_shaders_nc_rotate", "u_angle", 0)
	end
	
	enabled = false
end)

make_callback("set_target", function(tag, target)
	if not is_table(target) then
		return
	end
	
	targets[tag] = target
	
	return target
end)

make_callback("override_target", function(tag, target)
	if not is_table(target) then
		return
	end
	
	override(targets[tag] or nc_set_target({tag, {}}), target)
end)

make_callback("remove_target", function(tag)
	targets[tag] = nil
end)

make_callback("snap_target", function(tag, lock)
	local target = targets[tag]
	if not target then
		return
	end
	
	for cam, props in pairs(target) do
		for prop, data in pairs(props) do
			cams[cam][prop]:snap(data.goal, lock)
		end
	end
end)

make_callback("focus", function(tag, override_target, lock)
	if not targets[tag] then
		return
	end
	
	if not is_table(override_target) then
		override_target = {}
	end
	
	for cam, props in pairs(override(copy(targets[tag]), override_target)) do
		for prop, data in pairs(props) do
			if is_table(data.x) or is_table(data.y) then
				for _, v in pairs({"x", "y"}) do
					if is_table(data[v]) then
						cams[cam][prop][v]:tween(
							data[v].start or (is_table(data.start) and data.start[v]) or data.start,
							data[v].goal or (is_table(data.goal) and data.goal[v]) or data.goal,
							
							data[v].duration or data.duration,
							data[v].ease or data.ease,
							
							lock == nil and (data[v].lock or data.lock) or lock
						)
						
						if is_table(data[v].shake) then
							cams[cam][prop][v].shake:tween(
								data[v].shake.start or (is_table(data.shake) and (is_table(data.shake.start) and data.shake.start[v] or data.shake.start)),
								data[v].shake.goal or (is_table(data.shake) and (is_table(data.shake.goal) and data.shake.goal[v] or data.shake.goal)),
								
								data[v].shake.duration or (is_table(data.shake) and data.shake.duration) or data[v].duration or data.duration,
								data[v].shake.ease or (is_table(data.shake) and data.shake.ease) or data[v].ease or data.ease,
								
								lock == nil and (data[v].shake.lock or (is_table(data.shake) and data.shake.lock) or data[v].lock or data.lock) or lock
							)
						end
					end
				end
			else
				cams[cam][prop]:tween(
					data.start,
					data.goal,
					
					data.duration,
					data.ease,
					
					lock == nil and (data.lock) or lock
				)
				
				if is_table(data.shake) then
					cams[cam][prop].shake:tween(
						data.shake.start,
						data.shake.goal,
						
						data.shake.duration or data.duration,
						data.shake.ease or data.ease,
						
						lock == nil and (data.shake.lock or data.lock) or lock
					)
				end
			end
		end
	end
end)

make_callback("set_note_offset", function(val)
	cams.game.note_offset.offset = (is_table(val) and {x = val.x, y = val.y}) or tonumber(val) or 0
end)

do
	local function setup_cam(name)
		local function setup_movable(prop, val, speed)
			local function setup_callbacks(unit, tag)
				tag = tag .. "_"
				
				for k, v in pairs(unit) do
					if type(v) == "function" then
						make_callback(tag .. k, function(...)
							return v(unit, ...)
						end)
					end
				end
			end
			
			local tag = name .. "_" .. prop
			local ret = movable:new(tag, val, speed)
			
			setup_callbacks(ret, tag)
			if ret.x and ret.y then
				setup_callbacks(ret.x, tag .. "_x")
				setup_callbacks(ret.y, tag .. "_y")
			end
			
			setup_callbacks(ret.shake, tag .. "_shake")
			if ret.shake.x and ret.shake.y then
				setup_callbacks(ret.shake.x, tag .. "_shake_x")
				setup_callbacks(ret.shake.y, tag .. "_shake_y")
				
				setup_callbacks(ret.x.shake, tag .. "_x_shake")
				setup_callbacks(ret.y.shake, tag .. "_y_shake")
			end
			
			return ret
		end
		
		local uniform_getters = {
			bool = getShaderBool,
			bool_array = getShaderBoolArray,
			
			int = getShaderInt,
			int_array = getShaderIntArray,
			
			float = getShaderFloat,
			float_array = getShaderFloatArray
		}
		
		local tag = name .. "_"
		local ret
		ret = {
			pos = setup_movable("pos", { x = 0, y = 0 }, settings.vanilla_camera and 2.4 or 8),
			zoom = setup_movable("zoom", 1, settings.vanilla_camera and 3.125 or 2),
			angle = setup_movable("angle", 0, 4),
			
			bump_pattern = nil,
			
			set_bump_pattern = make_callback(tag .. "set_bump_pattern", function(pattern, section_offset)
				if not is_table(pattern) then
					if pattern == nil then
						ret.bump_pattern = nil
					end
					
					return
				end
				
				local last_step = 1
				for i, amount in pairs(pattern) do
					if tonumber(amount) then
						last_step = max(last_step, tonumber(i) or 1)
					end
				end
				
				ret.bump_pattern = override(pattern, {
					sections = floor((last_step - 1) / 16) + 1,
					section_step = section_step + (tonumber(section_offset) or 0)
				})
			end),
			
			bump = make_callback(tag .. "bump", function(amount)
				ret.zoom.cur = ret.zoom.cur + (tonumber(amount) or 0)
			end),
			
			shaders = {
				create = make_callback(tag .. "shaders_create", function(shader_tag, shader_name)
					runHaxeFunction(tag .. "shaders_create", {shader_tag, shader_name})
				end),
				
				set = make_callback(tag .. "shaders_set", function(shader_tags)
					runHaxeFunction(tag .. "shaders_set", {shader_tags})
				end),
				
				add = make_callback(tag .. "shaders_add", function(shader_tags)
					runHaxeFunction(tag .. "shaders_add", {shader_tags})
				end),
				
				remove = make_callback(tag .. "shaders_remove", function(shader_tags)
					runHaxeFunction(tag .. "shaders_remove", {shader_tags})
				end),
				
				set_uniform = make_callback(tag .. "shaders_set_uniform", function(shader_tag, uniform, val, uniform_type)
					if not uniform_type then
						if type(val) == "boolean" then
							uniform_type = "bool"
						elseif type(val) == "number" then
							uniform_type = (floor(val) == val) and "int" or "float"
						elseif is_table(val) then
							if type(val[1]) == "boolean" then
								uniform_type = "bool_array"
							elseif type(val[1]) == "number" then
								uniform_type = (floor(val[1]) == val[1]) and "int_array" or "float_array"
							end
						elseif type(val) == "string" then
							uniform_type = "sampler2d"
						end
					end
					
					runHaxeFunction(tag .. "shaders_set_uniform", {shader_tag, uniform, val, uniform_type})
				end),
				
				get_uniform = make_callback(tag .. "shaders_get_uniform", function(shader_tag, uniform)
					local uniform_type = runHaxeFunction(tag .. "shaders_get_uniform_type", {shader_tag, uniform})
					if not uniform_type then
						return
					end
					
					shader_tag = "nc_" .. name .. "_shaders_" .. shader_tag
					if uniform_getters[uniform_type] then
						return uniform_getters[uniform_type](shader_tag, uniform)
					end
				end)
			}
		}
		
		return ret
	end
	
	local note_offset = {
		offset = (settings.note_offset and (not settings.vanilla_camera)) and 8 or 0,
		
		cur = {x = 0, y = 0},
		lerpto = {x = 0, y = 0}
	}
	
	cams = {
		game = override(setup_cam("game"), {
			note_offset = override(note_offset, {
				set_lerpto = function(lerpto)
					note_offset.lerpto = lerpto
				end,
				
				update = function(elapsed)
					note_offset.cur = {
						x = lerp(note_offset.lerpto.x, note_offset.cur.x, exp(-elapsed * 4)),
						y = lerp(note_offset.lerpto.y, note_offset.cur.y, exp(-elapsed * 4))
					}
				end
			})
		}),
		
		hud = setup_cam("hud")
	}
end

function onCreatePost()
	nc_set_target({"player", {
		game = {
			pos = {
				goal = {
					x = getMidpointX("boyfriend") - 100 - getProperty("boyfriend.cameraPosition[0]") + getProperty("boyfriendCameraOffset[0]"),
					y = getMidpointY("boyfriend") - 100 + getProperty("boyfriend.cameraPosition[1]") + getProperty("boyfriendCameraOffset[1]")
				},
				
				duration = settings.vanilla_camera and 0 or 1,
				ease = "circout"
			}
		}
	}})
	
	nc_set_target({"opponent", {
		game = {
			pos = {
				goal = {
					x = getMidpointX("dad") + 150 + getProperty("dad.cameraPosition[0]") + getProperty("opponentCameraOffset[0]"),
					y = getMidpointY("dad") - 100 + getProperty("dad.cameraPosition[1]") + getProperty("opponentCameraOffset[1]")
				},
				
				duration = settings.vanilla_camera and 0 or 1,
				ease = "circout"
			}
		}
	}})
	
	if runHaxeFunction("check_gf") then
		nc_set_target({"gf", {
			game = {
				pos = {
					goal = {
						x = getMidpointX("gf") + getProperty("gf.cameraPosition[0]") + getProperty("girlfriendCameraOffset[0]"),
						y = getMidpointY("gf") + getProperty("gf.cameraPosition[1]") + getProperty("girlfriendCameraOffset[1]")
					},

					duration = settings.vanilla_camera and 0 or 1,
					ease = "circout"
				}
			}
		}})
	end
	
	nc_set_target({"center", {
		game = {
			pos = {
				goal = {
					x = (targets.player.game.pos.goal.x + targets.opponent.game.pos.goal.x) / 2,
					y = (targets.player.game.pos.goal.y + targets.opponent.game.pos.goal.y) / 2
				},
				
				duration = settings.vanilla_camera and 0 or 1,
				ease = "circout"
			}
		}
	}})
	
	if settings.start_centered and (not settings.vanilla_camera) then
		nc_snap_target({"center"})
	else
		nc_snap_target({runHaxeFunction("first_musthit") and "player" or "opponent"})
	end
	
	nc_game_zoom_snap({getProperty("defaultCamZoom")})
	
	for i = 0, 7 do
		setPropertyFromGroup("strumLineNotes", i, "scrollFactor.x", 1)
		setPropertyFromGroup("strumLineNotes", i, "scrollFactor.y", 1)
	end
	
	for i = 0, getProperty("unspawnNotes.length") - 1 do
		setPropertyFromGroup("unspawnNotes", i, "scrollFactor.x", 1)
		setPropertyFromGroup("unspawnNotes", i, "scrollFactor.y", 1)
	end
	
	runHaxeFunction("setup_shader_cams")
	
	nc_enable({})
end

function onSongStart()
	nc_focus({gfSection and "gf" or (mustHitSection and "player" or "opponent")})
	
	for name, cam in pairs(cams) do
		if cam.bump_pattern then
			cam.bump(cam.bump_pattern[1] or 0)
		else
			cam.bump(name == "game" and 0.015 or 0.03)
		end
	end
end

function onSectionHit()
	nc_focus({gfSection and "gf" or (mustHitSection and "player" or "opponent")})
	
	section_step = curStep
	for name, cam in pairs(cams) do
		if cam.bump_pattern then
			if floor(curStep - cam.bump_pattern.section_step) / 16 >= cam.bump_pattern.sections then
				cam.bump_pattern.section_step = section_step
				
				cam.bump(cam.bump_pattern[1] or 0)
			end
		else
			cam.bump(name == "game" and 0.015 or 0.03)
		end
	end	
end

function onStepHit()
	for _, cam in pairs(cams) do
		if cam.bump_pattern then
			cam.bump(cam.bump_pattern[curStep - section_step + 1] or 0)
		end
	end
end

local offsets = {
	{x = -1, y = 0},
	{x = 0, y = 1},
	{x = 0, y = -1},
	{x = 1, y = 0}
}

local function follow_note(id, dir)
	dir = dir % 4 + 1
	
	local offset = cams.game.note_offset.offset or 0
	cams.game.note_offset.set_lerpto({
		x = offsets[dir].x * offset,
		y = offsets[dir].y * offset
	})
end

function goodNoteHit(id, dir)
	if mustHitSection then
		follow_note(id, dir)
	end
end

function opponentNoteHit(id, dir)
	if not mustHitSection then
		follow_note(id, dir)
	end
end

local anims = {
	player = "idle",
	opponent = "idle",
	
	gf = "idle"
}

local function anim_changed(char, anim)
	anims[char] = anim
	
	if anim == "idle" and (
		(char == "player" and mustHitSection) or
		(char == "opponent" and not mustHitSection) or
		(char == "gf" and gfSection)
	) then
		cams.game.note_offset.set_lerpto({x = 0, y = 0})
	end
end

function onUpdatePost(elapsed)
	tween:update(elapsed)
	
	for _, cam in pairs(cams) do
		for _, prop in pairs({ "pos", "zoom", "angle" }) do
			cam[prop]:update(elapsed)
			cam[prop].shake:update(elapsed)
		end
	end
	
	cams.game.note_offset.update(elapsed)
	
	if getProperty("boyfriend.animation.name") ~= anims.player then
		anim_changed("player", getProperty("boyfriend.animation.name"))
	end
	
	if getProperty("dad.animation.name") ~= anims.opponent then
		anim_changed("opponent", getProperty("dad.animation.name"))
	end
	
	if runHaxeFunction("check_gf") then
		if getProperty("gf.animation.name") ~= anims.gf then
			anim_changed("gf", getProperty("gf.animation.name"))
		end
	end
	
	if not enabled then
		return
	end
	
	if inGameOver then
		return
	end
	
	setProperty("isCameraOnForcedPos", true)
	setProperty("camGame.followLerp", 0)
	
	local game = cams.game
	setProperty("camGame.scroll.x", game.pos.x.applied + game.note_offset.cur.x + game.pos.x.shake.applied - 640)
	setProperty("camGame.scroll.y", game.pos.y.applied + game.note_offset.cur.y + game.pos.y.shake.applied - 360)
	setProperty("camGame.zoom", (game.zoom.applied + game.zoom.shake.applied) / diagonal)
	setShaderFloat("nc_game_shaders_nc_rotate", "u_angle", rad(game.angle.applied + game.angle.shake.applied))
	
	local hud = cams.hud
	setProperty("camHUD.scroll.x", hud.pos.x.applied + hud.pos.x.shake.applied)
	setProperty("camHUD.scroll.y", hud.pos.y.applied + hud.pos.y.shake.applied)
	setProperty("camHUD.zoom", (hud.zoom.applied + hud.zoom.shake.applied) / diagonal)
	setShaderFloat("nc_hud_shaders_nc_rotate", "u_angle", rad(hud.angle.applied + hud.angle.shake.applied))
	
	for i = 0, getProperty("grpNoteSplashes.length") - 1 do
		setPropertyFromGroup("grpNoteSplashes", i, "scrollFactor.x", 1)
		setPropertyFromGroup("grpNoteSplashes", i, "scrollFactor.y", 1)
	end
end

function onGameOverStart()
	nc_disable({})
end