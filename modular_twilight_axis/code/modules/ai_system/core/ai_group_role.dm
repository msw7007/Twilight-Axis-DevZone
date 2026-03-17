// =====================================================================
//  Base group role — override per species.
// =====================================================================

/datum/ai_group_role
	var/id = "base"
	var/name = "base"
	var/priority = 0
	var/max_per_group = 0
	var/min_group_size = 1
	var/list/comm_messages  // assoc: intent = list("msg1", "msg2", ...)

/datum/ai_group_role/proc/is_valid(mob/living/M)
	return TRUE

/datum/ai_group_role/proc/on_assigned(datum/ai_group/group, mob/living/M)
	return

/datum/ai_group_role/proc/apply_bb(datum/ai_controller/C, datum/ai_group/group, mob/living/M)
	C.set_blackboard_key(BB_GROUP_ROLE, id)

/datum/ai_group_role/proc/get_comm_message(mob/living/M, intent)
	if(!comm_messages || !comm_messages[intent])
		return null
	return pick(comm_messages[intent])
