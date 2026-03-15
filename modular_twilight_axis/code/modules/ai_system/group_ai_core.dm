/proc/group_ai_health_pct(mob/living/living_mob)
	if(!living_mob || !living_mob.maxHealth)
		return 0
	return (living_mob.health / living_mob.maxHealth) * 100

/proc/group_ai_is_deadish(mob/living/living_mob)
	if(!living_mob || QDELETED(living_mob))
		return TRUE
	if(living_mob.stat >= UNCONSCIOUS)
		return TRUE
	if(living_mob.health <= 0)
		return TRUE
	return FALSE

/proc/group_ai_is_reachable(atom/source, atom/target, max_dist = 14)
	if(!source || !target)
		return FALSE
	if(source.z != target.z)
		return FALSE
	return get_dist(source, target) <= max_dist

/proc/group_ai_dir_left(direction)
	switch(direction)
		if(NORTH)
			return WEST
		if(SOUTH)
			return EAST
		if(EAST)
			return NORTH
		if(WEST)
			return SOUTH
	return WEST

/proc/group_ai_dir_right(direction)
	switch(direction)
		if(NORTH)
			return EAST
		if(SOUTH)
			return WEST
		if(EAST)
			return SOUTH
		if(WEST)
			return NORTH
	return EAST

/proc/group_ai_dir_back(direction)
	switch(direction)
		if(NORTH)
			return SOUTH
		if(SOUTH)
			return NORTH
		if(EAST)
			return WEST
		if(WEST)
			return EAST
	return SOUTH

/proc/group_ai_sanitize_dir(direction)
	if(direction in group_ai_cardinals())
		return direction
	return SOUTH

/proc/group_ai_pick_step_away(atom/movable/source, atom/danger, prefer_distance = 2)
	if(!source || !danger)
		return null
	var/turf/best_turf = null
	var/best_score = -1.0e31
	for(var/direction in group_ai_cardinals())
		var/turf/candidate = get_step(source, direction)
		if(!candidate || candidate.density)
			continue
		var/score = get_dist(candidate, danger) * 100
		if(prefer_distance)
			score -= abs(get_dist(candidate, danger) - prefer_distance) * 10
		if(score > best_score)
			best_score = score
			best_turf = candidate
	return best_turf

/proc/group_ai_make_group_key(atom/anchor, doctrine_id)
	if(!anchor)
		return null
	var/area/current_area = get_area(anchor)
	var/area_key = current_area ? "[current_area.type]" : "/area"
	return "[doctrine_id]-[anchor.z]-[area_key]"

/proc/group_ai_get_or_create_group(mob/living/member, key, doctrine_type = /datum/group_ai_doctrine)
	if(!member)
		return null

	var/datum/group_ai_doctrine/probe_doctrine = new doctrine_type()
	if(!key)
		key = group_ai_make_group_key(member, probe_doctrine.id)

	for(var/datum/group_ai_group/existing as anything in group_ai_groups)
		if(QDELETED(existing))
			continue
		if(existing.key != key)
			continue
		if(existing.doctrine.type != doctrine_type)
			continue
		if(existing.doctrine.can_join(existing, member))
			existing.add_member(member)
			qdel(probe_doctrine)
			return existing

	var/datum/group_ai_group/new_group = new(probe_doctrine)
	new_group.key = key
	new_group.add_member(member)
	return new_group

/proc/group_ai_target_score_simple(datum/group_ai_group/group, mob/living/member, mob/living/target)
	if(!group || !member || !target)
		return 0
	if(group_ai_is_deadish(target))
		return 0
	var/score = 10
	if(target.client)
		score += 20
	if(target.stat < UNCONSCIOUS)
		score += 10
	if(target.health > 0)
		score += min(25, round(target.health / 10))
	score += max(0, 12 - get_dist(member, target)) * 2
	return score

/proc/group_ai_sort_targets_desc(list/assoc)
	var/list/ordered = list()
	if(!islist(assoc))
		return ordered
	while(length(ordered) < length(assoc))
		var/best_key = null
		var/best_score = -1.0e31
		for(var/key in assoc)
			if(key in ordered)
				continue
			var/value = assoc[key]
			if(isnull(value))
				continue
			if(value > best_score)
				best_score = value
				best_key = key
		if(isnull(best_key))
			break
		ordered += best_key
	return ordered

