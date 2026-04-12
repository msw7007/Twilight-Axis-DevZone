/datum/ai_behavior/basic_ranged_attack/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()
	var/mob/living/simple_animal/basic_mob = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	var/datum/targetting_datum/targetting_datum = controller.blackboard[targetting_datum_key]

	if(!targetting_datum.can_attack(basic_mob, target))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	var/atom/hiding_target = targetting_datum.find_hidden_mobs(basic_mob, target)

	controller.set_blackboard_key(hiding_location_key, hiding_target)

	var/atom/attack_target = hiding_target || target

	basic_mob.face_atom()

	if(get_dist(basic_mob, target) <= 1)
		if(world.time >= basic_mob.melee_cooldown)
			if(length(basic_mob.possible_a_intents))
				basic_mob.a_intent = pick(basic_mob.possible_a_intents)
			basic_mob.ClickOn(attack_target, list())

		var/turf/retreat_turf = find_retreat_turf(controller, target)
		if(retreat_turf)
			basic_mob.Move(retreat_turf)
			basic_mob.face_atom(target)

		finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)
		return

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

	for(var/direction in list(NORTH, SOUTH, EAST, WEST))
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
		for(var/direction in list(NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
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
