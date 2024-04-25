local this = {};

local utils;
local singletons;
local config;
local drawing;
local customization_menu;
local player_handler;
local game_handler;
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

this.enemy_list = {};
this.update_time_limit = 0.5;

local enemy_controller_type_def = sdk.find_type_definition("app.ropeway.EnemyController");
local update_method = enemy_controller_type_def:get_method("update");
local get_is_in_sight_method = enemy_controller_type_def:get_method("get_IsInSight");
local do_on_destroy_method = enemy_controller_type_def:get_method("doOnDestroy");
local get_game_object_method = enemy_controller_type_def:get_method("get_GameObject");
local on_hit_damage_method = enemy_controller_type_def:get_method("HitController_OnHitDamage");
local get_hit_point_method = enemy_controller_type_def:get_method("get_HitPoint");
local dead_method = enemy_controller_type_def:get_method("dead");
local do_awake_b_529_4_method = enemy_controller_type_def:get_method("<doAwake>b__529_4");
local get_no_damage_method = enemy_controller_type_def:get_method("get_NoDamage");

local enemy_hit_point_controller_type_def = get_hit_point_method:get_return_type();
local get_current_hit_point_method = enemy_hit_point_controller_type_def:get_method("get_CurrentHitPoint");
local get_default_hit_point_method = enemy_hit_point_controller_type_def:get_method("get_DefaultHitPoint");
local get_is_dead_method = enemy_hit_point_controller_type_def:get_method("get_IsDead");

local game_object_type_def = get_game_object_method:get_return_type();
local get_transform_method = game_object_type_def:get_method("get_Transform");

local transform_type_def = get_transform_method:get_return_type();
local get_joint_by_name_method = transform_type_def:get_method("getJointByName");

local joint_type_def = get_joint_by_name_method:get_return_type();
local get_position_method = joint_type_def:get_method("get_Position");

local damage_info_type_def = sdk.find_type_definition("app.Collision.HitController.DamageInfo");
local get_damage_method = damage_info_type_def:get_method("get_Damage");

function this.new(enemy_controller)
	local enemy = {};
	enemy.enemy_controller = enemy_controller;

	enemy.game_object = nil;

	enemy.health = -1;
	enemy.max_health = -1;
	enemy.health_percentage = 0;
	enemy.is_dead = false;


	enemy.head_joint = nil;
	enemy.position = Vector3f.new(0, 0, 0);
	enemy.distance = 0;

	enemy.is_in_sight = false;

	enemy.last_reset_time = 0;
	enemy.last_update_time = 0;

	this.update_health(enemy);

	if enemy.health == -1 or enemy.max_health == -1 then
		return nil;
	end

	this.update_game_object(enemy);
	this.update_head_joint(enemy);
	this.update_position(enemy);
	
	this.enemy_list[enemy_controller] = enemy;
	
	return enemy;
end

function this.get_enemy(enemy_controller)
	local enemy = this.enemy_list[enemy_controller];
	if enemy == nil then
		enemy = this.new(enemy_controller);
	end
	
	return enemy;
end

function this.get_enemy_null(enemy_controller, create_if_not_found)
	if create_if_not_found == nil then
		create_if_not_found = true;
	end

	local enemy = this.enemy_list[enemy_controller];
	if enemy == nil and create_if_not_found then
		enemy = this.new(enemy_controller);
	end

	return enemy;
end

function this.update()
	for enemy_controller, enemy in pairs(this.enemy_list) do
		this.update_is_in_sight(enemy);
	end
end

function this.update_health(enemy)
	local hit_point_controller = get_hit_point_method:call(enemy.enemy_controller);
	if hit_point_controller == nil then
		error_handler.report("enemy_handler.update_health", "No HitPointController");
		return;
	end

	local health = get_current_hit_point_method:call(hit_point_controller);
	local max_health = get_default_hit_point_method:call(hit_point_controller);
	local is_dead = get_is_dead_method:call(hit_point_controller);

	if health == nil then
		error_handler.report("enemy_handler.update_health", "No Health");
	else
		enemy.health = utils.math.round(health);
	end

	if max_health == nil then
		error_handler.report("enemy_handler.update_health", "No MaxHealth");
	else
		enemy.max_health = utils.math.round(max_health);
	end

	if enemy.max_health == 0 then
		enemy.health_percentage = 0;
	else
		enemy.health_percentage = enemy.health / enemy.max_health;
	end

	if is_dead == nil then
		error_handler.report("enemy_handler.update_health", "No IsDead");
	else
		enemy.is_dead = is_dead;
	end