/proc/group_ai_slot_offset(slot_key, orientation)
	orientation = group_ai_sanitize_dir(orientation)
	switch(slot_key)
		if("2")
			return get_step(null, orientation)
		if("8")
			return get_step(null, group_ai_dir_back(orientation))
		if("4")
			return get_step(null, group_ai_dir_left(orientation))
		if("6")
			return get_step(null, group_ai_dir_right(orientation))
		if("1")
			var/d1 = group_ai_dir_left(orientation)
			return turn(d1, 0)
		if("3")
			var/d3 = group_ai_dir_right(orientation)
			return turn(d3, 0)
		if("7")
			var/d7 = group_ai_dir_left(group_ai_dir_back(orientation))
			return turn(d7, 0)
		if("9")
			var/d9 = group_ai_dir_right(group_ai_dir_back(orientation))
			return turn(d9, 0)
	return null

/proc/group_ai_matrix_turf(atom/target, slot_key, orientation)
	if(!target)
		return null
	var/turf/base = get_turf(target)
	if(!base)
		return null
	orientation = group_ai_sanitize_dir(orientation)
	var/turf/result = base
	switch(slot_key)
		if("2")
			result = get_step(base, orientation)
		if("8")
			result = get_step(base, group_ai_dir_back(orientation))
		if("4")
			result = get_step(base, group_ai_dir_left(orientation))
		if("6")
			result = get_step(base, group_ai_dir_right(orientation))
		if("1")
			result = get_step(get_step(base, orientation), group_ai_dir_left(orientation))
		if("3")
			result = get_step(get_step(base, orientation), group_ai_dir_right(orientation))
		if("7")
			result = get_step(get_step(base, group_ai_dir_back(orientation)), group_ai_dir_left(orientation))
		if("9")
			result = get_step(get_step(base, group_ai_dir_back(orientation)), group_ai_dir_right(orientation))
	if(result && !result.density)
		return result
	return null

/proc/group_ai_outer_turfs(atom/target, orientation)
	var/list/out = list()
	if(!target)
		return out
	var/turf/base = get_turf(target)
	if(!base)
		return out
	orientation = group_ai_sanitize_dir(orientation)
	for(var/side_dir in group_ai_cardinals())
		var/turf/two = get_step(get_step(base, side_dir), side_dir)
		if(two && !two.density)
			out += two
	for(var/a_dir in group_ai_cardinals())
		var/b_dir = group_ai_dir_right(a_dir)
		var/turf/diag = get_step(get_step(get_step(base, a_dir), a_dir), b_dir)
		if(diag && !diag.density)
			out += diag
	return out

/proc/group_ai_pick_anchor_near_target(mob/living/member, atom/target, desired_distance = 2)
	if(!member || !target)
		return null
	var/turf/base = get_turf(target)
	if(!base)
		return null
	var/turf/best_turf = null
	var/best_score = -1.0e31
	for(var/side_dir in group_ai_cardinals())
		var/turf/candidate = get_step(base, side_dir)
		if(!candidate || candidate.density)
			continue
		var/score = 0
		score -= abs(get_dist(candidate, target) - desired_distance) * 100
		score -= get_dist(member, candidate) * 5
		if(score > best_score)
			best_score = score
			best_turf = candidate
	for(var/slot_key in GROUP_AI_MATRIX_RESERVE)
		var/turf/candidate = group_ai_matrix_turf(target, slot_key, SOUTH)
		if(!candidate || candidate.density)
			continue
		var/score = 0
		score -= abs(get_dist(candidate, target) - desired_distance) * 100
		score -= get_dist(member, candidate) * 5
		if(score > best_score)
			best_score = score
			best_turf = candidate
	return best_turf

/proc/group_ai_clone_assignment(datum/group_ai_assignment/source)
	if(!source)
		return null
	var/datum/group_ai_assignment/copy = new
	copy.task = source.task
	copy.slot_key = source.slot_key
	copy.slot_turf = source.slot_turf
	copy.reserve_turf = source.reserve_turf
	copy.anchor_turf = source.anchor_turf
	copy.engagement_id = source.engagement_id
	copy.slot_layer = source.slot_layer
	return copy

/datum/group_ai_assignment
	var/task = GROUP_AI_TASK_NONE
	var/slot_key = null
	var/turf/slot_turf = null
	var/turf/reserve_turf = null
	var/turf/anchor_turf = null
	var/engagement_id = null
	var/slot_layer = null

/datum/group_ai_doctrine
	var/id = "generic"
	var/group_pulse_interval = 1 SECONDS
	var/slot_rebuild_interval = 1.5 SECONDS
	var/max_join_distance = 10
	var/max_group_spread = 12
	var/leader_bias = 25
	var/max_engaged_targets = 3
	var/min_target_score = 8
	var/max_target_scan = 12
	var/rotation_cooldown = 2.5 SECONDS
	var/matrix_reorient_threshold = 2
	var/preferred_ranged_distance = 3

