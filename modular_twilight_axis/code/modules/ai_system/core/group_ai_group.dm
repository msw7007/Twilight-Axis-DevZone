// Group AI — the brain. All tactical decisions happen here.

// ── Order: what group tells a mob to do ──
/datum/group_ai_order
	var/task           = GROUP_AI_TASK_IDLE
	var/atom/target    = null
	var/turf/slot_turf = null
	var/turf/anchor    = null
	var/role_flags     = GROUP_AI_ROLE_NONE

// ── Target state ──
/datum/group_ai_target_state
	var/mob/living/target                     = null
	var/threat                                = 0
	var/budget                                = 0
	var/last_seen                             = 0
	var/datum/group_ai_formation/formation    = null

// ── Group datum ──
/datum/group_ai_group
	var/id                        = null
	var/key                       = null
	var/shared_faction            = null
	var/datum/group_ai_doctrine/doctrine = null
	var/list/members              = list()
	var/list/profiles             = list()
	var/list/orders               = list()
	var/list/target_states        = list()
	var/list/role_map             = list()
	var/mob/living/leader         = null
	var/morale                    = 100
	var/morale_state              = GROUP_AI_MORALE_STEADY
	var/last_pulse                = 0
	var/last_reacquire            = 0
	var/leader_dead_at            = 0
	var/last_damage_emote         = 0

/datum/group_ai_group/New(datum/group_ai_doctrine/doc)
	..()
	doctrine = doc || new /datum/group_ai_doctrine()
	id = "g_[world.time]_[rand(1000,999999)]"
	group_ai_groups += src

/datum/group_ai_group/Destroy(force, ...)
	for(var/mob/living/M as anything in members)
		if(group_ai_membership[M] == src)
			group_ai_membership -= M
	members.Cut()
	profiles.Cut()
	orders.Cut()
	target_states.Cut()
	group_ai_groups -= src
	return ..()

// ── Membership ──

/datum/group_ai_group/proc/living_count()
	var/c = 0
	for(var/mob/living/M as anything in members)
		if(!group_ai_is_deadish(M)) c++
	return c

/datum/group_ai_group/proc/add_member(mob/living/M)
	if(!M || QDELETED(M)) return
	if(!(M in members))
		members += M
		profiles[M] = doctrine.profile_for(M)
	group_ai_membership[M] = src
	if(!shared_faction && islist(M.faction) && length(M.faction))
		shared_faction = M.faction[1]

/datum/group_ai_group/proc/remove_member(mob/living/M)
	if(!M) return
	members -= M
	profiles -= M
	orders -= M
	role_map -= M
	if(group_ai_membership[M] == src)
		group_ai_membership -= M
	if(leader == M)
		leader = null
		leader_dead_at = world.time
		push_event(GROUP_AI_EVENT_LEADER_DIED, M)
		morale = max(0, morale - GROUP_AI_MORALE_HIT_LEADER)
	if(!length(members))
		qdel(src)

// ── Events ──

/datum/group_ai_group/proc/push_event(event_id, atom/payload)
	if(leader && !group_ai_is_deadish(leader))
		var/datum/group_ai_profile/P = profiles[leader]
		if(P)
			if(event_id == GROUP_AI_EVENT_DAMAGED)
				if(world.time < last_damage_emote + GROUP_AI_EMOTE_COOLDOWN) return
				last_damage_emote = world.time
			P.leader_react(leader, event_id)

/datum/group_ai_group/proc/observe_target(mob/living/M, mob/living/T)
	if(!doctrine.is_valid_enemy(src, M, T)) return
	var/datum/group_ai_target_state/S = target_states[T]
	if(!S)
		S = new
		S.target = T
		target_states[T] = S
		push_event(GROUP_AI_EVENT_SPOTTED, T)
	S.last_seen = world.time

/datum/group_ai_group/proc/member_damaged(mob/living/M)
	morale = max(0, morale - GROUP_AI_MORALE_HIT_DAMAGE)
	push_event(GROUP_AI_EVENT_DAMAGED, M)

