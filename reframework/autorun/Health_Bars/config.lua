local this = {};
local version = "1.2";

local utils;
local language;

local sdk = sdk;
local tostring = tostring;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local require = require;
local pcall = pcall;
local table = table;
local string = string;
local Vector3f = Vector3f;
local d2d = d2d;
local math = math;
local json = json;
local log = log;
local fs = fs;
local next = next;
local type = type;
local setmetatable = setmetatable;
local getmetatable = getmetatable;
local assert = assert;
local select = select;
local coroutine = coroutine;
local utf8 = utf8;
local re = re;
local imgui = imgui;
local draw = draw;
local Vector2f = Vector2f;
local reframework = reframework;
local os = os;

this.current_config = nil;
this.config_file_name = "Health Bars/config.json";

this.default_config = {};

function this.init()
	this.default_config = {
		enabled = true,
		
		version = this.version,
		language = "default",

		customization_menu = {
			position = {
				x = 480,
				y = 200
			},

			size = {
				width = 650,
				height = 480
			},

			pivot = {
				x = 0,
				y = 0
			}
		},

		menu_font = {
			size = 15
		},

		ui_font = {
			family = "Consolas",
			size = 13,
			bold = true,
			italic = false
		},

		settings = {
			timer_delays = {
				update_singletons_delay = 0,
				update_window_size_delay = 0,
				update_game_data_delay = 0.1,
				update_player_data_delay = 0.1,
				update_enemy_data_delay = 0.1,
			},
			
			use_d2d_if_available = true,
			
			render_during_cutscenes = false,
			render_when_game_is_paused = false,

			render_aim_target_enemy = true,
			render_damaged_enemies = true,
			render_everyone_else = true,

			render_when_normal = true,
			render_when_aiming = true,

			hide_if_dead = true,
			hide_if_full_health = true,
			hide_if_enemy_is_not_in_sight = true,

			opacity_falloff = true,
			max_distance = 30,

			apply_time_duration_on_aiming = false,
			apply_time_duration_on_aim_target = false,
			apply_time_duration_on_damage_dealt = false,
			reset_time_duration_on_aim_target_for_everyone = true,
			reset_time_duration_on_damage_dealt_for_everyone = true,
			time_duration = 15,
		},

		world_offset = {
			x = 0,
			y = 0.35,
			z = 0
		},

		health_value_label = {
			visibility = true,

			settings = {
				right_alignment_shift = 11
			},

			include = {
				current_value = true,
				max_value = true
			},

			text_format = "%s", -- current_health/max_health

			offset = {
				x = -20,
				y = 0
			},
			
			color = 0xFFFFFCC0,

			shadow = {
				visibility = true,
				offset = {
					x = 1,
					y = 1
				},
				color = 0xFF000000
			}
		},

		health_bar = {
			visibility = true,

			settings = {
				fill_direction = "Left to Right"
			},

			offset = {
				x = -64,
				y = 0
			},

			size = {
				width = 128,
				height = 8
			},

			outline = {
				visibility = true,
				thickness = 2.5,
				offset = 0,
				style = "Outside"
			},

			colors = {
				foreground = 0x80A0FF71,
				background = 0x48000000,
				outline = 0x68000000
			}
		},

		debug = {
			history_size = 64
		},
	};
end

function this.load()
	local loaded_config = json.load_file(this.config_file_name);
	if loaded_config ~= nil then
		log.info("[Health Bars] config.json loaded successfully");
		this.current_config = utils.table.merge(this.default_config, loaded_config);
	else
		log.error("[Health Bars] Failed to load config.json");
		this.current_config = utils.table.deep_copy(this.default_config);
	end
end

function this.save()
	-- save current config to disk, replacing any existing file
	local success = json.dump_file(this.config_file_name, this.current_config);
	if success then
		log.info("[Health Bars] config.json saved successfully");
	else
		log.error("[Health Bars] Failed to save config.json");
	end
end

function this.reset()
	this.current_config = utils.table.deep_copy(this.default_config);
	this.current_config.version = version;
end

function this.init_module()
	utils = require("Health_Bars.utils");
	language = require("Health_Bars.language");
	this.init();
	this.load();
	this.current_config.version = version;

	language.update(utils.table.find_index(language.language_names, this.current_config.language));
end

return this;