/datum/group_ai_doctrine/proc/can_join(datum/group_ai_group/group, mob/living/member)
	if(!group || !member)
		return FALSE
	if(!length(group.members))
		return TRUE
	for(var/mob/living/other as anything in group.members)
		if(QDELETED(other))
			continue
		if(get_dist(other, member) <= max_join_distance)
			return TRUE
	return FALSE

/datum/group_ai_doctrine/proc/member_role(mob/living/member)
	return GROUP_AI_ROLE_MELEE

/datum/group_ai_doctrine/proc/leader_score(mob/living/member)
	if(group_ai_is_deadish(member))
		return -1
	return group_ai_health_pct(member)

/datum/group_ai_doctrine/proc/should_member_recover(mob/living/member, datum/group_ai_group/group)
	return group_ai_health_pct(member) <= 25

/datum/group_ai_doctrine/proc/score_target(datum/group_ai_group/group, mob/living/member, mob/living/target)
	return group_ai_target_score_simple(group, member, target)

/datum/group_ai_doctrine/proc/target_selection_count(datum/group_ai_group/group, living_members, candidate_count)
	if(living_members <= 0 || candidate_count <= 0)
		return 0
	return min(max_engaged_targets, candidate_count, max(1, living_members))

/datum/group_ai_doctrine/proc/allocate_target_budgets(datum/group_ai_group/group, list/selected_targets, list/current_threats, living_members)
	var/list/budgets = list()
	if(!living_members || !length(selected_targets))
		return budgets
	var/target_count = length(selected_targets)
	var/base_budget = max(1, round(living_members / target_count))
	var/remaining = living_members
	for(var/atom/target as anything in selected_targets)
		var/budget = min(base_budget, remaining)
		budgets[target] = budget
		remaining -= budget
	if(remaining > 0)
		var/list/ordered = group_ai_sort_targets_desc(current_threats)
		for(var/atom/target as anything in ordered)
			if(!(target in selected_targets))
				continue
			if(remaining <= 0)
				break
			budgets[target] = (budgets[target] || 0) + 1
			remaining--
	return budgets

/datum/group_ai_doctrine/proc/update_morale(datum/group_ai_group/group)
	if(!group.leader || group_ai_is_deadish(group.leader))
		group.morale_state = GROUP_AI_MORALE_SHAKEN
		return
	var/member_count = 0
	var/healthy_count = 0
	for(var/mob/living/member as anything in group.members)
		if(group_ai_is_deadish(member))
			continue
		member_count++
		if(group_ai_health_pct(member) > 50)
			healthy_count++
	if(member_count <= 1)
		group.morale_state = GROUP_AI_MORALE_SHAKEN
	else if(healthy_count <= max(1, round(member_count * 0.33)))
		group.morale_state = GROUP_AI_MORALE_SHAKEN
	else
		group.morale_state = GROUP_AI_MORALE_PRESSURE

/datum/group_ai_engagement
	var/id = null
	var/atom/target = null
	var/share = 0
	var/assigned_budget = 0
	var/orientation = SOUTH
	var/last_rotation_time = 0
	var/turf/last_center_turf = null
	var/had_recent_substitution = FALSE
	var/list/primary_turfs = list()
	var/list/reserve_turfs = list()
	var/list/outer_turfs = list()
	var/list/primary_members = list()
	var/list/reserve_members = list()
	var/list/outer_members = list()
	var/list/reserve_anchor = list()

/datum/group_ai_engagement/New(atom/new_target)
	..()
	target = new_target
	id = "eng_[world.time]_[rand(1000, 999999)]"

