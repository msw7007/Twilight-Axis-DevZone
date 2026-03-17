// =====================================================================
//  AI Group — thin coordinator. Writes BB keys, never controls behavior.
// =====================================================================

GLOBAL_LIST_EMPTY(active_ai_groups)

// ========================= UTILS =========================

/proc/group_ai_is_deadish(mob/living/M)
	if(!M || QDELETED(M))
		return TRUE
	return M.stat == DEAD

/proc/group_ai_is_crit(mob/living/M)
	if(!M || QDELETED(M) || M.stat == DEAD)
		return FALSE
	if(M.stat >= UNCONSCIOUS)
		return TRUE
	if(M.maxHealth > 0 && M.health < M.maxHealth * GROUP_AI_CRIT_THRESHOLD)
		return TRUE
	return FALSE

/proc/group_ai_threat_score(mob/living/target)
	if(!target)
		return 0
	. = 10
	if(target.client)
		. += 50
	if(target.stat >= UNCONSCIOUS)
		. -= 40

// ========================= GROUP =========================

/datum/ai_group
	// Config — override in subtypes per species
	var/cohesion_range = 7
	var/list/role_paths = list()
	var/list/tactic_paths = list()
	// State
	var/list/members = list()
	var/list/member_roles = list()
	var/list/tactics = list()
	var/list/roles = list()
	var/list/enemies = list()
	var/datum/ai_tactic/active_tactic
	var/mob/living/focus_target
	var/sealed = FALSE
	var/last_update = 0
	var/last_comm_time = 0
	var/last_comm_intent

/datum/ai_group/New()
	. = ..()
	for(var/path in role_paths)
		roles += new path
	for(var/path in tactic_paths)
		tactics += new path
	GLOB.active_ai_groups += src

/datum/ai_group/Destroy()
	for(var/mob/living/M as anything in members)
		clear_bb(M)
	GLOB.active_ai_groups -= src
	members.Cut()
	member_roles.Cut()
	enemies.Cut()
	active_tactic = null
	focus_target = null
	return ..()

// --- Membership ---

/datum/ai_group/proc/add_member(mob/living/M)
	if(!M || QDELETED(M) || (M in members))
		return
	members += M

/datum/ai_group/proc/remove_member(mob/living/M)
	if(!M)
		return
	clear_bb(M)
	members -= M
	member_roles -= M
	if(M == focus_target)
		focus_target = null
	if(!length(members))
		qdel(src)

/datum/ai_group/proc/seal()
	if(sealed)
		return
	sealed = TRUE
	assign_roles()

// --- Roles ---

/datum/ai_group/proc/assign_roles()
	for(var/datum/ai_group_role/role as anything in roles)
		var/count = 0
		for(var/mob/living/M as anything in member_roles)
			if(member_roles[M] == role)
				count++
		if(role.max_per_group > 0 && count >= role.max_per_group)
			continue
		if(length(members) < role.min_group_size)
			continue
		for(var/mob/living/M as anything in members)
			if(QDELETED(M) || member_roles[M])
				continue
			if(!role.is_valid(M))
				continue
			member_roles[M] = role
			role.on_assigned(src, M)
			count++
			if(role.max_per_group > 0 && count >= role.max_per_group)
				break

/datum/ai_group/proc/get_role(mob/living/M)
	return member_roles[M]

// --- Enemies & Focus ---

/datum/ai_group/proc/observe_from(mob/living/source)
	if(!source || QDELETED(source))
		return
	for(var/mob/living/target in view(GROUP_AI_SCAN_RANGE, source))
		if(target == source || (target in members))
			continue
		if(group_ai_is_deadish(target))
			continue
		if(islist(source.faction) && islist(target.faction))
			var/friendly = FALSE
			for(var/F in source.faction)
				if(F in target.faction)
					friendly = TRUE
					break
			if(friendly)
				continue
		enemies[target] = world.time

