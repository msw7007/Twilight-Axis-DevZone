/datum/ai_behavior/human_npc_deliver_captive
	action_cooldown = 0.5 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT
	required_distance = 1
	var/original_max_target_distance = null
	var/raised_max_target_distance = FALSE

/datum/ai_behavior/human_npc_deliver_captive/setup(datum/ai_controller/controller, captive_key, destination_key)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return FALSE

	var/mob/living/carbon/human/captive = controller.blackboard[captive_key]
	if(!istype(captive))
		return FALSE

	if(!human_npc_is_valid_delivery_captive(captive))
		return FALSE

	var/turf/destination = controller.blackboard[destination_key]
	if(!destination)
		destination = human_npc_get_captive_delivery_turf(pawn)
		if(!destination)
			return FALSE
		controller.set_blackboard_key(destination_key, destination)

	if(isnum(controller.max_target_distance))
		original_max_target_distance = controller.max_target_distance
		if(controller.max_target_distance < 1000)
			controller.max_target_distance = 1000
			raised_max_target_distance = TRUE

	if(captive.loc == pawn)
		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_CARRYING)
		set_movement_target(controller, destination)
		return TRUE

	if(pawn.Adjacent(captive))
		if(!human_npc_pick_up_captive(pawn, captive))
			return FALSE

		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_CARRYING)
		set_movement_target(controller, destination)
		return TRUE

	set_movement_target(controller, captive)
	return TRUE

/datum/ai_behavior/human_npc_deliver_captive/perform(delta_time, datum/ai_controller/controller, captive_key, destination_key)
	. = ..()

	if(!captive_key)
		captive_key = BB_HUMAN_NPC_CAPTURE_TARGET
	if(!destination_key)
		destination_key = BB_HUMAN_NPC_CAPTURE_DESTINATION

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		finish_action(controller, FALSE, captive_key, destination_key)
		return

	var/mob/living/carbon/human/captive = controller.blackboard[captive_key]
	if(!istype(captive))
		finish_action(controller, FALSE, captive_key, destination_key)
		return

	if(!human_npc_is_valid_delivery_captive(captive))
		finish_action(controller, FALSE, captive_key, destination_key)
		return

	var/turf/destination = controller.blackboard[destination_key]
	if(!destination)
		destination = human_npc_get_captive_delivery_turf(pawn)
		if(!destination)
			finish_action(controller, FALSE, captive_key, destination_key)
			return
		controller.set_blackboard_key(destination_key, destination)

	if(captive.loc != pawn)
		if(!pawn.Adjacent(captive))
			set_movement_target(controller, captive)
			return

		if(!human_npc_pick_up_captive(pawn, captive))
			finish_action(controller, FALSE, captive_key, destination_key)
			return

		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_CARRYING)
		set_movement_target(controller, destination)
		return

	controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_CARRYING)

	if(get_dist(pawn, destination) > required_distance)
		set_movement_target(controller, destination)
		return

	if(!human_npc_drop_off_captive(pawn, captive, get_turf(pawn) || destination))
		finish_action(controller, FALSE, captive_key, destination_key)
		return

	finish_action(controller, TRUE, captive_key, destination_key)

/datum/ai_behavior/human_npc_deliver_captive/finish_action(datum/ai_controller/controller, succeeded, captive_key, destination_key)
	. = ..()

	if(raised_max_target_distance && !isnull(original_max_target_distance))
		controller.max_target_distance = original_max_target_distance

	if(!captive_key)
		captive_key = BB_HUMAN_NPC_CAPTURE_TARGET
	if(!destination_key)
		destination_key = BB_HUMAN_NPC_CAPTURE_DESTINATION

	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/carbon/human/captive = controller.blackboard[captive_key]

	if(succeeded)
		controller.clear_blackboard_key(captive_key)
		controller.clear_blackboard_key(destination_key)
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_LOOT)
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE)
		return

	if(istype(pawn) && istype(captive) && captive.loc == pawn)
		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_CARRYING)
		return

	if(istype(captive) && human_npc_is_valid_delivery_captive(captive))
		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_DELIVER)
		return

	controller.clear_blackboard_key(captive_key)
	controller.clear_blackboard_key(destination_key)
	controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_LOOT)
	controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE)