/datum/group_ai_engagement/proc/rebuild_matrix(datum/group_ai_doctrine/doctrine, force_rotate = FALSE)
	if(!target || QDELETED(target))
		return
	var/turf/current_center = get_turf(target)
	if(!current_center)
		return
	var/new_orientation = orientation
	if(!new_orientation)
		if(ismob(target))
			var/mob/m = target
			new_orientation = group_ai_sanitize_dir(m.dir)
		else
			new_orientation = SOUTH
	if(last_center_turf && get_dist(last_center_turf, current_center) > doctrine.matrix_reorient_threshold)
		if(force_rotate || (had_recent_substitution && world.time >= last_rotation_time + doctrine.rotation_cooldown))
			if(ismob(target))
				var/mob/mt = target
				new_orientation = group_ai_sanitize_dir(mt.dir)
			else
				new_orientation = orientation
			last_rotation_time = world.time
			had_recent_substitution = FALSE
	orientation = group_ai_sanitize_dir(new_orientation)
	last_center_turf = current_center
	primary_turfs.Cut()
	reserve_turfs.Cut()
	outer_turfs = group_ai_outer_turfs(target, orientation)
	for(var/slot_key in GROUP_AI_MATRIX_PRIMARY)
		primary_turfs[slot_key] = group_ai_matrix_turf(target, slot_key, orientation)
		if(!(slot_key in primary_members))
			primary_members[slot_key] = null
	for(var/slot_key in GROUP_AI_MATRIX_RESERVE)
		reserve_turfs[slot_key] = group_ai_matrix_turf(target, slot_key, orientation)
		if(!(slot_key in reserve_members))
			reserve_members[slot_key] = null
	reserve_anchor["1"] = "4"
	reserve_anchor["3"] = "2"
	reserve_anchor["7"] = "8"
	reserve_anchor["9"] = "6"

/datum/group_ai_group
	var/id = null
	var/key = null
	var/datum/group_ai_doctrine/doctrine = null
	var/list/members = list()
	var/mob/living/leader = null
	var/list/engagements = list()
	var/list/engaged_targets = list()
	var/list/assignments = list()
	var/list/threat_table = list()
	var/morale_state = GROUP_AI_MORALE_STEADY
	var/dirty_flags = GROUP_AI_DIRTY_ALL
	var/last_group_pulse = 0
	var/last_slot_rebuild = 0
	var/last_target_refresh = 0
	var/last_leader_refresh = 0
	var/last_morale_refresh = 0

/datum/group_ai_group/New(datum/group_ai_doctrine/new_doctrine)
	..()
	doctrine = new_doctrine || new /datum/group_ai_doctrine()
	id = "group_ai_[world.time]_[rand(1000, 999999)]"
	group_ai_groups += src

/datum/group_ai_group/Destroy(force, ...)
	for(var/mob/living/member as anything in members)
		if(member && group_ai_membership[member] == src)
			group_ai_membership -= member
	members.Cut()
	assignments.Cut()
	engagements.Cut()
	engaged_targets.Cut()
	threat_table.Cut()
	group_ai_groups -= src
	return ..()

/datum/group_ai_group/proc/add_member(mob/living/member)
	if(!member || QDELETED(member))
		return FALSE
	if(!(member in members))
		members += member
	group_ai_membership[member] = src
	dirty_flags |= GROUP_AI_DIRTY_ALL
	return TRUE

/datum/group_ai_group/proc/remove_member(mob/living/member)
	if(!member)
		return
	members -= member
	assignments -= member
	if(group_ai_membership[member] == src)
		group_ai_membership -= member
	if(leader == member)
		leader = null
	dirty_flags |= GROUP_AI_DIRTY_ALL
	if(!length(members))
		qdel(src)

/datum/group_ai_group/proc/mark_dirty(flag = GROUP_AI_DIRTY_ALL)
	dirty_flags |= flag

/datum/group_ai_group/proc/cleanup_members()
	var/list/to_remove = list()
	for(var/mob/living/member as anything in members)
		if(group_ai_is_deadish(member))
			to_remove += member
			continue
		if(leader && get_dist(member, leader) > doctrine.max_group_spread)
			to_remove += member
			continue
		if(member.ai_controller)
			member.ai_controller.set_blackboard_key(BB_GROUP_AI_HANDLE, src)
	for(var/mob/living/member as anything in to_remove)
		remove_member(member)

/datum/group_ai_group/proc/try_pulse(force = FALSE)
	if(QDELETED(src))
		return
	cleanup_members()
	if(QDELETED(src) || !length(members))
		return
	if(!force && world.time < last_group_pulse + doctrine.group_pulse_interval)
		return
	last_group_pulse = world.time
	if((dirty_flags & (GROUP_AI_DIRTY_MEMBERSHIP | GROUP_AI_DIRTY_LEADER)) || !leader || world.time >= last_leader_refresh + 5 SECONDS)
		refresh_leader()
	if((dirty_flags & (GROUP_AI_DIRTY_MEMBERSHIP | GROUP_AI_DIRTY_TARGET)) || world.time >= last_target_refresh + 2 SECONDS)
		refresh_targets()
	if((dirty_flags & (GROUP_AI_DIRTY_MORALE | GROUP_AI_DIRTY_MEMBERSHIP)) || world.time >= last_morale_refresh + 3 SECONDS)
		refresh_morale()
	if((dirty_flags & (GROUP_AI_DIRTY_SLOTS | GROUP_AI_DIRTY_TARGET | GROUP_AI_DIRTY_TASKS)) || world.time >= last_slot_rebuild + doctrine.slot_rebuild_interval)
		rebuild_engagements()
	assign_tasks()
	dirty_flags = GROUP_AI_DIRTY_NONE

