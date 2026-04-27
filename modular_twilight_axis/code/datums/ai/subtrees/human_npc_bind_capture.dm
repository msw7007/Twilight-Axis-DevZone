/datum/ai_planning_subtree/human_npc_bind_capture
	var/bind_item_type = /obj/item/rope
	var/datum/ai_behavior/bind_behavior = /datum/ai_behavior/human_npc_bind_target/rope

/datum/ai_planning_subtree/human_npc_bind_capture/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return

	var/mob/living/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!istype(target))
		return

	if(human_npc_is_in_captive_delivery_zone(target, pawn))
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		return

	if(!human_npc_is_valid_bind_target(target))
		return

	if(human_npc_has_nearby_active_hostiles(pawn, target))
		return

	controller.queue_behavior(bind_behavior, BB_BASIC_MOB_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/human_npc_bind_capture/rope
	bind_item_type = /obj/item/rope
	bind_behavior = /datum/ai_behavior/human_npc_bind_target/rope

/datum/ai_planning_subtree/human_npc_bind_capture/chain
	bind_item_type = /obj/item/rope/chain
	bind_behavior = /datum/ai_behavior/human_npc_bind_target/chain
