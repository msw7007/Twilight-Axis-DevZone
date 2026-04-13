/datum/ai_behavior/human_npc_bind_target
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1
	var/bind_item_type = /obj/item/rope

/datum/ai_behavior/human_npc_bind_target/setup(datum/ai_controller/controller, target_key)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return FALSE

	var/mob/living/target = controller.blackboard[target_key]
	if(!istype(target))
		return FALSE

	if(!human_npc_is_valid_bind_target(target))
		return FALSE

	set_movement_target(controller, target)
	return TRUE

/datum/ai_behavior/human_npc_bind_target/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		finish_action(controller, FALSE, target_key)
		return

	var/mob/living/target = controller.blackboard[target_key]
	if(!istype(target))
		finish_action(controller, FALSE, target_key)
		return

	if(!human_npc_is_valid_bind_target(target))
		finish_action(controller, FALSE, target_key)
		return

	if(!pawn.Adjacent(target))
		return

	var/obj/item/restored_item = null
	var/obj/item/active_item = pawn.get_active_held_item()
	if(active_item)
		restored_item = active_item
		pawn.dropItemToGround(active_item)

	var/obj/item/binding_item = new bind_item_type(pawn)
	if(!pawn.put_in_hands(binding_item))
		if(binding_item && !QDELETED(binding_item))
			binding_item.forceMove(get_turf(pawn))
		finish_action(controller, FALSE, target_key)
		return

	pawn.cmode = FALSE
	pawn.face_atom(target)
	pawn.ClickOn(target, list())

	if(binding_item && !QDELETED(binding_item))
		if(binding_item.loc == pawn || binding_item.loc == get_turf(pawn))
			qdel(binding_item)

	if(ishuman(target) && human_npc_target_already_bound(target))
		var/mob/living/carbon/human/human_target = target
		human_npc_stabilize_bound_target(human_target)
		var/list/capture_loot = human_npc_strip_bound_target_equipment(human_target, get_turf(human_target))
		if(length(capture_loot))
			controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_LOOT, capture_loot)

	if(restored_item && !QDELETED(restored_item))
		if(restored_item.loc == get_turf(pawn) || restored_item.loc == pawn.loc)
			pawn.put_in_hands(restored_item)

	finish_action(controller, TRUE, target_key)

/datum/ai_behavior/human_npc_bind_target/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	if(istype(pawn))
		pawn.cmode = TRUE
	if(!succeeded)
		controller.clear_blackboard_key(target_key)

/datum/ai_behavior/human_npc_bind_target/rope
	bind_item_type = /obj/item/rope

/datum/ai_behavior/human_npc_bind_target/chain
	bind_item_type = /obj/item/rope/chain