end

function this.update_is_in_sight(enemy)
	local is_in_sight = get_is_in_sight_method:call(enemy.enemy_controller);
	if is_in_sight == nil then
		error_handler.report("enemy_handler.update_is_in_sight", "No IsInSight");
		return;
	end

	enemy.is_in_sight = is_in_sight;
end

function this.update_game_object(enemy)
	local enemy_game_object = get_game_object_method:call(enemy.enemy_controller);
	if enemy_game_object == nil then
		error_handler.report("enemy_handler.update_game_object", "No GameObject");
		return;
	end

	enemy.game_object = enemy_game_object;
end

function this.update_head_joint(enemy)
	if enemy.game_object == nil then
		error_handler.report("enemy_handler.update_head_joint", "No GameObject");
		return;
	end

	local enemy_transform = get_transform_method:call(enemy.game_object);
	if enemy_transform == nil then
		error_handler.report("enemy_handler.update_head_joint", "No Transform");
		return;
	end

	local joint = get_joint_by_name_method:call(enemy_transform, "head")
	or get_joint_by_name_method:call(enemy_transform, "Head")
	or get_joint_by_name_method:call(enemy_transform, "mouthHead") -- G 5th Form
	or get_joint_by_name_method:call(enemy_transform, "root");

	if joint == nil then
		error_handler.report("enemy_handler.update_head_joint", "No Head Joint");
		return;
	end

	enemy.head_joint = joint;
end

function this.update_last_reset_time(enemy)
	enemy.last_reset_time = time.total_elapsed_script_seconds;
end

function this.update_all_positions()
	for enemy_controller, enemy in pairs(this.enemy_list) do
		this.update_position(enemy);
	end
end

function this.update_position(enemy)
	if(enemy.head_joint == nil) then
		error_handler.report("enemy_handler.update_position", "No Head Joint");
		return;
	end

	local head_joint_position = get_position_method:call(enemy.head_joint);
	if head_joint_position == nil then
		error_handler.report("enemy_handler.update_position", "No Head Joint Position");
		return;
	end
	enemy.position = head_joint_position;
	enemy.distance = (player_handler.player.position - head_joint_position):length();
end

function this.draw_enemies()
	local cached_config = config.current_config;

	if not cached_config.settings.render_during_cutscenes and game_handler.game.is_cutscene_playing then
		return;
	end

	if not cached_config.settings.render_when_game_is_paused and game_handler.game.is_paused then
		return;
	end

	if not player_handler.player.is_aiming then
		if not cached_config.settings.render_when_normal then
		 return;
		end
	elseif not cached_config.settings.render_when_aiming then
		return;
	end

	local max_distance = cached_config.settings.max_distance;

	for enemy_controller, enemy in pairs(this.enemy_list) do
		if max_distance ~= 0 and enemy.distance > max_distance then
			goto continue;
		end

		if enemy.max_health <= 1 then
			goto continue;
		end

		local is_time_duration_on = false;

		if cached_config.settings.apply_time_duration_on_aiming
		or cached_config.settings.apply_time_duration_on_aim_target
		or cached_config.settings.apply_time_duration_on_damage_dealt then
			if cached_config.settings.time_duration ~= 0 then
				if time.total_elapsed_script_seconds - enemy.last_reset_time > cached_config.settings.time_duration then
					goto continue;
				else
					is_time_duration_on = true;
				end
			end
		end

		if not cached_config.settings.render_aim_target_enemy
		and enemy.enemy_controller == player_handler.player.aim_target
		and not is_time_duration_on then
			goto continue;
		end

		if not cached_config.settings.render_damaged_enemies
		and not utils.number.is_equal(enemy.health, enemy.max_health)
		and not is_time_duration_on then
			if enemy.enemy_controller == player_handler.player.aim_target then
				if not cached_config.settings.render_aim_target_enemy then
					goto continue;
				end
			else
				goto continue;
			end
		end

		if not cached_config.settings.render_everyone_else
		and enemy.enemy_controller ~= player_handler.player.aim_target
		and utils.number.is_equal(enemy.health, enemy.max_health)
		and not is_time_duration_on then
			goto continue;
		end

		if cached_config.settings.hide_if_dead
		and enemy.is_dead then
			goto continue;
		end

		if cached_config.settings.hide_if_full_health
		and utils.number.is_equal(enemy.health, enemy.max_health) then
			goto continue;
		end

		if cached_config.settings.hide_if_enemy_is_not_in_sight
		and not enemy.is_in_sight then
			goto continue;
		end

		local world_offset = Vector3f.new(cached_config.world_offset.x, cached_config.world_offset.y, cached_config.world_offset.z);

		local position_on_screen = draw.world_to_screen(enemy.position + world_offset);
		if position_on_screen == nil then
			goto continue;
		end

		local opacity_scale = 1;
		if cached_config.settings.opacity_falloff and max_distance ~= 0 then
			opacity_scale = 1 - (enemy.distance / max_distance);
		end

		local health_value_text = "";

		local health_value_label = cached_config.health_value_label;
		local health_value_include = health_value_label.include;
		local right_alignment_shift = health_value_label.settings.right_alignment_shift;

		if health_value_include.current_value then
			health_value_text = string.format("%.0f", enemy.health);

			if health_value_include.max_value then
				health_value_text = string.format("%s/%.0f", health_value_text, enemy.max_health);
			end
		elseif health_value_include.max_value then
			health_value_text = string.format("%.0f", enemy.max_health);
		end

		if right_alignment_shift ~= 0 then
			local right_aligment_format = string.format("%%%ds", right_alignment_shift);
			health_value_text = string.format(right_aligment_format, health_value_text);
		end

		drawing.draw_bar(cached_config.health_bar, position_on_screen, opacity_scale, enemy.health_percentage);
		drawing.draw_label(health_value_label, position_on_screen, opacity_scale, health_value_text);
		
		::continue::
	end
