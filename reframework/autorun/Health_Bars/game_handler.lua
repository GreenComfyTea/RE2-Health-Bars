local this = {};

local singletons;
local customization_menu;
local time;
local error_handler;

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

this.game = {};
this.game.is_cutscene_playing = false;
this.game.is_paused = false;

local game_clock_type_def = sdk.find_type_definition("app.ropeway.GameClock");

local measure_demo_spending_time_field = game_clock_type_def:get_field("_MeasureDemoSpendingTime");
local measure_inventory_spending_time_field = game_clock_type_def:get_field("_MeasureInventorySpendingTime");
local measure_pause_spending_time_field = game_clock_type_def:get_field("_MeasurePauseSpendingTime");

function this.update()
	local game_clock = singletons.game_clock;
	if game_clock == nil then
		error_handler.report("game_handler.update", "No GameClock");
		return;
	end

	this.update_is_cutscene(game_clock);
	this.update_is_paused(game_clock);
end

function this.update_is_cutscene(game_clock)
	local measure_demo_spending_time = measure_demo_spending_time_field:get_data(game_clock);
	if measure_demo_spending_time == nil then
		measure_demo_spending_time = false;
	end

	this.game.is_cutscene_playing = measure_demo_spending_time;
end

function this.update_is_paused(game_clock)
	local measure_inventory_spending_time = measure_inventory_spending_time_field:get_data(game_clock);
	if measure_inventory_spending_time == nil then
		measure_inventory_spending_time = false;
	end

	local measure_pause_spending_time = measure_pause_spending_time_field:get_data(game_clock);
	if measure_pause_spending_time == nil then
		measure_pause_spending_time = false;
	end

	this.game.is_paused = measure_inventory_spending_time or measure_pause_spending_time;
end

function this.init_module()
	singletons = require("Health_Bars.singletons");
	customization_menu = require("Health_Bars.customization_menu");
	time = require("Health_Bars.time");
	error_handler = require("Health_Bars.error_handler");
end

return this;