/datum/group_ai_group/proc/member_stunned(mob/living/M)
	morale = max(0, morale - GROUP_AI_MORALE_HIT_STUN)
	push_event(GROUP_AI_EVENT_STUNNED, M)

/datum/group_ai_group/proc/member_died(mob/living/M)
	morale = max(0, morale - GROUP_AI_MORALE_HIT_DEATH)
	push_event(GROUP_AI_EVENT_DIED, M)
	remove_member(M)

// ── Main pulse ──

/datum/group_ai_group/proc/try_pulse(force = FALSE)
	cleanup_dead()
	if(QDELETED(src) || !length(members)) return
	if(!force && world.time < last_pulse + doctrine.pulse_interval) return
	last_pulse = world.time
	refresh_leader()
	if(!leader)
		set_all_idle()
		return
	if(world.time >= last_reacquire + doctrine.reacquire_interval)
		refresh_targets()
	refresh_morale()
	assign_roles()
	build_formations()
	publish_orders()

/datum/group_ai_group/proc/cleanup_dead()
	for(var/mob/living/M as anything in members.Copy())
		if(group_ai_is_deadish(M))
			remove_member(M)

// ── Leader election (per ТЗ: highest HP+defense) ──

/datum/group_ai_group/proc/refresh_leader()
	if(leader && !group_ai_is_deadish(leader)) return
	if(leader_dead_at && world.time < leader_dead_at + GROUP_AI_LEADER_REASSIGN_DELAY)
		leader = null
		return
	var/mob/living/best = null
	var/best_score = -1e30
	for(var/mob/living/M as anything in members)
		if(group_ai_is_deadish(M)) continue
		var/datum/group_ai_profile/P = profiles[M]
		if(!P) continue
		var/s = P.leader_score(M)
		if(s > best_score)
			best_score = s
			best = M
	leader = best

// ── Targets (per ТЗ: proportional budget by threat) ──

/datum/group_ai_group/proc/refresh_targets()
	last_reacquire = world.time
	// Prune dead/lost
	for(var/mob/living/T as anything in target_states)
		var/datum/group_ai_target_state/S = target_states[T]
		if(group_ai_is_deadish(T) || world.time > S.last_seen + doctrine.lost_target_grace)
			if(!group_ai_is_deadish(T))
				push_event(GROUP_AI_EVENT_LOST, T)
			target_states -= T
	// Score targets
	var/list/scores = list()
	for(var/mob/living/T as anything in target_states)
		var/total = 0
		for(var/mob/living/M as anything in members)
			if(!group_ai_is_deadish(M))
				total += doctrine.target_score(src, M, T)
		if(total > 0)
			scores[T] = total
			target_states[T].threat = total
	// Select top N
	var/list/sorted = group_ai_sort_desc(scores)
	var/max_t = doctrine.max_targets(src)
	var/list/selected = list()
	for(var/mob/living/T as anything in sorted)
		if(length(selected) >= max_t) break
		selected += T
	// Proportional budget
	var/total_threat = 0
	for(var/mob/living/T as anything in selected)
		total_threat += max(1, round(target_states[T].threat))
	var/fighters = max(0, living_count() - 1)
	for(var/mob/living/T as anything in selected)
		var/datum/group_ai_target_state/S = target_states[T]
		if(total_threat > 0)
			S.budget = max(1, round((S.threat / total_threat) * fighters))
		else
			S.budget = max(1, round(fighters / max(1, length(selected))))

// ── Morale ──

/datum/group_ai_group/proc/refresh_morale()
	if(!leader)
		morale = min(morale, 20)
	else if(living_count() > 0)
		morale = clamp(morale + 1, 0, 100)
	if(morale <= 20)      morale_state = GROUP_AI_MORALE_BROKEN
	else if(morale <= 45) morale_state = GROUP_AI_MORALE_SHAKEN
	else                  morale_state = GROUP_AI_MORALE_STEADY

