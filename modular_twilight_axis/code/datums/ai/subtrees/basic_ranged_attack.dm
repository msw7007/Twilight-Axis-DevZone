/datum/ai_behavior/basic_ranged_attack/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()
	var/mob/living/simple_animal/basic_mob = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	var/datum/targetting_datum/targetting_datum = controller.blackboard[targetting_datum_key]

	if(isliving(target))
		var/mob/living/living_target = target
		if(human_npc_should_not_attack_target(living_target))
			finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
			return

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
