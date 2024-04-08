local this = {};

local singletons;
local customization_menu;
local config;
local utils;
local screen;
local game_handler;
local enemy_handler;
local player_handler;

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
local ValueType = ValueType;
local package = package;

this.total_elapsed_script_seconds = 0;

this.timer_list = {};
this.delay_timer_list = {};

function this.new_timer(callback, cooldown_seconds, start_offset_seconds)
	start_offset_seconds = start_offset_seconds or utils.math.random();

	if callback == nil or cooldown_seconds == nil then
		return;
	end

	local timer = {};
	timer.callback = callback;
	timer.cooldown = cooldown_seconds;

	timer.last_trigger_time = os.clock() + start_offset_seconds;

	this.timer_list[callback] =  timer;
end

function this.new_delay_timer(callback, delay_seconds)
	if callback == nil or delay_seconds == nil then
		return;
	end

	local delay_timer = {};
	delay_timer.callback = callback;
	delay_timer.delay = delay_seconds;
	
	delay_timer.init_time = os.clock();

	this.delay_timer_list[callback] = delay_timer;

	return delay_timer;
end

function this.remove_delay_timer(delay_timer)
	if delay_timer == nil then
		return;
	end

	this.delay_timer_list[delay_timer.callback] = nil; 
end

function this.init_global_timers()
	local cached_config = config.current_config.settings.timer_delays;

	this.timer_list = {};

	this.new_timer(singletons.update, cached_config.update_singletons_delay);
	this.new_timer(screen.update_window_size, cached_config.update_window_size_delay);
	this.new_timer(game_handler.update, cached_config.update_game_data_delay);
	this.new_timer(player_handler.update, cached_config.update_player_data_delay);
	this.new_timer(enemy_handler.update, cached_config.update_enemy_data_delay);
end

function this.update_timers()
	this.update_script_time();

	for callback, timer in pairs(this.timer_list) do
		if this.total_elapsed_script_seconds - timer.last_trigger_time > timer.cooldown then
			timer.last_trigger_time = this.total_elapsed_script_seconds;
			callback();
		end
	end

	local remove_list = {};

	for callback, delay_timer in pairs(this.delay_timer_list) do
		if this.total_elapsed_script_seconds - delay_timer.init_time > delay_timer.delay then
			callback();
			table.insert(remove_list, callback);
		end
	end

	for i, callback in ipairs(remove_list) do
		this.delay_timer_list[callback] = nil;
	end
end

function this.update_script_time()
	this.total_elapsed_script_seconds = os.clock();
end

function this.init_module()
	singletons = require("Health_Bars.singletons");
	screen = require("Health_Bars.screen");
	customization_menu = require("Health_Bars.customization_menu");
	config = require("Health_Bars.config");
	utils = require("Health_Bars.utils");
	game_handler = require("Health_Bars.game_handler");
	enemy_handler = require("Health_Bars.enemy_handler");
	player_handler = require("Health_Bars.player_handler");
end

return this;