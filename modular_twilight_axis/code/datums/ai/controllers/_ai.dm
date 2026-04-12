/datum/ai_controller/process(delta_time)
	if(!able_to_run())
		walk(pawn, 0)
		return

	var/has_combat_context = blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET) || blackboard_key_exists(BB_BASIC_MOB_RETREAT_TILE)

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

	SEND_SIGNAL(src, COMSIG_AI_CONTROLLER_PICKED_BEHAVIORS, current_behaviors, planned_behaviors)

	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		var/action_delta_time = max(current_behavior.get_cooldown(src) * 0.1, delta_time)
		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_EXECUTE_ALONGSIDE))
			continue
		if(behavior_cooldowns[current_behavior] > world.time)
			continue
		ProcessBehavior(action_delta_time, current_behavior)

	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		var/action_delta_time = max(current_behavior.get_cooldown(src) * 0.1, delta_time)

		if(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_MOVEMENT)
			if(!current_movement_target)
				current_behavior.finish_action(src, FALSE)
				return

			var/mob/living/moving_pawn = pawn
			var/obj/item/held_for_reach = null
			if(iscarbon(moving_pawn))
				var/mob/living/carbon/carbon_pawn = moving_pawn
				held_for_reach = carbon_pawn.get_active_held_item()

			var/can_reach = !(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_REACH) || moving_pawn.CanReach(current_movement_target, held_for_reach)

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

			var/effective_required_distance = current_behavior.required_distance
			if(iscarbon(moving_pawn))
				var/mob/living/carbon/carbon_pawn = moving_pawn
				var/intent_reach = carbon_pawn.used_intent?.reach || 1
				if(intent_reach > effective_required_distance)
					effective_required_distance = intent_reach

			if(((can_reach && effective_required_distance >= get_dist(moving_pawn, current_movement_target))) || failed_sneak_check > 4)
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
