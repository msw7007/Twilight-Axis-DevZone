// Mirespider integration and doctrine.

/proc/is_mirespider_mob(mob/living/member)
	if(!member)
		return FALSE
	if(istype(member, /mob/living/simple_animal/hostile/retaliate/rogue/mirespider))
		return TRUE
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		return TRUE
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		return TRUE
	return FALSE

/proc/mirespider_group_key(mob/living/member)
	return group_ai_make_group_key(member, "mirespider_pack")

/datum/group_ai_doctrine/mirespider_pack
	id = "mirespider_pack"
	group_pulse_interval = 1 SECONDS
	slot_rebuild_interval = 2 SECONDS
	max_join_distance = 12
	max_group_spread = 14
	leader_bias = 45
	max_engaged_targets = 3
	min_target_score = 12
	max_target_scan = 14
	rotation_cooldown = 3 SECONDS
	matrix_reorient_threshold = 2
	preferred_ranged_distance = 2

/datum/group_ai_doctrine/mirespider_pack/target_selection_count(datum/group_ai_group/group, living_members, candidate_count)
	if(living_members <= 0 || candidate_count <= 0)
		return 0
	return min(3, candidate_count, max(1, living_members))

/datum/group_ai_doctrine/mirespider_pack/allocate_target_budgets(datum/group_ai_group/group, list/selected_targets, list/current_threats, living_members)
	var/list/budgets = list()
	if(!living_members || !length(selected_targets))
		return budgets
	var/target_count = length(selected_targets)
	var/base_budget = max(1, round(living_members / target_count))
	var/remaining = living_members
	var/list/ordered = group_ai_sort_targets_desc(current_threats)
	for(var/atom/target as anything in selected_targets)
		budgets[target] = min(base_budget, remaining)
		remaining -= budgets[target]
	if(remaining > 0)
		for(var/atom/target as anything in ordered)
			if(!(target in selected_targets))
				continue
			if(remaining <= 0)
				break
			budgets[target] = (budgets[target] || 0) + 1
			remaining--
	return budgets

/datum/group_ai_doctrine/mirespider_pack/member_role(mob/living/member)
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		return GROUP_AI_ROLE_RANGED
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		return GROUP_AI_ROLE_SKIRMISHER
	return GROUP_AI_ROLE_MELEE

/datum/group_ai_doctrine/mirespider_pack/leader_score(mob/living/member)
	if(group_ai_is_deadish(member))
		return -1
	var/score = group_ai_health_pct(member)
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		score += 300
	else if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		score += 35
	return score

/datum/group_ai_doctrine/mirespider_pack/should_member_recover(mob/living/member, datum/group_ai_group/group)
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		return FALSE
	return group_ai_health_pct(member) <= 20

/datum/group_ai_doctrine/mirespider_pack/score_target(datum/group_ai_group/group, mob/living/member, mob/living/target)
	if(!target || (target in group.members))
		return 0
	if(islist(target.faction) && ("spiders" in target.faction))
		return 0
	var/score = ..()
	if(target.client)
		score += 25
	if(target.stat >= UNCONSCIOUS)
		score *= 0.2
	if(!group_ai_is_reachable(member, target, max_target_scan + 2))
		score *= 0.35
	return score

/datum/group_ai_doctrine/mirespider_pack/update_morale(datum/group_ai_group/group)
	if(!group.leader || group_ai_is_deadish(group.leader))
		group.morale_state = GROUP_AI_MORALE_SHAKEN
		return
	var/living_count = 0
	var/healthy_count = 0
	for(var/mob/living/member as anything in group.members)
		if(group_ai_is_deadish(member))
			continue
		living_count++
		if(group_ai_health_pct(member) > 40)
			healthy_count++
	if(living_count >= 4 && healthy_count >= 3)
		group.morale_state = GROUP_AI_MORALE_PRESSURE
	else if(healthy_count <= 1)
		group.morale_state = GROUP_AI_MORALE_SHAKEN
	else
		group.morale_state = GROUP_AI_MORALE_STEADY