end

function this.on_update(enemy_controller)
	local enemy = this.get_enemy(enemy_controller);
end

function this.on_do_awake_b_529_4(enemy_controller)
	local enemy = this.get_enemy(enemy_controller);
	if enemy == nil then
		return;
	end

	this.update_health(enemy);
end

function this.on_destroy(enemy_controller)
	local enemy = this.get_enemy(enemy_controller);
	if enemy == nil then
		return;
	end

	this.enemy_list[enemy_controller] = nil;
end

function this.on_get_no_damage(enemy_controller)
	local attacked_enemy = this.get_enemy(enemy_controller);
	if attacked_enemy == nil then
		return;
	end

	this.update_health(attacked_enemy);

	this.on_damage_or_dead(attacked_enemy)
end

function this.on_dead(enemy_controller)
	local attacked_enemy = this.get_enemy(enemy_controller);
	if attacked_enemy == nil then
		return;
	end
	
	this.update_health(attacked_enemy);
	this.on_damage_or_dead(attacked_enemy)
end

function this.on_damage_or_dead(attacked_enemy)
	local cached_config = config.current_config.settings;

	if cached_config.reset_time_duration_on_damage_dealt_for_everyone then
		for enemy_controller, enemy in pairs(this.enemy_list) do
			if time.total_elapsed_script_seconds - enemy.last_reset_time < cached_config.time_duration then
				this.update_last_reset_time(enemy);
			end
		end
	end

	if cached_config.apply_time_duration_on_damage_dealt then
		this.update_last_reset_time(attacked_enemy);
	end
end

function this.init_module()
	utils = require("Health_Bars.utils");
	config = require("Health_Bars.config");
	singletons = require("Health_Bars.singletons");
	drawing = require("Health_Bars.drawing");
	customization_menu = require("Health_Bars.customization_menu");
	player_handler = require("Health_Bars.player_handler");
	game_handler = require("Health_Bars.game_handler");
	time = require("Health_Bars.time");
	error_handler = require("Health_Bars.error_handler");

	sdk.hook(update_method, function(args)
		local enemy_controller = sdk.to_managed_object(args[2]);
		this.on_update(enemy_controller);

	end, function(retval)
		return retval;
	end);

	sdk.hook(do_awake_b_529_4_method, function(args)
		local enemy_controller = sdk.to_managed_object(args[2]);
		this.on_do_awake_b_529_4(enemy_controller);

	end, function(retval)
		return retval;
	end);

	sdk.hook(do_on_destroy_method, function(args)
		local enemy_controller = sdk.to_managed_object(args[2]);
		this.on_destroy(enemy_controller);

	end, function(retval)
		return retval;
	end);

	sdk.hook(get_no_damage_method, function(args)
		local enemy_controller = sdk.to_managed_object(args[2]);
		this.on_get_no_damage(enemy_controller);

	end, function(retval)
		return retval;
	end);

	sdk.hook(dead_method, function(args)
		local enemy_controller = sdk.to_managed_object(args[2]);
		this.on_dead(enemy_controller);

	end, function(retval)
		return retval;
	end);
end

return this;