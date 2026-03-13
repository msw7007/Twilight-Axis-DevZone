/datum/group_ai_driver/simple_hostile
	owner = null

/datum/group_ai_driver/simple_hostile/set_target(atom/target)
	var/mob/living/simple_animal/hostile/H = owner
	if(!istype(H))
		return FALSE
	if(target)
		H.GiveTarget(target)
	return TRUE

/datum/group_ai_driver/simple_hostile/do_melee(atom/target)
	var/mob/living/simple_animal/hostile/H = owner
	if(!istype(H) || !can_act() || QDELETED(target))
		return FALSE

	set_target(target)
	H.ClickOn(target, null)
	return TRUE

/datum/group_ai_driver/simple_hostile/do_ranged(atom/target)
	var/mob/living/simple_animal/hostile/H = owner
	if(!istype(H) || !can_act() || QDELETED(target))
		return FALSE
	if(!H.ranged)
		return FALSE

	set_target(target)
	H.OpenFire(target)
	return TRUE

/datum/group_ai_driver/simple_hostile/do_special(atom/target)
	return FALSE
