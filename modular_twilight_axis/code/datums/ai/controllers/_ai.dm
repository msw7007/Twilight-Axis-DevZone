/datum/ai_controller/process(delta_time)
	if(!able_to_run())
		walk(pawn, 0)
		return

	var/has_combat_context = blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET)

	if(!LAZYLEN(current_behaviors) && idle_behavior)
		if(!has_combat_context)
			idle_behavior.perform_idle_behavior(delta_time, src)
			return

	if(current_movement_target)
		if(!isatom(current_movement_target))
			stack_trace("[pawn]'s current movement target is not an atom, rather a [current_movement_target.type]! Did you accidentally set it to a weakref?")
			CancelActions()
			return

		if(get_dist_3d(pawn, current_movement_target) > max_target_distance)
			CancelActions()
			return

	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		var/action_delta_time = max(current_behavior.action_cooldown * 0.1, delta_time)

		if(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_MOVEMENT)
			if(!current_movement_target)
				current_behavior.finish_action(src, FALSE)
				return

			var/mob/living/moving_pawn = pawn
			var/can_reach = !(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_REACH) || moving_pawn.CanReach(current_movement_target)

			if(isliving(current_movement_target))
				var/mob/living/living_pawn = pawn
				var/mob/living/living_target = current_movement_target
				if(living_target.rogue_sneaking)
					if(!living_pawn.npc_detect_sneak(living_target, 0))
						failed_sneak_check++
				else
					failed_sneak_check = 0

			if(prob(8))
				moving_pawn.emote("cidle")

			if(((can_reach && current_behavior.required_distance >= get_dist(moving_pawn, current_movement_target))) || failed_sneak_check > 4)
				if(ai_movement.moving_controllers[src] == current_movement_target)
					ai_movement.stop_moving_towards(src)

				if(failed_sneak_check > 4)
					ai_movement.stop_moving_towards(src)
				failed_sneak_check = 0

				if(behavior_cooldowns[current_behavior] > world.time)
					continue
				ProcessBehavior(action_delta_time, current_behavior)
				return

			else if(ai_movement.moving_controllers[src] != current_movement_target)
				ai_movement.start_moving_towards(src, current_movement_target)

			if(current_behavior.behavior_flags & AI_BEHAVIOR_MOVE_AND_PERFORM)
				if(behavior_cooldowns[current_behavior] > world.time)
					continue
				ProcessBehavior(action_delta_time, current_behavior)
				return
		else
			if(behavior_cooldowns[current_behavior] > world.time)
				continue
			ProcessBehavior(action_delta_time, current_behavior)
			return
