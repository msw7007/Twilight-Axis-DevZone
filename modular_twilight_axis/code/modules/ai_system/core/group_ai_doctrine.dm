// Group AI — doctrine: group-type configuration.

/datum/group_ai_doctrine
	var/id                   = "generic"
	var/pulse_interval       = 0.5 SECONDS
	var/reacquire_interval   = 1 SECONDS
	var/max_join_distance    = 10
	var/max_target_scan      = 12
	var/min_per_target       = GROUP_AI_MIN_PER_TARGET
	var/support_range        = 4
	var/lost_target_grace    = 3 SECONDS

/datum/group_ai_doctrine/proc/can_join(datum/group_ai_group/G, mob/living/M)
	if(!G || !M) return FALSE
	if(!length(G.members)) return TRUE
	for(var/mob/living/other as anything in G.members)
		if(!QDELETED(other) && get_dist(other, M) <= max_join_distance)
			return TRUE
	return FALSE

/datum/group_ai_doctrine/proc/profile_for(mob/living/M)
	return new /datum/group_ai_profile()

/datum/group_ai_doctrine/proc/is_valid_enemy(datum/group_ai_group/G, mob/living/M, mob/living/T)
	if(!T || QDELETED(T) || group_ai_is_deadish(T)) return FALSE
	if(T in G.members) return FALSE
	if(G.shared_faction && islist(T.faction) && (G.shared_faction in T.faction)) return FALSE
	return TRUE

/datum/group_ai_doctrine/proc/target_score(datum/group_ai_group/G, mob/living/M, mob/living/T)
	if(!is_valid_enemy(G, M, T)) return 0
	var/s = group_ai_nature_threat(T) + group_ai_equipment_threat(T)
	s += max(0, 20 - get_dist(M, T)) * 2
	if(M.z != T.z || get_dist(M, T) > max_target_scan + 2)
		s *= 0.5
	return max(s, 0)

/datum/group_ai_doctrine/proc/max_targets(datum/group_ai_group/G)
	var/living = G.living_count()
	if(living <= 0) return 0
	return max(1, round(living / max(1, min_per_target)))

// ── Mirespider pack ──

/datum/group_ai_doctrine/mirespider_pack
	id                 = "mirespider_pack"
	pulse_interval     = 0.4 SECONDS
	reacquire_interval = 0.8 SECONDS
	max_join_distance  = 12
	max_target_scan    = 16
	min_per_target     = 3
	support_range      = 4

/datum/group_ai_doctrine/mirespider_pack/profile_for(mob/living/M)
	if(istype(M, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		return new /datum/group_ai_profile/mirespider_lurker()
	if(istype(M, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		return new /datum/group_ai_profile/mirespider_paralytic()
	return new /datum/group_ai_profile/mirespider_small()