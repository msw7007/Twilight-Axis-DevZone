/datum/ai_planning_subtree/find_captive_loot

/datum/ai_planning_subtree/find_captive_loot/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return

	var/list/captive_loot = controller.blackboard[BB_HUMAN_NPC_CAPTURE_LOOT]
	if(!islist(captive_loot) || !length(captive_loot))
		return

	if(human_npc_has_nearby_active_hostiles(pawn))
		return

	controller.queue_behavior(/datum/ai_behavior/regear_from_captive_loot, BB_HUMAN_NPC_CAPTURE_LOOT)
	return SUBTREE_RETURN_FINISH_PLANNING
