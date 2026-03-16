// Group AI — utilities.

// ── Member status ──

/proc/group_ai_is_deadish(mob/living/L)
	if(!L || QDELETED(L)) return TRUE
	if(L.stat >= UNCONSCIOUS || L.health <= 0) return TRUE
	return FALSE

/proc/group_ai_health_pct(mob/living/L)
	if(!L || !L.maxHealth) return 0
	return max(0, round((L.health / L.maxHealth) * 100))

/proc/group_ai_defense_hint(mob/living/M)
	if(!M) return 0
	var/s = 0
	if(!isnull(M.vars["armor"]))       s += text2num("[M.vars["armor"]]")
	if(!isnull(M.vars["melee_armor"])) s += text2num("[M.vars["melee_armor"]]")
	return max(s, 0)

/proc/group_ai_speed_hint(mob/living/M)
	if(!M) return 1
	if(!isnull(M.vars["speed"]))
		return max(1, text2num("[M.vars["speed"]]"))
	if(!isnull(M.vars["move_to_delay"]))
		var/v = text2num("[M.vars["move_to_delay"]]")
		if(v > 0) return max(1, round(10 / v))
	return 1

/proc/group_ai_has_shield(mob/living/M)
	if(!M) return FALSE
	for(var/obj/item/I in M)
		if(I.loc != M) continue
		if(!isnull(I.vars["block_chance"]) && text2num("[I.vars["block_chance"]]") > 0)
			return TRUE
	return FALSE

// ── Threat assessment (per ТЗ) ──

/proc/group_ai_nature_threat(mob/living/T)
	if(!T) return 0
	var/s = 10
	if(T.client) s += 60
	else          s -= 10
	if(ishuman(T) || iscarbon(T)) s -= 10
	else                           s += 20
	if(T.stat >= UNCONSCIOUS)      s -= 40
	return s

/proc/group_ai_equipment_threat(mob/living/T)
	if(!T) return 0
	var/weapon_score = 0
	var/armor_score  = 0
	var/has_weapon   = FALSE
	var/l_hand = T.vars["l_hand"]
	var/r_hand = T.vars["r_hand"]
	for(var/obj/item/I in T)
		if(I.loc != T) continue
		var/in_hand = (!isnull(l_hand) && l_hand == I) || (!isnull(r_hand) && r_hand == I)
		if(in_hand)
			var/df = isnull(I.vars["dynamic_force"])    ? 0 : text2num("[I.vars["dynamic_force"]]")
			var/dw = isnull(I.vars["dynamic_wdefense"]) ? 0 : text2num("[I.vars["dynamic_wdefense"]]")
			var/f  = isnull(I.vars["force"])             ? 0 : text2num("[I.vars["force"]]")
			var/eff = max(df, f)
			if(eff > 0 || dw > 0)
				has_weapon = TRUE
				weapon_score += eff * 3 + dw * 2
		var/cov = isnull(I.vars["body_parts_covered"]) ? 0 : text2num("[I.vars["body_parts_covered"]]")
		if(cov > 0)
			var/prot = isnull(I.vars["armor"]) ? 0 : text2num("[I.vars["armor"]]")
			var/bits = group_ai_count_bits(round(cov))
			var/mult = group_ai_armor_mult(prot)
			armor_score += (prot + 5) * bits * mult / 8.0
	if(!has_weapon)
		var/unarmed = 0
		if(!isnull(T.vars["unarmed"]))          unarmed = text2num("[T.vars["unarmed"]]")
		if(unarmed <= 0 && !isnull(T.vars["melee_damage_lower"]))
			unarmed = text2num("[T.vars["melee_damage_lower"]]")
		weapon_score = max(weapon_score, unarmed * 2)
	return max(8, weapon_score + armor_score)

/proc/group_ai_count_bits(n)
	var/c = 0
	n = round(n)
	while(n > 0)
		if(n & 1) c++
		n = n >> 1
	return c

/proc/group_ai_armor_mult(prot)
	if(prot <= 0)  return 0.5
	if(prot <= 25) return 1.0
	if(prot <= 55) return 1.5
	return 2.5

// ── LoS check (no friendly fire) ──

/proc/group_ai_can_shoot_at(mob/living/shooter, atom/target, list/friendlies)
	if(!shooter || !target || shooter.z != target.z) return FALSE
	var/turf/S = get_turf(shooter)
	var/turf/T = get_turf(target)
	if(!S || !T) return FALSE
	var/list/line = get_line(S, T)
	if(!islist(line)) return TRUE
	for(var/turf/step as anything in line)
		if(step == S || step == T) continue
		if(step.density) return FALSE
		if(islist(friendlies))
			for(var/mob/living/M in step)
				if(M in friendlies) return FALSE
	return TRUE

// ── Direction/turf helpers ──

/proc/group_ai_cardinals()
	return list(NORTH, EAST, SOUTH, WEST)

/proc/group_ai_sanitize_dir(d)
	if(d in group_ai_cardinals()) return d
	return SOUTH

/proc/group_ai_dir_left(d)
	switch(group_ai_sanitize_dir(d))
		if(NORTH) return WEST
		if(WEST)  return SOUTH
		if(SOUTH) return EAST
		if(EAST)  return NORTH
	return WEST

/proc/group_ai_dir_right(d)
	switch(group_ai_sanitize_dir(d))
		if(NORTH) return EAST
		if(EAST)  return SOUTH
		if(SOUTH) return WEST
		if(WEST)  return NORTH
	return EAST

/proc/group_ai_is_open_turf(turf/T)
	return T && !T.density

/proc/group_ai_pick_step_away(atom/movable/src_atom, atom/danger, ideal = 3)
	if(!src_atom || !danger) return null
	var/turf/best = null
	var/best_score = -1e30
	for(var/dir in group_ai_cardinals())
		var/turf/C = get_step(src_atom, dir)
		if(!group_ai_is_open_turf(C)) continue
		var/d = get_dist(C, danger)
		var/score = d * 100 - abs(d - ideal) * 10
		if(score > best_score)
			best_score = score
			best = C
	return best

// ── Sort associative list descending by value ──

/proc/group_ai_sort_desc(list/assoc)
	var/list/out = list()
	if(!islist(assoc)) return out
	while(length(out) < length(assoc))
		var/best_key = null
		var/best_val = -1e30
		for(var/key in assoc)
			if(key in out) continue
			var/v = assoc[key]
			if(!isnull(v) && v > best_val)
				best_val = v
				best_key = key
		if(isnull(best_key)) break
		out += best_key
	return out

// ── Group management ──

/proc/group_ai_make_key(atom/anchor, doctrine_id)
	if(!anchor) return null
	var/area/A = get_area(anchor)
	return "[doctrine_id]-[anchor.z]-[A ? "[A.type]" : "/area"]"

/proc/group_ai_get_or_create(mob/living/M, key, doctrine_type)
	if(!M || !doctrine_type) return null
	var/datum/group_ai_doctrine/probe = new doctrine_type()
	if(!key)
		key = group_ai_make_key(M, probe.id)
	for(var/datum/group_ai_group/G as anything in group_ai_groups)
		if(QDELETED(G) || G.key != key || G.doctrine.type != doctrine_type) continue
		if(G.doctrine.can_join(G, M))
			G.add_member(M)
			qdel(probe)
			return G
	var/datum/group_ai_group/new_group = new(probe)
	new_group.key = key
	new_group.add_member(M)
	return new_group