// =====================================================================
//  Base tactic — override per species.
// =====================================================================

/datum/ai_tactic
	var/id = "base"
	var/name = "base"
	var/priority = 0
	var/comm_intent  // comm intent string, null = no comm

/datum/ai_tactic/proc/can_run(datum/ai_group/group)
	return FALSE

/datum/ai_tactic/proc/apply_bb(datum/ai_controller/C, datum/ai_group/group, mob/living/M, datum/ai_group_role/role)
	C.set_blackboard_key(BB_GROUP_TACTIC, id)

/datum/ai_tactic/proc/get_comm_intent()
	return comm_intent