/datum/group_ai_group/proc/refresh_leader()
	last_leader_refresh = world.time
	var/mob/living/best_leader = null
	var/best_score = -1.0e31
	for(var/mob/living/member as anything in members)
		if(group_ai_is_deadish(member))
			continue
		var/score = doctrine.leader_score(member)
		if(member == leader)
			score += doctrine.leader_bias
		if(score > best_score)
			best_score = score
			best_leader = member
	leader = best_leader


/datum/group_ai_group/proc/refresh_targets()
	last_target_refresh = world.time
	var/list/previous_targets = engaged_targets.Copy()
	threat_table.Cut()
	for(var/mob/living/member as anything in members)
		if(group_ai_is_deadish(member))
			continue
		var/list/local_targets = list()
		if(member.ai_controller)
			var/atom/current_target = member.ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
			if(isliving(current_target))
				local_targets += current_target
			var/atom/shared_target = member.ai_controller.blackboard[BB_GROUP_AI_SHARED_TARGET]
			if(isliving(shared_target) && !(shared_target in local_targets))
				local_targets += shared_target
		for(var/mob/living/possible in view(doctrine.max_target_scan, member))
			if(possible in local_targets)
				continue
			local_targets += possible
		for(var/mob/living/possible as anything in local_targets)
			if(group_ai_is_deadish(possible))
				continue
			if(possible in members)
				continue
			var/add_score = doctrine.score_target(src, member, possible)
			if(add_score <= 0)
				continue
			if(!group_ai_is_reachable(member, possible, doctrine.max_target_scan + 2))
				add_score *= 0.35
			threat_table[possible] = (threat_table[possible] || 0) + add_score
	for(var/mob/living/possible as anything in previous_targets)
		if(group_ai_is_deadish(possible))
			continue
		if(!(possible in threat_table))
			threat_table[possible] = doctrine.min_target_score
	var/list/ordered = group_ai_sort_targets_desc(threat_table)
	engaged_targets.Cut()
	var/living_members = 0
	for(var/mob/living/member as anything in members)
		if(!group_ai_is_deadish(member))
			living_members++
	var/max_targets = doctrine.target_selection_count(src, living_members, length(ordered))
	for(var/mob/living/possible as anything in ordered)
		if(length(engaged_targets) >= max_targets)
			break
		if((threat_table[possible] || 0) < doctrine.min_target_score)
			continue
		if(leader && !group_ai_is_reachable(leader, possible, doctrine.max_target_scan + 6))
			continue
		engaged_targets += possible
	var/list/keep_ids = list()
	for(var/mob/living/target as anything in engaged_targets)
		var/datum/group_ai_engagement/found = null
		for(var/datum/group_ai_engagement/eng as anything in engagements)
			if(eng.target == target)
				found = eng
				break
		if(!found)
			found = new(target)
			engagements += found
		keep_ids += found
	var/list/to_remove = list()
	for(var/datum/group_ai_engagement/eng as anything in engagements)
		if(!(eng in keep_ids))
			to_remove += eng
	for(var/datum/group_ai_engagement/eng as anything in to_remove)
		engagements -= eng
	allocate_target_budgets()

/datum/group_ai_group/proc/allocate_target_budgets()
	var/list/selected = engaged_targets.Copy()
	var/living_members = 0
	for(var/mob/living/member as anything in members)
		if(!group_ai_is_deadish(member))
			living_members++
	if(!living_members || !length(selected))
		return
	var/list/budgets = doctrine.allocate_target_budgets(src, selected, threat_table, living_members)
	for(var/datum/group_ai_engagement/eng as anything in engagements)
		eng.share = length(selected) ? (1 / length(selected)) : 1
		eng.assigned_budget = budgets[eng.target] || 0

/datum/group_ai_group/proc/refresh_morale()
	last_morale_refresh = world.time
	doctrine.update_morale(src)

/datum/group_ai_group/proc/rebuild_engagements()
	last_slot_rebuild = world.time
	for(var/datum/group_ai_engagement/eng as anything in engagements)
		var/force_rotate = FALSE
		if(!eng.last_center_turf)
			force_rotate = TRUE
		eng.rebuild_matrix(doctrine, force_rotate)