// ── Role assignment (per ТЗ) ──

/datum/group_ai_group/proc/assign_roles()
	role_map.Cut()
	if(leader) role_map[leader] = GROUP_AI_ROLE_LEADER
	var/list/tanks = list()
	var/list/ctrls = list()
	for(var/mob/living/M as anything in members)
		if(group_ai_is_deadish(M) || M == leader) continue
		var/datum/group_ai_profile/P = profiles[M]
		if(!P) continue
		if(P.capable_of(GROUP_AI_ROLE_TANK))    tanks[M] = P.tank_score(M)
		if(P.capable_of(GROUP_AI_ROLE_CONTROL)) ctrls[M] = P.control_score(M)
	var/list/st = group_ai_sort_desc(tanks)
	if(length(st))
		role_map[st[1]] = (role_map[st[1]] || 0) | GROUP_AI_ROLE_TANK
	var/list/sc = group_ai_sort_desc(ctrls)
	if(length(sc) && sc[1] != leader)
		role_map[sc[1]] = (role_map[sc[1]] || 0) | GROUP_AI_ROLE_CONTROL
	for(var/mob/living/M as anything in members)
		if(group_ai_is_deadish(M) || M == leader) continue
		var/datum/group_ai_profile/P = profiles[M]
		if(!P) continue
		if(P.capable_of(GROUP_AI_ROLE_RDD))
			role_map[M] = (role_map[M] || 0) | GROUP_AI_ROLE_RDD
		if(P.capable_of(GROUP_AI_ROLE_MDD))
			role_map[M] = (role_map[M] || 0) | GROUP_AI_ROLE_MDD

// ── Formations ──

/datum/group_ai_group/proc/build_formations()
	for(var/mob/living/T as anything in target_states)
		var/datum/group_ai_target_state/S = target_states[T]
		if(!S.formation)
			S.formation = new
		S.formation.setup(T, ismob(T) ? T.dir : SOUTH)

// ── Order publishing ──

/datum/group_ai_group/proc/set_all_idle()
	for(var/mob/living/M as anything in members)
		var/datum/group_ai_order/O = get_order(M)
		O.task = GROUP_AI_TASK_IDLE
		O.target = null
		O.anchor = get_turf(M)

/datum/group_ai_group/proc/get_order(mob/living/M)
	var/datum/group_ai_order/O = orders[M]
	if(!O)
		O = new
		orders[M] = O
	return O

/datum/group_ai_group/proc/publish_orders()
	// Reset all
	for(var/mob/living/M as anything in members)
		var/datum/group_ai_order/O = get_order(M)
		O.task       = GROUP_AI_TASK_IDLE
		O.target     = null
		O.slot_turf  = null
		O.anchor     = null
		O.role_flags = role_map[M] || GROUP_AI_ROLE_NONE

	if(morale_state == GROUP_AI_MORALE_BROKEN)
		publish_retreat()
		return
	publish_leader()
	publish_target_assignments()
	publish_guards()
	if(morale_state == GROUP_AI_MORALE_SHAKEN)
		publish_low_hp_retreats()
	resolve_chain_movement()
	announce_orders()

/datum/group_ai_group/proc/publish_leader()
	if(!leader) return
	var/datum/group_ai_order/O = get_order(leader)
	O.task   = GROUP_AI_TASK_LEADER_IDLE
	O.anchor = get_turf(leader)

/datum/group_ai_group/proc/publish_retreat()
	for(var/mob/living/M as anything in members)
		var/datum/group_ai_order/O = get_order(M)
		if(M == leader)
			O.task   = GROUP_AI_TASK_LEADER_IDLE
			O.anchor = get_turf(M)
		else
			O.task   = GROUP_AI_TASK_RETREAT
			O.anchor = group_ai_pick_step_away(M, leader || M, 4)

