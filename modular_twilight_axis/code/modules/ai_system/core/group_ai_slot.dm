/datum/group_ai_slot
	var/turf/position
	var/datum/group_ai_host/occupant
	var/index = 0
	var/priority = 0

/datum/group_ai_slot/New(turf/_position, _index)
	..()
	position = _position
	index = _index

/datum/group_ai_slot/proc/is_free()
	return !occupant || QDELETED(occupant)

/datum/group_ai_slot/proc/clear_if_invalid()
	if(is_free())
		occupant = null

/datum/group_ai_slot/proc/is_valid_for_target(atom/target)
	if(QDELETED(position) || QDELETED(target))
		return FALSE
	return get_dist(position, target) <= 1
