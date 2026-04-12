/datum/ai_behavior/basic_ranged_attack
	action_cooldown = 0.6 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 3

/datum/ai_behavior/basic_ranged_attack/setup(datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()

	var/atom/retreat_tile = controller.blackboard[BB_BASIC_MOB_RETREAT_TILE]
	if(retreat_tile)
		if(QDELETED(retreat_tile))
			controller.clear_blackboard_key(BB_BASIC_MOB_RETREAT_TILE)
			return FALSE
		set_movement_target(controller, retreat_tile)
		return TRUE

	var/atom/target = controller.blackboard[hiding_location_key] || controller.blackboard[target_key]
	if(QDELETED(target) || !target)
		return FALSE

	set_movement_target(controller, target)
	return TRUE

/datum/ai_behavior/basic_ranged_attack/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()

	var/mob/living/simple_animal/basic_mob = controller.pawn
	if(!istype(basic_mob))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	// Phase 2: finish retreat if we already committed to it.
	var/turf/retreat_tile = controller.blackboard[BB_BASIC_MOB_RETREAT_TILE]
	if(retreat_tile)
		if(QDELETED(retreat_tile))
			controller.clear_blackboard_key(BB_BASIC_MOB_RETREAT_TILE)
			finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)
			return

		if(get_turf(basic_mob) == retreat_tile)
			controller.clear_blackboard_key(BB_BASIC_MOB_RETREAT_TILE)
			finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)
			return

		// Still retreating. Movement layer will handle the step.
		return

	var/atom/target = controller.blackboard[target_key]
	var/datum/targetting_datum/targetting_datum = controller.blackboard[targetting_datum_key]

	if(QDELETED(target) || !target)
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	if(!targetting_datum.can_attack(basic_mob, target))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	var/atom/hiding_target = targetting_datum.find_hidden_mobs(basic_mob, target)
	controller.set_blackboard_key(hiding_location_key, hiding_target)

	var/atom/attack_target = hiding_target || target
	if(QDELETED(attack_target) || !attack_target)
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	// Phase 1: adjacent target -> melee if possible, then commit to retreat.
	if(get_dist(basic_mob, target) <= 1)
		if(world.time >= basic_mob.melee_cooldown)
			basic_mob.face_atom()
			if(length(basic_mob.possible_a_intents))
				basic_mob.a_intent = pick(basic_mob.possible_a_intents)
			basic_mob.ClickOn(attack_target, list())

		var/turf/new_retreat_tile = find_retreat_turf(controller, target)
		if(new_retreat_tile)
			controller.set_blackboard_key(BB_BASIC_MOB_RETREAT_TILE, new_retreat_tile)
			set_movement_target(controller, new_retreat_tile)
			return

		// No valid retreat tile: we still consumed the melee response, so end the action cleanly.
		finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)
		return

	// Normal ranged step.
	basic_mob.face_atom()
	basic_mob.RangedAttack(attack_target)
	finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)

/datum/ai_behavior/basic_ranged_attack/proc/find_retreat_turf(datum/ai_controller/controller, atom/target)
	var/atom/movable/pawn = controller.pawn
	var/turf/current_turf = get_turf(pawn)
	if(!current_turf)
		return null

	var/current_dist = get_dist(current_turf, target)
	var/turf/best_turf = null
	var/best_dist = current_dist

	for(var/direction in GLOB.cardinals)
		var/turf/candidate = get_step(current_turf, direction)
		if(!candidate)
			continue
		if(candidate.density)
			continue

		var/candidate_dist = get_dist(candidate, target)
		if(candidate_dist <= current_dist)
			continue

		if(candidate_dist > best_dist)
			best_turf = candidate
			best_dist = candidate_dist

	if(!best_turf)
		for(var/direction in GLOB.alldirs)
			if(direction in GLOB.cardinals)
				continue

			var/turf/candidate = get_step(current_turf, direction)
			if(!candidate)
				continue
			if(candidate.density)
				continue

			var/candidate_dist = get_dist(candidate, target)
			if(candidate_dist <= current_dist)
				continue

			if(candidate_dist > best_dist)
				best_turf = candidate
				best_dist = candidate_dist

	return best_turf

/datum/ai_behavior/basic_ranged_attack/finish_action(datum/ai_controller/controller, succeeded, target_key, targetting_datum_key, hiding_location_key)
	. = ..()

	if(controller.blackboard[BB_BASIC_MOB_RETREAT_TILE])
		controller.clear_blackboard_key(BB_BASIC_MOB_RETREAT_TILE)

	if(!succeeded)
		controller.clear_blackboard_key(target_key)
