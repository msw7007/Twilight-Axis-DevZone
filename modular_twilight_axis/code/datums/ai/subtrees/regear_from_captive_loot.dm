/datum/ai_behavior/regear_from_captive_loot

/datum/ai_behavior/regear_from_captive_loot/perform(delta_time, datum/ai_controller/controller, loot_key)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		finish_action(controller, FALSE, loot_key)
		return

	var/list/captive_loot = controller.blackboard[loot_key]
	if(!islist(captive_loot) || !length(captive_loot))
		finish_action(controller, FALSE, loot_key)
		return

	var/list/held_items = list()
	for(var/i in 1 to 2)
		var/obj/item/I = pawn.get_item_for_held_index(i)
		if(I)
			held_items += I
			pawn.dropItemToGround(I)

	captive_loot = human_npc_cleanup_capture_loot(captive_loot, get_turf(pawn), 1)
	for(var/obj/item/I as anything in captive_loot)
		if(QDELETED(I) || !isturf(I.loc))
			continue

		if(!istype(I, /obj/item/clothing))
			continue

		var/score = human_npc_get_armor_score(pawn, I)
		if(score <= 0)
			continue

		var/obj/item/current = human_npc_get_equipped_competitor(pawn, I)
		if(current)
			var/current_score = human_npc_get_armor_score(pawn, current)
			if(current_score >= score)
				continue

			pawn.dropItemToGround(current)

		I.forceMove(pawn)
		if(!pawn.equip_to_appropriate_slot(I))
			I.forceMove(get_turf(pawn))

	for(var/obj/item/I as anything in captive_loot)
		if(QDELETED(I))
			continue

		if(human_npc_is_capture_consumable(I))
			human_npc_try_store_consumable(pawn, I)

	for(var/obj/item/I as anything in held_items)
		if(QDELETED(I))
			continue

		if(get_dist(pawn, I) <= 1)
			pawn.put_in_hands(I)

	controller.clear_blackboard_key(loot_key)
	controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_DELIVER)
	finish_action(controller, TRUE, loot_key)
