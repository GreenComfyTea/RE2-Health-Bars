local this = {};

local singletons;
local config;
local enemy_handler;
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

this.player = {};
this.player.position = Vector3f.new(0, 0, 0);
this.player.is_aiming = false;
this.player.aim_target = nil;

local player_manager_type_def = sdk.find_type_definition("app.ropeway.PlayerManager");
local get_current_position_method = player_manager_type_def:get_method("get_CurrentPosition");
local get_current_player_condition_method = player_manager_type_def:get_method("get_CurrentPlayerCondition");

local player_condition_type_def = sdk.find_type_definition("app.ropeway.survivor.player.PlayerCondition");
local get_is_hold_method = player_condition_type_def:get_method("get_IsHold");

local equipment_manager_type_def = sdk.find_type_definition("app.ropeway.EquipmentManager");
local get_player_equipment_method = equipment_manager_type_def:get_method("getPlayerEquipment");

local equip_weapon_type_def = get_player_equipment_method:get_return_type();
local get_equip_weapon_method = equip_weapon_type_def:get_method("get_EquipWeapon");

local gun_type_def = get_equip_weapon_method:get_return_type();
local get_enemy_controller_method = gun_type_def:get_method("get_EnemyController");

function this.tick()
	local player_manager = singletons.player_manager;
	if player_manager == nil then
		error_handler.report("player_handler.tick", "No PlayerManager");
		return;
	end

	this.update_position(player_manager);
end

function this.update()
	local player_manager = singletons.player_manager;

	if player_manager == nil then
		error_handler.report("player_handler.update_player_data", "No PlayerManager");
		return;
	end

	this.update_is_aiming(player_manager);
	this.update_aim_target();
end

function this.update_position(player_manager)
	local position = get_current_position_method:call(player_manager);

	if position == nil then
		error_handler.report("player_handler.update_position", "No Position");
		return;
	end

	this.player.position = position;
end

function this.update_is_aiming(player_manager)
	local cached_config = config.current_config.settings;

	local player_condition = get_current_player_condition_method:call(player_manager);
	if player_condition == nil then
		return;
	end

	local is_hold = get_is_hold_method:call(player_condition);

	if is_hold == nil then
		error_handler.report("player_handler.update_aim", "No IsHold");
		return;
	end

	this.player.is_aiming = is_hold;

	if is_hold and cached_config.apply_time_duration_on_aiming then
		for enemy_context, enemy in pairs(enemy_handler.enemy_list) do
			enemy_handler.update_last_reset_time(enemy);
		end
	end
end

function this.update_aim_target()
	local cached_config = config.current_config.settings;

	local equipment_manager = singletons.equipment_manager;
	if equipment_manager == nil then
		error_handler.report("player_handler.update_aim_target", "No EquipmentManager");
		return;
	end

	local player_equipment = get_player_equipment_method:call(equipment_manager);
	if player_equipment == nil then
		-- error_handler.report("player_handler.update_aim_target", "No PlayerEquipment");
		return;
	end

	local equip_weapon = get_equip_weapon_method:call(player_equipment);
	if equip_weapon == nil then
		return;
	end

	local target_enemy_controller = get_enemy_controller_method:call(equip_weapon);
	this.player.aim_target = target_enemy_controller;

	if target_enemy_controller == nil then
		return;
	end

	local target_enemy = enemy_handler.enemy_list[target_enemy_controller];
	if target_enemy == nil then
		return;
	end

	if cached_config.reset_time_duration_on_aim_target_for_everyone then
		for enemy_context, enemy in pairs(enemy_handler.enemy_list) do
			if time.total_elapsed_script_seconds - enemy.last_reset_time < cached_config.time_duration then
				enemy_handler.update_last_reset_time(enemy);
			end
		end
	end
	
	if cached_config.apply_time_duration_on_aim_target then
		enemy_handler.update_last_reset_time(target_enemy);
	end
end

function this.init_module()
	singletons = require("Health_Bars.singletons");
	error_handler = require("Health_Bars.error_handler");
	config = require("Health_Bars.config");
	time = require("Health_Bars.time");
	enemy_handler = require("Health_Bars.enemy_handler");
end

return this;