/proc/group_ai_recruit_mirespider_cluster(mob/living/source, datum/group_ai_group/group, radius = 5)
	if(!source || !group)
		return
	for(var/mob/living/nearby in view(radius, source))
		if(!is_mirespider_mob(nearby))
			continue
		group.add_member(nearby)
		if(nearby.ai_controller)
			nearby.ai_controller.set_blackboard_key(BB_GROUP_AI_HANDLE, group)

/proc/group_ai_propagate_spider_contact(datum/group_ai_group/group, mob/living/witness, atom/target)
	if(!group || !witness || QDELETED(target))
		return
	group_ai_recruit_mirespider_cluster(witness, group, 5)
	for(var/mob/living/member as anything in group.members)
		if(group_ai_is_deadish(member))
			continue
		if(get_dist(member, witness) > 12)
			continue
		if(member.ai_controller)
			member.ai_controller.set_blackboard_key(BB_GROUP_AI_SHARED_TARGET, target)
	group.mark_dirty(GROUP_AI_DIRTY_TARGET | GROUP_AI_DIRTY_TASKS | GROUP_AI_DIRTY_SLOTS)

/datum/ai_planning_subtree/mirespider_group_sync
/datum/ai_planning_subtree/mirespider_group_sync/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(!controller || !controller.pawn)
		return
	var/mob/living/pawn = controller.pawn
	if(!is_mirespider_mob(pawn))
		return

	var/datum/group_ai_group/group = controller.blackboard[BB_GROUP_AI_HANDLE]
	if(!group || QDELETED(group))
		group = group_ai_get_or_create_group(pawn, mirespider_group_key(pawn), /datum/group_ai_doctrine/mirespider_pack)
		if(group)
			controller.set_blackboard_key(BB_GROUP_AI_HANDLE, group)

	var/atom/current_target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/atom/shared_target = controller.blackboard[BB_GROUP_AI_SHARED_TARGET]
	if(QDELETED(current_target) && !QDELETED(shared_target))
		current_target = shared_target
	var/atom/last_seen_target = controller.blackboard[BB_GROUP_AI_LAST_SEEN_TARGET]
	if(current_target != last_seen_target)
		if(current_target && !QDELETED(current_target) && group)
			group_ai_propagate_spider_contact(group, pawn, current_target)
		if(current_target)
			controller.set_blackboard_key(BB_GROUP_AI_LAST_SEEN_TARGET, current_target)
		else
			controller.clear_blackboard_key(BB_GROUP_AI_LAST_SEEN_TARGET)

	if(group)
		group.try_pulse()

/datum/ai_planning_subtree/mirespider_group_position
	var/datum/ai_behavior/travel_towards/stop_on_arrival/travel_behavior = /datum/ai_behavior/travel_towards/stop_on_arrival

/datum/ai_planning_subtree/mirespider_group_position/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(!controller || !controller.pawn)
		return
	var/task = controller.blackboard[BB_GROUP_AI_TASK]
	var/atom/target = controller.blackboard[BB_GROUP_AI_SHARED_TARGET]
	if(QDELETED(target))
		return
	var/mob/living/pawn = controller.pawn
	if(task == GROUP_AI_TASK_PRIMARY)
		var/turf/slot_turf = controller.blackboard[BB_GROUP_AI_SLOT_TURF]
		if(slot_turf && get_turf(pawn) != slot_turf && get_dist(pawn, target) > 1)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, slot_turf)
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
	if(task == GROUP_AI_TASK_RESERVE)
		var/turf/reserve_turf = controller.blackboard[BB_GROUP_AI_RESERVE_TURF]
		if(reserve_turf && get_dist(pawn, reserve_turf) > 0)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, reserve_turf)
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(get_dist(pawn, target) > 3)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, reserve_turf || get_turf(target))
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
	if(task == GROUP_AI_TASK_OUTER)
		var/turf/outer_turf = controller.blackboard[BB_GROUP_AI_OUTER_TURF]
		if(outer_turf && get_dist(pawn, outer_turf) > 0)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, outer_turf)
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(get_dist(pawn, target) > 5)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, outer_turf || get_turf(target))
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
	if(task == GROUP_AI_TASK_RECOVERY)
		var/turf/recovery_turf = controller.blackboard[BB_GROUP_AI_ANCHOR_TURF]
		if(recovery_turf && get_dist(pawn, recovery_turf) > 0)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, recovery_turf)
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/mirespider_lurker_group_position
	var/datum/ai_behavior/travel_towards/stop_on_arrival/travel_behavior = /datum/ai_behavior/travel_towards/stop_on_arrival

