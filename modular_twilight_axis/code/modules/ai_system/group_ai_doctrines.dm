/datum/group_ai_doctrine/mirespider
	id = "mirespider"
	group_pulse_interval = 0.7 SECONDS
	slot_rebuild_interval = 1.0 SECONDS
	max_join_distance = 10
	max_group_spread = 12
	leader_bias = 35

/datum/group_ai_doctrine/mirespider/member_role(mob/living/member)
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		return GROUP_AI_ROLE_RANGED
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		return GROUP_AI_ROLE_SKIRMISHER
	return GROUP_AI_ROLE_MELEE

/datum/group_ai_doctrine/mirespider/leader_score(mob/living/member)
	if(group_ai_is_deadish(member))
		return -1
	var/score = group_ai_health_pct(member)
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		score += 300
	else if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		score += 40
	return score

/datum/group_ai_doctrine/mirespider/should_member_recover(mob/living/member, datum/group_ai_group/group)
	if(istype(member, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		return FALSE
	return group_ai_health_pct(member) <= 20

/datum/group_ai_doctrine/mirespider/proc/select_target(datum/group_ai_group/group)
	var/atom/best_target = null
	if(best_target)
		return best_target
	for(var/mob/living/member as anything in group.members)
		if(group_ai_is_deadish(member))
			continue
		for(var/mob/living/possible in view(7, member))
			if(group_ai_is_deadish(possible))
				continue
			if(possible in group.members)
				continue
			if(islist(possible.faction) && ("spiders" in possible.faction))
				continue
			return possible
	return null

/datum/group_ai_doctrine/mirespider/update_morale(datum/group_ai_group/group)
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