/datum/group_ai_group/proc/member_assignment(mob/living/member)
	var/datum/group_ai_assignment/assignment = assignments[member]
	if(!assignment)
		assignment = new
		assignments[member] = assignment
	return assignment

/datum/group_ai_group/proc/reset_assignments()
	for(var/mob/living/member as anything in members)
		var/datum/group_ai_assignment/assignment = member_assignment(member)
		assignment.task = GROUP_AI_TASK_NONE
		assignment.slot_key = null
		assignment.slot_turf = null
		assignment.reserve_turf = null
		assignment.anchor_turf = null
		assignment.engagement_id = null
		assignment.slot_layer = null

/datum/group_ai_group/proc/can_hold_primary(mob/living/member)
	var/role = doctrine.member_role(member)
	if(role == GROUP_AI_ROLE_RANGED)
		return FALSE
	return TRUE

/datum/group_ai_group/proc/can_hold_reserve(mob/living/member)
	return can_hold_primary(member)

/datum/group_ai_group/proc/primary_slot_priority(slot_key)
	switch(slot_key)
		if("2")
			return 100
		if("4")
			return 95
		if("6")
			return 95
		if("8")
			return 85
	return 80

/datum/group_ai_group/proc/member_slot_score(mob/living/member, datum/group_ai_engagement/eng, slot_key, turf/slot_turf)
	if(!member || !eng)
		return -1.0e31
	var/score = group_ai_health_pct(member)
	score += primary_slot_priority(slot_key)
	if(slot_turf)
		score += max(0, 12 - get_dist(member, slot_turf)) * 4
	var/datum/group_ai_assignment/assignment = assignments[member]
	if(assignment && assignment.engagement_id == eng.id && assignment.slot_key == slot_key)
		score += 50
	if(member == leader)
		score -= 20
	return score

/datum/group_ai_group/proc/member_reserve_score(mob/living/member, datum/group_ai_engagement/eng, slot_key, turf/slot_turf)
	if(!member || !eng)
		return -1.0e31
	var/score = group_ai_health_pct(member)
	if(slot_turf)
		score += max(0, 10 - get_dist(member, slot_turf)) * 3
	var/datum/group_ai_assignment/assignment = assignments[member]
	if(assignment && assignment.engagement_id == eng.id && assignment.slot_key == slot_key)
		score += 35
	return score


/datum/group_ai_group/proc/assign_tasks()
	var/list/previous_assignments = list()
	for(var/mob/living/member as anything in members)
		var/datum/group_ai_assignment/existing = assignments[member]
		if(existing)
			previous_assignments[member] = group_ai_clone_assignment(existing)

	reset_assignments()
	var/list/unassigned = list()
	for(var/mob/living/member as anything in members)
		if(group_ai_is_deadish(member))
			continue
		unassigned += member
		if(member.ai_controller)
			member.ai_controller.set_blackboard_key(BB_GROUP_AI_ROLE, doctrine.member_role(member))
	for(var/datum/group_ai_engagement/eng as anything in engagements)
		eng.primary_members.Cut()
		eng.reserve_members.Cut()
		eng.outer_members.Cut()

	for(var/datum/group_ai_engagement/eng as anything in engagements)
		var/list/pool = list()
		for(var/mob/living/member as anything in unassigned)
			if(doctrine.should_member_recover(member, src))
				continue
			if(!group_ai_is_reachable(member, eng.target, doctrine.max_target_scan + 6))
				continue
			pool += member
		assign_engagement_primary(eng, pool, unassigned, previous_assignments)
		assign_engagement_reserve(eng, pool, unassigned, previous_assignments)
		assign_engagement_outer(eng, pool, unassigned, previous_assignments)
		assign_engagement_ranged(eng, unassigned, previous_assignments)

	for(var/mob/living/member as anything in unassigned)
		var/datum/group_ai_assignment/assignment = member_assignment(member)
		if(doctrine.should_member_recover(member, src))
			assignment.task = GROUP_AI_TASK_RECOVERY
			var/atom/recovery_target = length(engaged_targets) ? engaged_targets[1] : leader
			assignment.anchor_turf = group_ai_pick_step_away(member, recovery_target, 3)
		else if(length(engagements))
			var/datum/group_ai_engagement/primary_eng = engagements[1]
			assignment.task = GROUP_AI_TASK_OUTER
			assignment.engagement_id = primary_eng.id
			assignment.slot_layer = GROUP_AI_TASK_OUTER
			var/turf/best_outer = null
			var/best_score = -1.0e31
			for(var/turf/outer_turf as anything in primary_eng.outer_turfs)
				var/score = -get_dist(member, outer_turf)
				var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
				if(old_assignment && old_assignment.anchor_turf == outer_turf)
					score += 10
				if(score > best_score)
					best_score = score
					best_outer = outer_turf
			assignment.anchor_turf = best_outer || group_ai_pick_step_away(member, primary_eng.target, 3)
		else
			assignment.task = GROUP_AI_TASK_COMMAND
			assignment.anchor_turf = leader ? get_turf(leader) : get_turf(member)
	for(var/mob/living/member as anything in members)
		publish_assignment(member, assignments[member])

