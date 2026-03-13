/datum/group_ai_gate
	var/id = "base"

/datum/group_ai_gate/proc/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	return TRUE

/datum/group_ai_gate/target_exists
	id = "target_exists"

/datum/group_ai_gate/target_exists/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	return !QDELETED(target)

/datum/group_ai_gate/target_living
	id = "target_living"

/datum/group_ai_gate/target_living/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	return isliving(target)

/datum/group_ai_gate/target_prone
	id = "target_prone"

/datum/group_ai_gate/target_prone/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/L = target
	return !(L.mobility_flags & MOBILITY_STAND) || L.stat >= UNCONSCIOUS

/datum/group_ai_gate/target_standing
	id = "target_standing"

/datum/group_ai_gate/target_standing/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/L = target
	return (L.mobility_flags & MOBILITY_STAND) && L.stat < UNCONSCIOUS

/datum/group_ai_gate/in_melee_range
	id = "in_melee_range"

/datum/group_ai_gate/in_melee_range/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(QDELETED(target) || QDELETED(host?.driver?.owner))
		return FALSE
	return host.driver.get_dist_to(target) <= 1

/datum/group_ai_gate/in_ranged_band
	id = "in_ranged_band"
	var/min_range = 2
	var/max_range = 6

/datum/group_ai_gate/in_ranged_band/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(QDELETED(target) || QDELETED(host?.driver?.owner))
		return FALSE
	var/dist = host.driver.get_dist_to(target)
	return dist >= min_range && dist <= max_range

/datum/group_ai_gate/self_low_hp
	id = "self_low_hp"
	var/threshold = 0.35

/datum/group_ai_gate/self_low_hp/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	var/mob/living/owner = host?.get_owner()
	if(QDELETED(owner))
		return FALSE
	return (owner.health / max(owner.maxHealth, 1)) <= threshold

/datum/group_ai_gate/group_low_hp
	id = "group_low_hp"
	var/threshold = 0.75

/datum/group_ai_gate/group_low_hp/check(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(QDELETED(group))
		return FALSE
	return group.get_group_health_ratio() <= threshold
