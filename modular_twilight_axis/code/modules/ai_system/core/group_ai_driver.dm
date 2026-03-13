/datum/group_ai_driver
	var/mob/living/owner

/datum/group_ai_driver/New(mob/living/_owner)
	..()
	owner = _owner

/datum/group_ai_driver/proc/can_act()
	if(QDELETED(owner))
		return FALSE
	if(owner.stat >= UNCONSCIOUS)
		return FALSE
	if(owner.incapacitated(ignore_restraints = TRUE))
		return FALSE
	if(!isturf(owner.loc))
		return FALSE
	return TRUE

/datum/group_ai_driver/proc/get_dist_to(atom/target)
	if(QDELETED(owner) || QDELETED(target))
		return INFINITY
	return get_dist(owner, target)

/datum/group_ai_driver/proc/set_target(atom/target)
	return TRUE

/datum/group_ai_driver/proc/step_forward(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	step_towards(owner, target)
	return TRUE

/datum/group_ai_driver/proc/step_backward(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	step_away(owner, target)
	return TRUE

/datum/group_ai_driver/proc/do_melee(atom/target)
	return FALSE

/datum/group_ai_driver/proc/do_ranged(atom/target)
	return FALSE

/datum/group_ai_driver/proc/do_special(atom/target)
	return FALSE
