// Group AI — profile: source of truth per species.
// Defines roles, special abilities, communication.

/datum/group_ai_profile
	var/id            = "generic"
	var/role_flags    = GROUP_AI_ROLE_MDD
	var/leader_bonus  = 0
	var/morale_weight = 10
	var/can_shoot     = FALSE
	var/can_cocoon    = FALSE
	var/prefers_ranged = FALSE
	var/list/group_tags = list()

// ── Scoring ──

/datum/group_ai_profile/proc/leader_score(mob/living/M)
	if(group_ai_is_deadish(M)) return -1
	return group_ai_health_pct(M) + group_ai_defense_hint(M) * 2 + leader_bonus

/datum/group_ai_profile/proc/tank_score(mob/living/M)
	var/s = group_ai_defense_hint(M) * 3
	if(role_flags & GROUP_AI_ROLE_TANK)
		s += 50 + group_ai_health_pct(M)
	if(group_ai_has_shield(M))
		s += 30
	return s

/datum/group_ai_profile/proc/control_score(mob/living/M)
	var/s = group_ai_speed_hint(M) * 15
	if(role_flags & GROUP_AI_ROLE_CONTROL)
		s += 50
	return s

/datum/group_ai_profile/proc/ranged_score(mob/living/M)
	if(!can_shoot) return 0
	return 80

/datum/group_ai_profile/proc/capable_of(flag)
	return !!(role_flags & flag)

// ── Execution: profile tells HOW to queue species-specific actions ──
// Return TRUE = handled. FALSE = not capable.

/datum/group_ai_profile/proc/execute_melee(datum/ai_controller/C, mob/living/pawn, atom/target)
	C.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	C.queue_behavior(/datum/ai_behavior/basic_melee_attack, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return TRUE

/datum/group_ai_profile/proc/execute_ranged(datum/ai_controller/C, mob/living/pawn, atom/target, list/friendlies)
	return FALSE

/datum/group_ai_profile/proc/execute_control(datum/ai_controller/C, mob/living/pawn, atom/target)
	return execute_melee(C, pawn, target)

// ── Communication: per ТЗ emotes when receiving order ──

/datum/group_ai_profile/proc/announce_order(mob/living/M, task)
	return

/datum/group_ai_profile/proc/leader_react(mob/living/M, event_id)
	return

// ──────────────────────────────────────────────────────────────────────────────
// Mirespider profiles
// ──────────────────────────────────────────────────────────────────────────────

/datum/group_ai_profile/mirespider_small
	id          = "mirespider_small"
	role_flags  = GROUP_AI_ROLE_MDD | GROUP_AI_ROLE_CONTROL
	morale_weight = 8
	group_tags  = list("spiders")

/datum/group_ai_profile/mirespider_small/announce_order(mob/living/M, task)
	if(!hascall(M, "emote")) return
	switch(task)
		if(GROUP_AI_TASK_ATTACK_MELEE) call(M, "emote")("hisses and closes in")
		if(GROUP_AI_TASK_CONTROL)      call(M, "emote")("circles for an opening")
		if(GROUP_AI_TASK_RETREAT)       call(M, "emote")("skitters away")
		if(GROUP_AI_TASK_GUARD_LEADER)  call(M, "emote")("guards the pack")

/datum/group_ai_profile/mirespider_lurker
	id             = "mirespider_lurker"
	role_flags     = GROUP_AI_ROLE_RDD | GROUP_AI_ROLE_TANK | GROUP_AI_ROLE_LEADER
	leader_bonus   = 40
	morale_weight  = 14
	can_shoot      = TRUE
	can_cocoon     = TRUE
	prefers_ranged = TRUE
	group_tags     = list("spiders")

/datum/group_ai_profile/mirespider_lurker/execute_ranged(datum/ai_controller/C, mob/living/pawn, atom/target, list/friendlies)
	// LoS check: no friendly fire
	if(islist(friendlies) && !group_ai_can_shoot_at(pawn, target, friendlies))
		return TRUE  // Hold fire, but handled
	// Cocoon escalation: downed target
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat || L.getBruteLoss() > 500)
			C.set_blackboard_key(BB_BASIC_MOB_COCOON_TARGET, L)
			C.queue_behavior(/datum/ai_behavior/cocoon_target, BB_BASIC_MOB_COCOON_TARGET)
			return TRUE
	// Shoot
	C.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	C.queue_behavior(/datum/ai_behavior/basic_ranged_attack, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return TRUE

/datum/group_ai_profile/mirespider_lurker/announce_order(mob/living/M, task)
	if(!hascall(M, "emote")) return
	switch(task)
		if(GROUP_AI_TASK_SUPPORT)  call(M, "emote")("tracks a target")
		if(GROUP_AI_TASK_HOLD_SLOT) call(M, "emote")("plants itself firmly")
		if(GROUP_AI_TASK_RETREAT)   call(M, "emote")("retreats cautiously")

/datum/group_ai_profile/mirespider_lurker/leader_react(mob/living/M, event_id)
	if(!hascall(M, "emote")) return
	switch(event_id)
		if(GROUP_AI_EVENT_SPOTTED)  call(M, "emote")("rises up and directs the pack")
		if(GROUP_AI_EVENT_DIED)     call(M, "emote")("shrieks furiously")
		if(GROUP_AI_EVENT_STUNNED)  call(M, "emote")("screeches in alarm")
		if(GROUP_AI_EVENT_DAMAGED)  call(M, "emote")("hisses aggressively")
		if(GROUP_AI_EVENT_LOST)     call(M, "emote")("surveys the area warily")

/datum/group_ai_profile/mirespider_paralytic
	id          = "mirespider_paralytic"
	role_flags  = GROUP_AI_ROLE_MDD | GROUP_AI_ROLE_CONTROL
	morale_weight = 9
	can_cocoon  = TRUE
	group_tags  = list("spiders")

/datum/group_ai_profile/mirespider_paralytic/execute_control(datum/ai_controller/C, mob/living/pawn, atom/target)
	// Paralytic's control: approach and bite (venom injection via AttackingTarget override)
	// If downed → cocoon
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat || L.getBruteLoss() > 500)
			C.set_blackboard_key(BB_BASIC_MOB_COCOON_TARGET, L)
			C.queue_behavior(/datum/ai_behavior/cocoon_target, BB_BASIC_MOB_COCOON_TARGET)
			return TRUE
	return execute_melee(C, pawn, target)

/datum/group_ai_profile/mirespider_paralytic/announce_order(mob/living/M, task)
	if(!hascall(M, "emote")) return
	switch(task)
		if(GROUP_AI_TASK_ATTACK_MELEE) call(M, "emote")("hisses menacingly")
		if(GROUP_AI_TASK_CONTROL)      call(M, "emote")("moves to flank")
		if(GROUP_AI_TASK_RETREAT)       call(M, "emote")("withdraws")