/datum/group_ai_group/proc/publish_target_assignments()
	var/list/scores = list()
	for(var/mob/living/T as anything in target_states)
		var/datum/group_ai_target_state/S = target_states[T]
		if(S.budget > 0) scores[T] = S.threat
	var/list/sorted = group_ai_sort_desc(scores)
	var/list/free = list()
	for(var/mob/living/M as anything in members)
		if(!group_ai_is_deadish(M) && M != leader) free += M
	for(var/mob/living/T as anything in sorted)
		var/datum/group_ai_target_state/S = target_states[T]
		if(!S?.formation) continue
		assign_target(S, free)

/datum/group_ai_group/proc/assign_target(datum/group_ai_target_state/S, list/free)
	var/need = min(length(free), S.budget)
	var/list/assigned = list()

	// Phase 1: prefers_ranged → SUPPORT
	for(var/mob/living/M as anything in free.Copy())
		if(length(assigned) >= need) break
		var/datum/group_ai_profile/P = profiles[M]
		if(!P?.prefers_ranged) continue
		var/datum/group_ai_order/O = get_order(M)
		O.task      = GROUP_AI_TASK_SUPPORT
		O.target    = S.target
		O.anchor    = pick_support_turf(M, S)
		free -= M
		assigned += M

	// Phase 2: fill formation slots
	var/list/slot_seq = list(
		GROUP_AI_SLOT_BACK,
		GROUP_AI_SLOT_FRONT,
		GROUP_AI_SLOT_FRONT_LEFT, GROUP_AI_SLOT_FRONT_RIGHT,
		GROUP_AI_SLOT_LEFT, GROUP_AI_SLOT_RIGHT,
		GROUP_AI_SLOT_BACK_LEFT, GROUP_AI_SLOT_BACK_RIGHT
	)
	for(var/slot_id in slot_seq)
		if(length(assigned) >= need) break
		var/turf/st = S.formation.slot_turfs[slot_id]
		if(!group_ai_is_open_turf(st)) continue
		var/wanted_role = S.formation.slot_roles[slot_id]
		var/mob/living/pick = pick_for_slot(free, slot_id, wanted_role)
		if(!pick) continue
		var/datum/group_ai_order/O = get_order(pick)
		O.target    = S.target
		O.slot_turf = st
		if(slot_id == GROUP_AI_SLOT_BACK)
			O.task = GROUP_AI_TASK_CONTROL
		else if(slot_id == GROUP_AI_SLOT_FRONT && (role_map[pick] & GROUP_AI_ROLE_TANK))
			O.task = GROUP_AI_TASK_HOLD_SLOT
		else
			O.task = GROUP_AI_TASK_ATTACK_MELEE
		free -= pick
		assigned += pick

	// Phase 3: remaining RDD → SUPPORT
	for(var/mob/living/M as anything in free.Copy())
		if(length(assigned) >= need) break
		var/datum/group_ai_profile/P = profiles[M]
		if(!P?.can_shoot) continue
		var/datum/group_ai_order/O = get_order(M)
		O.task   = GROUP_AI_TASK_SUPPORT
		O.target = S.target
		O.anchor = pick_support_turf(M, S)
		free -= M
		assigned += M

/datum/group_ai_group/proc/pick_for_slot(list/free, slot_id, wanted_role)
	var/mob/living/best = null
	var/best_score = -1e30
	for(var/mob/living/M as anything in free)
		var/r = role_map[M] || GROUP_AI_ROLE_NONE
		var/datum/group_ai_profile/P = profiles[M]
		// Back slot: control only
		if(slot_id == GROUP_AI_SLOT_BACK && !(r & GROUP_AI_ROLE_CONTROL)) continue
		var/s = 0
		if(slot_id == GROUP_AI_SLOT_FRONT)
			s += (r & GROUP_AI_ROLE_TANK) ? 800 : ((r & GROUP_AI_ROLE_MDD) ? 200 : 0)
			if(P) s += P.tank_score(M)
		else if(slot_id == GROUP_AI_SLOT_BACK)
			s += 1000
			if(P) s += P.control_score(M)
		else
			s += (r & GROUP_AI_ROLE_MDD) ? 500 : 0
			if(P) s += group_ai_health_pct(M)
		s -= get_dist(M, leader || M) * 2
		if(s > best_score)
			best_score = s
			best = M
	return best

