// =====================================================================
//  Component (join/leave groups) + Subtree bridge (BB writer).
// =====================================================================

// ========================= COMPONENT =========================

/datum/component/ai_group_member
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/ai_group/group
	var/group_path

/datum/component/ai_group_member/Initialize(path)
	. = ..()
	if(!isliving(parent) || !ispath(path))
		return COMPONENT_INCOMPATIBLE
	group_path = path
	addtimer(CALLBACK(src, PROC_REF(join_group)), 2 SECONDS)

/datum/component/ai_group_member/Destroy()
	if(group)
		group.remove_member(parent)
	group = null
	return ..()

/datum/component/ai_group_member/proc/join_group()
	var/mob/living/M = parent
	if(!M || QDELETED(M))
		return
	var/turf/here = get_turf(M)
	if(!here)
		return
	for(var/datum/ai_group/G as anything in GLOB.active_ai_groups)
		if(QDELETED(G) || G.sealed || G.type != group_path)
			continue
		var/turf/there = G.members.len ? get_turf(G.members[1]) : null
		if(there && get_dist(here, there) <= initial(G.cohesion_range))
			group = G
			break
	if(!group)
		group = new group_path()
	group.add_member(M)
	if(!group.sealed)
		addtimer(CALLBACK(group, TYPE_PROC_REF(/datum/ai_group, seal)), 1 SECONDS)

/datum/component/ai_group_member/proc/sync()
	if(!group)
		return
	group.observe_from(parent)
	group.update()

// ========================= SUBTREE BRIDGE =========================
// RULE: NEVER return FINISH_PLANNING. NEVER queue custom behaviors.
// Only modify BB keys that native subtrees already read.

/datum/ai_planning_subtree/group_tactics

/datum/ai_planning_subtree/group_tactics/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!controller?.pawn)
		return
	var/mob/living/pawn = controller.pawn
	var/datum/component/ai_group_member/comp = pawn.GetComponent(/datum/component/ai_group_member)
	if(!comp?.group)
		return

	comp.sync()
	var/datum/ai_group/group = comp.group

	// Read tactic state
	var/tactic_id = controller.blackboard[BB_GROUP_TACTIC]
	var/should_not_kill = controller.blackboard[BB_GROUP_SHOULD_NOT_KILL]
	var/can_capture = controller.blackboard[BB_GROUP_CAN_CAPTURE]
	var/mob/living/focus = controller.blackboard[BB_GROUP_FOCUS_TARGET]

	// Retreat: disengage, but fight back if cornered
	if(tactic_id == GROUP_TACTIC_RETREAT)
		var/mob/living/current = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
		if(current && current.Adjacent(pawn))
			return // enemy in face — fight back
		controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
		return

	// Don't-kill: target in crit → capturer cocoons, others guard
	if(should_not_kill)
		var/mob/living/current = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
		if(isliving(current) && group_ai_is_crit(current))
			if(can_capture)
				controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
				controller.set_blackboard_key(BB_BASIC_MOB_COCOON_TARGET, current)
				return
			// Guard: find nearest non-crit enemy
			var/mob/living/guard_target
			var/best_dist = INFINITY
			for(var/mob/living/E as anything in group.enemies)
				if(E == current || QDELETED(E) || group_ai_is_deadish(E) || group_ai_is_crit(E))
					continue
				var/d = get_dist(pawn, E)
				if(d < best_dist)
					best_dist = d
					guard_target = E
			if(guard_target)
				controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, guard_target)
			else
				controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
			return

	// Focus fire
	if(focus && !QDELETED(focus) && !group_ai_is_deadish(focus))
		controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, focus)
