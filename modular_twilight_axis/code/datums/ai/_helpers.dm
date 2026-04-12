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