/datum/group_ai_group/proc/assign_engagement_primary(datum/group_ai_engagement/eng, list/pool, list/unassigned, list/previous_assignments)
	if(!eng || !eng.target)
		return
	var/slots_filled = 0
	for(var/slot_key in GROUP_AI_MATRIX_PRIMARY)
		if(slots_filled >= eng.assigned_budget)
			break
		var/turf/slot_turf = eng.primary_turfs[slot_key]
		if(!slot_turf)
			continue
		var/mob/living/current_holder = null
		for(var/mob/living/member as anything in pool)
			if(!(member in unassigned))
				continue
			var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
			if(old_assignment && old_assignment.engagement_id == eng.id && old_assignment.task == GROUP_AI_TASK_PRIMARY && old_assignment.slot_key == slot_key && can_hold_primary(member))
				current_holder = member
				break
		if(current_holder)
			unassigned -= current_holder
			var/datum/group_ai_assignment/assignment = member_assignment(current_holder)
			assignment.task = GROUP_AI_TASK_PRIMARY
			assignment.engagement_id = eng.id
			assignment.slot_layer = GROUP_AI_TASK_PRIMARY
			assignment.slot_key = slot_key
			assignment.slot_turf = slot_turf
			eng.primary_members[slot_key] = current_holder
			slots_filled++
			continue
		var/mob/living/best_member = null
		var/best_score = -1.0e31
		for(var/mob/living/member as anything in pool)
			if(!(member in unassigned))
				continue
			if(!can_hold_primary(member))
				continue
			var/score = member_slot_score(member, eng, slot_key, slot_turf)
			var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
			if(old_assignment && old_assignment.engagement_id == eng.id && old_assignment.task == GROUP_AI_TASK_PRIMARY)
				score += 15
			if(score > best_score)
				best_score = score
				best_member = member
		if(!best_member)
			continue
		unassigned -= best_member
		var/datum/group_ai_assignment/assignment = member_assignment(best_member)
		assignment.task = GROUP_AI_TASK_PRIMARY
		assignment.engagement_id = eng.id
		assignment.slot_layer = GROUP_AI_TASK_PRIMARY
		assignment.slot_key = slot_key
		assignment.slot_turf = slot_turf
		eng.primary_members[slot_key] = best_member
		slots_filled++
/datum/group_ai_group/proc/assign_engagement_reserve(datum/group_ai_engagement/eng, list/pool, list/unassigned, list/previous_assignments)
	if(!eng || !eng.target)
		return
	for(var/slot_key in GROUP_AI_MATRIX_RESERVE)
		var/turf/slot_turf = eng.reserve_turfs[slot_key]
		if(!slot_turf)
			continue
		var/mob/living/current_holder = null
		for(var/mob/living/member as anything in pool)
			if(!(member in unassigned))
				continue
			var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
			if(old_assignment && old_assignment.engagement_id == eng.id && old_assignment.task == GROUP_AI_TASK_RESERVE && old_assignment.slot_key == slot_key && can_hold_reserve(member))
				current_holder = member
				break
		if(current_holder)
			unassigned -= current_holder
			var/datum/group_ai_assignment/assignment = member_assignment(current_holder)
			assignment.task = GROUP_AI_TASK_RESERVE
			assignment.engagement_id = eng.id
			assignment.slot_layer = GROUP_AI_TASK_RESERVE
			assignment.slot_key = slot_key
			assignment.reserve_turf = slot_turf
			eng.reserve_members[slot_key] = current_holder
			continue
		var/mob/living/best_member = null
		var/best_score = -1.0e31
		for(var/mob/living/member as anything in pool)
			if(!(member in unassigned))
				continue
			if(!can_hold_reserve(member))
				continue
			var/score = member_reserve_score(member, eng, slot_key, slot_turf)
			var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
			if(old_assignment && old_assignment.engagement_id == eng.id && old_assignment.task == GROUP_AI_TASK_RESERVE)
				score += 10
			if(score > best_score)
				best_score = score
				best_member = member
		if(!best_member)
			continue
		unassigned -= best_member
		var/datum/group_ai_assignment/assignment = member_assignment(best_member)
		assignment.task = GROUP_AI_TASK_RESERVE
		assignment.engagement_id = eng.id
		assignment.slot_layer = GROUP_AI_TASK_RESERVE
		assignment.slot_key = slot_key
		assignment.reserve_turf = slot_turf
		eng.reserve_members[slot_key] = best_member

