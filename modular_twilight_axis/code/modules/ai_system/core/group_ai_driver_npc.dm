/datum/group_ai_driver/carbon_npc
	owner = null

/datum/group_ai_driver/carbon_npc/set_target(atom/target)
	return TRUE

/datum/group_ai_driver/carbon_npc/do_melee(atom/target)
	var/mob/living/carbon/C = owner
	if(!istype(C) || !can_act() || QDELETED(target))
		return FALSE

	C.ClickOn(target, null)
	return TRUE

/datum/group_ai_driver/carbon_npc/do_ranged(atom/target)
	var/mob/living/carbon/C = owner
	if(!istype(C) || !can_act() || QDELETED(target))
		return FALSE

	return FALSE