/datum/ai_group/proc/prune()
	for(var/mob/living/M as anything in members.Copy())
		if(QDELETED(M) || group_ai_is_deadish(M))
			remove_member(M)
	for(var/mob/living/E as anything in enemies.Copy())
		if(group_ai_is_deadish(E) || world.time > enemies[E] + GROUP_AI_LOST_GRACE)
			enemies -= E
	if(!length(members))
		qdel(src)
		return
	var/turf/anchor = get_turf(members[1])
	if(anchor)
		var/max_dist = cohesion_range * GROUP_AI_COHESION_MULT
		for(var/mob/living/M as anything in members.Copy())
			if(get_dist(get_turf(M), anchor) > max_dist)
				remove_member(M)
	if(!length(members))
		qdel(src)

/datum/ai_group/proc/pick_focus()
	focus_target = null
	if(!length(enemies))
		return
	var/cx = 0
	var/cy = 0
	var/n = 0
	for(var/mob/living/M as anything in members)
		var/turf/T = get_turf(M)
		if(T)
			cx += T.x
			cy += T.y
			n++
	if(n)
		cx /= n
		cy /= n
	var/best = -INFINITY
	for(var/mob/living/E as anything in enemies)
		var/score = group_ai_threat_score(E)
		if(n)
			var/turf/T = get_turf(E)
			if(T)
				var/dx = T.x - cx
				var/dy = T.y - cy
				score -= sqrt(dx * dx + dy * dy) * 2
		if(score > best)
			best = score
			focus_target = E

/datum/ai_group/proc/pick_tactic()
	var/datum/ai_tactic/best
	for(var/datum/ai_tactic/T as anything in tactics)
		if(!T.can_run(src))
			continue
		if(!best || T.priority > best.priority)
			best = T
	if(best != active_tactic)
		active_tactic = best

// --- Sync ---

/datum/ai_group/proc/update(force = FALSE)
	if(!force && world.time < last_update + GROUP_AI_UPDATE_COOLDOWN)
		return
	last_update = world.time
	prune()
	if(!length(members))
		return
	pick_focus()
	pick_tactic()
	for(var/mob/living/M as anything in members)
		write_bb(M)
	// Communication — fires directly after tactic is set
	if(active_tactic)
		do_comm()

/datum/ai_group/proc/write_bb(mob/living/M)
	if(!M || QDELETED(M) || !M.ai_controller)
		return
	var/datum/ai_controller/C = M.ai_controller
	var/datum/ai_group_role/role = get_role(M)
	C.clear_blackboard_key(BB_GROUP_TACTIC)
	C.clear_blackboard_key(BB_GROUP_SHOULD_NOT_KILL)
	C.clear_blackboard_key(BB_GROUP_CAN_CAPTURE)
	C.set_blackboard_key(BB_GROUP_REF, src)
	C.set_blackboard_key(BB_GROUP_FOCUS_TARGET, focus_target)
	if(role)
		role.apply_bb(C, src, M)
	if(active_tactic)
		active_tactic.apply_bb(C, src, M, role)

/datum/ai_group/proc/clear_bb(mob/living/M)
	if(!M || QDELETED(M) || !M.ai_controller)
		return
	var/datum/ai_controller/C = M.ai_controller
	C.clear_blackboard_key(BB_GROUP_REF)
	C.clear_blackboard_key(BB_GROUP_ROLE)
	C.clear_blackboard_key(BB_GROUP_TACTIC)
	C.clear_blackboard_key(BB_GROUP_FOCUS_TARGET)
	C.clear_blackboard_key(BB_GROUP_SHOULD_NOT_KILL)
	C.clear_blackboard_key(BB_GROUP_CAN_CAPTURE)

// --- Communication ---

/datum/ai_group/proc/do_comm()
	if(!active_tactic)
		return
	var/intent = active_tactic.get_comm_intent()
	if(!intent)
		return
	if(world.time < last_comm_time + GROUP_AI_SIGNAL_COOLDOWN)
		return
	if(intent == last_comm_intent)
		return
	last_comm_time = world.time
	last_comm_intent = intent
	for(var/mob/living/M as anything in members)
		var/datum/ai_group_role/role = get_role(M)
		if(!role)
			continue
		var/message = role.get_comm_message(M, intent)
		if(message)
			var/msg = "<b>[M]</b> " + message
			M.visible_message(msg, runechat_message = message)