/datum/group_ai_group/proc/assign_engagement_outer(datum/group_ai_engagement/eng, list/pool, list/unassigned, list/previous_assignments)
	if(!eng || !length(eng.outer_turfs))
		return
	for(var/mob/living/member as anything in pool)
		if(!(member in unassigned))
			continue
		if(doctrine.member_role(member) == GROUP_AI_ROLE_RANGED)
			continue
		var/turf/best_outer = null
		var/best_score = -1.0e31
		for(var/turf/outer_turf as anything in eng.outer_turfs)
			var/score = -get_dist(member, outer_turf)
			var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
			if(old_assignment && old_assignment.engagement_id == eng.id && old_assignment.anchor_turf == outer_turf)
				score += 10
			if(score > best_score)
				best_score = score
				best_outer = outer_turf
		if(!best_outer)
			break
		unassigned -= member
		var/datum/group_ai_assignment/assignment = member_assignment(member)
		assignment.task = GROUP_AI_TASK_OUTER
		assignment.engagement_id = eng.id
		assignment.slot_layer = GROUP_AI_TASK_OUTER
		assignment.anchor_turf = best_outer
		eng.outer_members += member

/datum/group_ai_group/proc/assign_engagement_ranged(datum/group_ai_engagement/eng, list/unassigned, list/previous_assignments)
	if(!eng || !eng.target)
		return
	for(var/mob/living/member as anything in unassigned.Copy())
		if(doctrine.member_role(member) != GROUP_AI_ROLE_RANGED && member != leader)
			continue
		unassigned -= member
		var/datum/group_ai_assignment/assignment = member_assignment(member)
		assignment.task = GROUP_AI_TASK_RANGED_HOLD
		assignment.engagement_id = eng.id
		assignment.slot_layer = GROUP_AI_TASK_RANGED_HOLD
		var/datum/group_ai_assignment/old_assignment = previous_assignments[member]
		if(old_assignment && old_assignment.engagement_id == eng.id && old_assignment.anchor_turf)
			assignment.anchor_turf = old_assignment.anchor_turf
		else
			assignment.anchor_turf = group_ai_pick_anchor_near_target(member, eng.target, doctrine.preferred_ranged_distance)

/datum/group_ai_group/proc/publish_assignment(mob/living/member, datum/group_ai_assignment/assignment)
	if(!member || !member.ai_controller || !assignment)
		return
	member.ai_controller.set_blackboard_key(BB_GROUP_AI_HANDLE, src)
	member.ai_controller.set_blackboard_key(BB_GROUP_AI_TASK, assignment.task)
	if(assignment.engagement_id)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_ENGAGEMENT_ID, assignment.engagement_id)
	else
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_ENGAGEMENT_ID)
	if(assignment.slot_key)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_SLOT_KEY, assignment.slot_key)
	else
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_SLOT_KEY)
	if(assignment.slot_turf)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_SLOT_TURF, assignment.slot_turf)
	else
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_SLOT_TURF)
	if(assignment.reserve_turf)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_RESERVE_TURF, assignment.reserve_turf)
	else
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_RESERVE_TURF)
	if(assignment.anchor_turf)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_ANCHOR_TURF, assignment.anchor_turf)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_OUTER_TURF, assignment.anchor_turf)
	else
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_ANCHOR_TURF)
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_OUTER_TURF)
	var/atom/engagement_target = null
	for(var/datum/group_ai_engagement/eng as anything in engagements)
		if(eng.id == assignment.engagement_id)
			engagement_target = eng.target
			break
	if(engagement_target)
		member.ai_controller.set_blackboard_key(BB_GROUP_AI_SHARED_TARGET, engagement_target)
		member.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, engagement_target)
	else
		member.ai_controller.clear_blackboard_key(BB_GROUP_AI_SHARED_TARGET)

/datum/group_ai_group/proc/mark_member_substitution(mob/living/member)
	if(!member)
		return
	var/datum/group_ai_assignment/assignment = assignments[member]
	if(!assignment || !assignment.engagement_id)
		return
	for(var/datum/group_ai_engagement/eng as anything in engagements)
		if(eng.id == assignment.engagement_id)
			eng.had_recent_substitution = TRUE
			break