/datum/ai_planning_subtree/mirespider_lurker_group_position/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(!controller || !controller.pawn)
		return
	var/mob/living/pawn = controller.pawn
	var/atom/target = controller.blackboard[BB_GROUP_AI_SHARED_TARGET]
	if(QDELETED(target))
		return
	var/dist = get_dist(pawn, target)
	if(dist <= 1)
		var/turf/retreat_turf = group_ai_pick_step_away(pawn, target, 2)
		if(retreat_turf)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, retreat_turf)
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
	var/turf/anchor_turf = controller.blackboard[BB_GROUP_AI_ANCHOR_TURF]
	if(anchor_turf && get_dist(pawn, anchor_turf) > 0)
		controller.set_blackboard_key(BB_TRAVEL_DESTINATION, anchor_turf)
		controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(dist > 3)
		var/turf/approach_turf = group_ai_pick_anchor_near_target(pawn, target, 2)
		if(approach_turf)
			controller.set_blackboard_key(BB_TRAVEL_DESTINATION, approach_turf)
			controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_controller/mirespider
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/mirespider_group_sync,
		/datum/ai_planning_subtree/mirespider_group_position,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/simple_self_recovery,
		/datum/ai_planning_subtree/find_food,
		/datum/ai_planning_subtree/eat_food,
		/datum/ai_planning_subtree/being_a_minion/mirespider,
	)

/datum/ai_controller/mirespider_lurker
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/mirespider_group_sync,
		/datum/ai_planning_subtree/mirespider_lurker_group_position,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/basic_ranged_attack_subtree/mirespider_lurker,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)

/datum/ai_controller/mirespider_paralytic
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/mirespider_group_sync,
		/datum/ai_planning_subtree/mirespider_group_position,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)

/proc/group_ai_attach_mirespider(mob/living/member)
	if(!is_mirespider_mob(member))
		return
	var/datum/group_ai_group/group = group_ai_get_or_create_group(member, mirespider_group_key(member), /datum/group_ai_doctrine/mirespider_pack)
	if(group)
		if(member.ai_controller)
			member.ai_controller.set_blackboard_key(BB_GROUP_AI_HANDLE, group)
		group.mark_dirty(GROUP_AI_DIRTY_ALL)
		group.try_pulse(TRUE)

/proc/group_ai_detach_member(mob/living/member)
	if(!member)
		return
	var/datum/group_ai_group/group = group_ai_membership[member]
	if(group && !QDELETED(group))
		group.remove_member(member)

/proc/group_ai_signal_damage(mob/living/member)
	if(!member)
		return
	var/datum/group_ai_group/group = group_ai_membership[member]
	if(group && !QDELETED(group))
		group.mark_member_substitution(member)
		group.mark_dirty(GROUP_AI_DIRTY_MORALE | GROUP_AI_DIRTY_TASKS | GROUP_AI_DIRTY_SLOTS)

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/Initialize()
	. = ..()
	group_ai_attach_mirespider(src)

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/death(gibbed)
	group_ai_detach_member(src)
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	. = ..()
	if(damage >= 8)
		group_ai_signal_damage(src)

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/Initialize()
	. = ..()
	AddElement(/datum/element/ai_retaliate)
	group_ai_attach_mirespider(src)

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/death(gibbed)
	group_ai_detach_member(src)
	return ..()

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	. = ..()
	if(damage >= 8)
		group_ai_signal_damage(src)

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/Initialize()
	. = ..()
	AddElement(/datum/element/ai_retaliate)
	group_ai_attach_mirespider(src)

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/death(gibbed)
	group_ai_detach_member(src)
	return ..()

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	. = ..()
	if(damage >= 8)
		group_ai_signal_damage(src)
