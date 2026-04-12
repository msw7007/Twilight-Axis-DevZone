/datum/ai_behavior/basic_kite
	action_cooldown = 0.2 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/basic_kite/setup(datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()

	var/atom/target = controller.blackboard[hiding_location_key] || controller.blackboard[target_key]
	if(QDELETED(target) || !target)
		return FALSE

	return TRUE


/datum/ai_behavior/basic_kite/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	var/mob/living/simple_animal/M = controller.pawn
	if(!istype(M))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	var/atom/target = controller.blackboard[target_key]
	var/datum/targetting_datum/targetting = controller.blackboard[targetting_datum_key]

	if(QDELETED(target) || !target)
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	if(!targetting.can_attack(M, target))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	var/atom/hiding_target = targetting.find_hidden_mobs(M, target)
	controller.set_blackboard_key(hiding_location_key, hiding_target)

	var/atom/attack_target = hiding_target || target

	// 1. ЕСЛИ МОЖНО — БЬЁМ
	if(world.time >= M.melee_cooldown)
		M.face_atom()
		M.a_intent = pick(M.possible_a_intents)
		M.ClickOn(attack_target, list())

	// 2. ПЫТАЕМСЯ ОТСТУПИТЬ
	try_retreat(controller, target)

	finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)
