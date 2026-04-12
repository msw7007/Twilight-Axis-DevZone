/datum/ai_behavior/human_npc_anti_grab
	action_cooldown = 0.2 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1

/datum/ai_behavior/human_npc_anti_grab/setup(datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return FALSE

	var/mob/living/grabber = pawn.pulledby
	if(!(grabber?.grab_state > GRAB_PASSIVE) || !isliving(grabber))
		return FALSE

	controller.set_blackboard_key(target_key, grabber)
	set_movement_target(controller, grabber)
	return TRUE

/datum/ai_behavior/human_npc_anti_grab/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	controller.behavior_cooldowns[src] = world.time + action_cooldown

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	var/mob/living/grabber = pawn.pulledby
	if(!(grabber?.grab_state > GRAB_PASSIVE) || !isliving(grabber))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	var/datum/targetting_datum/td = controller.blackboard[targetting_datum_key]
	if(!td)
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	controller.set_blackboard_key(target_key, grabber)

	if(!td.can_attack(pawn, grabber))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	if(!pawn.Adjacent(grabber))
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	_force_swap_to_offhand(pawn)

	var/atom/hiding_target = td.find_hidden_mobs(pawn, grabber)
	controller.set_blackboard_key(hiding_location_key, hiding_target)

	var/atom/attack_target = hiding_target || grabber
	if(QDELETED(attack_target) || !attack_target)
		finish_action(controller, FALSE, target_key, targetting_datum_key, hiding_location_key)
		return

	pawn.face_atom(grabber)
	pawn.cmode = TRUE
	SEND_SIGNAL(pawn, COMSIG_COMBAT_TARGET_SET, grabber)
	_set_attack_intent(pawn)
	pawn.ClickOn(attack_target, list())

	pawn.execute_resist()

	if(pawn.pulledby == grabber && grabber.grab_state > GRAB_PASSIVE)
		if(_should_kick_grabber(pawn, grabber))
			pawn.try_kick(grabber)

	finish_action(controller, TRUE, target_key, targetting_datum_key, hiding_location_key)

/datum/ai_behavior/human_npc_anti_grab/finish_action(datum/ai_controller/controller, succeeded, target_key, targetting_datum_key, hiding_location_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	if(istype(pawn))
		pawn.cmode = FALSE
		SEND_SIGNAL(pawn, COMSIG_COMBAT_TARGET_SET, FALSE)
	if(!succeeded)
		controller.clear_blackboard_key(target_key)

/datum/ai_behavior/human_npc_anti_grab/proc/_force_swap_to_offhand(mob/living/carbon/human/pawn)
	pawn.swap_hand()

/datum/ai_behavior/human_npc_anti_grab/proc/_set_attack_intent(mob/living/carbon/human/pawn)
	var/list/possible_intents = list()
	for(var/datum/intent/intent as anything in pawn.possible_a_intents)
		if(istype(intent, /datum/intent/unarmed/help) || istype(intent, /datum/intent/unarmed/shove) || istype(intent, /datum/intent/unarmed/grab))
			continue
		possible_intents |= intent

	if(length(possible_intents))
		pawn.a_intent = pick(possible_intents)
		pawn.used_intent = pawn.a_intent

/datum/ai_behavior/human_npc_anti_grab/proc/_should_kick_grabber(mob/living/carbon/human/pawn, mob/living/grabber)
	if(!ishuman(grabber))
		return FALSE

	var/mob/living/carbon/human/human_grabber = grabber

	if(human_grabber.STACON >= HUMAN_NPC_ANTI_GRAB_CON_LIMIT)
		return FALSE

	if(human_grabber.STASTR >= HUMAN_NPC_ANTI_GRAB_STR_LIMIT)
		return FALSE

	if(!pawn.Adjacent(human_grabber))
		return FALSE

	return TRUE
