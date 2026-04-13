/proc/human_npc_target_is_undead_bind_blocked(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/H = target
	if(!H.mind)
		return FALSE
	if(H.mind.has_antag_datum(/datum/antagonist/zombie))
		return TRUE
	if(H.mind.has_antag_datum(/datum/antagonist/skeleton))
		return TRUE
	if(H.mind.has_antag_datum(/datum/antagonist/lich))
		return TRUE
	return FALSE

/proc/human_npc_target_already_bound(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/H = target
	if(H.handcuffed || H.legcuffed)
		return TRUE
	return FALSE

/proc/human_npc_target_yielded(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/H = target
	return H.surrendering

/proc/human_npc_is_valid_bind_target(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE
	if(human_npc_target_already_bound(target))
		return FALSE
	if(human_npc_target_yielded(target))
		return TRUE
	if(target.stat == DEAD)
		if(human_npc_target_is_undead_bind_blocked(target))
			return FALSE
		return TRUE
	if(target.stat >= UNCONSCIOUS)
		return TRUE
	return FALSE

/proc/human_npc_should_not_attack_target(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE
	return human_npc_target_already_bound(target)

/proc/human_npc_should_strip_item(obj/item/I, mob/living/carbon/human/target)
	if(!I || QDELETED(I))
		return FALSE
	if(!target)
		return FALSE

	if(istype(I, /obj/item/bodypart))
		return FALSE
	if(istype(I, /obj/item/organ))
		return FALSE

	if(target.handcuffed && I == target.handcuffed)
		return FALSE
	if(target.legcuffed && I == target.legcuffed)
		return FALSE

	return TRUE

/proc/human_npc_collect_strip_items(mob/living/carbon/human/target)
	var/list/storage_items = list()
	var/list/other_items = list()

	if(!target)
		return list()

	for(var/obj/item/I in target)
		if(!human_npc_should_strip_item(I, target))
			continue

		if(length(I.contents))
			storage_items += I
		else
			other_items += I

	var/list/result = list()
	result += storage_items
	result += other_items
	return result

/proc/human_npc_dump_storage_contents(obj/item/container_item, turf/drop_turf)
	if(!container_item || QDELETED(container_item) || !drop_turf)
		return

	var/list/to_dump = list()
	for(var/atom/movable/AM in container_item)
		to_dump += AM

	for(var/atom/movable/AM in to_dump)
		if(QDELETED(AM))
			continue

		if(istype(AM, /obj/item))
			var/obj/item/nested_item = AM
			if(length(nested_item.contents))
				human_npc_dump_storage_contents(nested_item, drop_turf)

		AM.forceMove(drop_turf)

/proc/human_npc_strip_bound_target_equipment(mob/living/carbon/human/target, turf/drop_turf)
	if(!target || !drop_turf)
		return

	var/list/strip_items = human_npc_collect_strip_items(target)
	if(!length(strip_items))
		return

	for(var/obj/item/I as anything in strip_items)
		if(QDELETED(I))
			continue
		if(I.loc != target)
			continue

		if(length(I.contents))
			human_npc_dump_storage_contents(I, drop_turf)

		target.dropItemToGround(I)