/datum/group_ai_group/proc/pick_support_turf(mob/living/M, datum/group_ai_target_state/S)
	var/turf/best = null
	var/best_s = -1e30
	for(var/turf/T as anything in S.formation.support_ring)
		if(!group_ai_is_open_turf(T)) continue
		var/s = -abs(get_dist(T, S.target) - doctrine.support_range) * 20 - get_dist(M, T)
		if(s > best_s)
			best_s = s
			best = T
	return best || get_turf(M)

// Per ТЗ: unassigned fighters guard leader
/datum/group_ai_group/proc/publish_guards()
	if(!leader) return
	var/list/ring = list()
	var/turf/base = get_turf(leader)
	if(base)
		for(var/dir in group_ai_cardinals())
			var/turf/T = get_step(base, dir)
			if(group_ai_is_open_turf(T)) ring += T
	var/idx = 1
	for(var/mob/living/M as anything in members)
		if(M == leader || group_ai_is_deadish(M)) continue
		var/datum/group_ai_order/O = orders[M]
		if(!O || O.task != GROUP_AI_TASK_IDLE) continue
		if(idx > length(ring)) break
		O.task   = GROUP_AI_TASK_GUARD_LEADER
		O.anchor = ring[idx++]

// Per ТЗ: morale blocks retreat. Only at SHAKEN can low-HP flee.
/datum/group_ai_group/proc/publish_low_hp_retreats()
	for(var/mob/living/M as anything in members)
		if(M == leader || group_ai_is_deadish(M)) continue
		if(group_ai_health_pct(M) > GROUP_AI_RETREAT_HP_PCT) continue
		var/datum/group_ai_order/O = orders[M]
		if(!O || O.task == GROUP_AI_TASK_GUARD_LEADER) continue
		O.task   = GROUP_AI_TASK_RETREAT
		O.target = null
		O.anchor = group_ai_pick_step_away(M, leader || M, 4)

// Per ТЗ: chain movement — Control > Tank > MDD
/datum/group_ai_group/proc/resolve_chain_movement()
	for(var/mob/living/M as anything in members)
		var/datum/group_ai_order/O = orders[M]
		if(!O?.slot_turf || get_turf(M) == O.slot_turf) continue
		var/my_prio = chain_prio(M)
		var/step_dir = get_dir(M, O.slot_turf)
		if(!step_dir) continue
		var/turf/next = get_step(M, step_dir)
		if(!next) continue
		for(var/mob/living/blocker in next)
			if(blocker == M || !(blocker in members)) continue
			if(chain_prio(blocker) < my_prio)
				var/datum/group_ai_order/BO = orders[blocker]
				if(!BO || BO.task == GROUP_AI_TASK_RETREAT) continue
				BO.task   = GROUP_AI_TASK_REPOSITION
				BO.anchor = group_ai_pick_step_away(blocker, M, 2)

/datum/group_ai_group/proc/chain_prio(mob/living/M)
	var/r = role_map[M] || GROUP_AI_ROLE_NONE
	if(r & GROUP_AI_ROLE_CONTROL) return GROUP_AI_CHAIN_CONTROL
	if(r & GROUP_AI_ROLE_TANK)    return GROUP_AI_CHAIN_TANK
	return GROUP_AI_CHAIN_MDD

// ── Announce orders (per ТЗ: emotes) ──
/datum/group_ai_group/proc/announce_orders()
	for(var/mob/living/M as anything in members)
		var/datum/group_ai_order/O = orders[M]
		if(!O) continue
		var/datum/group_ai_profile/P = profiles[M]
		if(P) P.announce_order(M, O.task)