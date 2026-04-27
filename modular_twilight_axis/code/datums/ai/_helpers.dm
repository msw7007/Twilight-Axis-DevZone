/proc/human_npc_target_is_undead_bind_blocked(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/H = target
	if(!H.mind)
		return FALSE
	if(H.mind.has_antag_datum(/datum/antagonist/zombie))
		return TRUE
	if(H.mind.has_antag_datum(/datum/antagonist/skeleton))
		return TRUE
	if(H.mind.has_antag_datum(/datum/antagonist/lich))
		return TRUE
	return FALSE

/proc/human_npc_target_already_bound(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/H = target
	if(H.handcuffed || H.legcuffed)
		return TRUE
	return FALSE

/proc/human_npc_target_yielded(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/H = target
	return H.surrendering

/proc/human_npc_is_valid_bind_target(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE
	if(human_npc_target_already_bound(target))
		return FALSE
	if(human_npc_target_yielded(target))
		return TRUE
	if(target.stat == DEAD)
		if(human_npc_target_is_undead_bind_blocked(target))
			return FALSE
		return TRUE
	if(target.stat >= UNCONSCIOUS)
		return TRUE
	return FALSE

/proc/human_npc_should_not_attack_target(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE
	return human_npc_should_preserve_capture_target(target)

/proc/human_npc_should_strip_item(obj/item/I, mob/living/carbon/human/target)
	if(!I || QDELETED(I))
		return FALSE
	if(!target)
		return FALSE

	if(istype(I, /obj/item/bodypart))
		return FALSE
	if(istype(I, /obj/item/organ))
		return FALSE

	if(target.handcuffed && I == target.handcuffed)
		return FALSE
	if(target.legcuffed && I == target.legcuffed)
		return FALSE

	return TRUE

/proc/human_npc_collect_strip_items(mob/living/carbon/human/target)
	var/list/storage_items = list()
	var/list/other_items = list()
	var/list/result = list()
	if(!target)
		return result

	for(var/obj/item/I in target)
		if(QDELETED(I))
			continue
		if(target.handcuffed && I == target.handcuffed)
			continue
		if(target.legcuffed && I == target.legcuffed)
			continue
		
		if(length(I.contents))
			storage_items += I
		else
			other_items += I

	result += storage_items
	result += other_items
	return result

/proc/human_npc_dump_storage_contents(obj/item/container_item, turf/drop_turf, list/dropped_items)
	if(!container_item || QDELETED(container_item) || !drop_turf)
		return

	var/list/to_dump = list()
	for(var/atom/movable/AM in container_item.contents)
		to_dump += AM

	for(var/atom/movable/AM as anything in to_dump)
		if(QDELETED(AM))
			continue
		AM.forceMove(drop_turf)
		if(isitem(AM))
			dropped_items += AM

/proc/human_npc_strip_bound_target_equipment(mob/living/carbon/human/target, turf/drop_turf)
	var/list/dropped_items = list()
	if(!target || !drop_turf)
		return dropped_items

	var/list/strip_items = human_npc_collect_strip_items(target)
	for(var/obj/item/I as anything in strip_items)
		if(QDELETED(I))
			continue
		if(I.loc != target)
			continue

		if(length(I.contents))
			human_npc_dump_storage_contents(I, drop_turf, dropped_items)

		target.dropItemToGround(I)
		if(I.loc == drop_turf)
			dropped_items += I

	return dropped_items

/proc/human_npc_prisoner_is_unsalvageable(mob/living/target)
	if(!target || QDELETED(target))
		return TRUE
	if(target.stat == DEAD)
		return TRUE

	// Для human-пленников: если головы нет, лечить бессмысленно.
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/bodypart/head/head = H.get_bodypart(BODY_ZONE_HEAD)
		if(!head)
			return TRUE

	return FALSE

/proc/human_npc_should_remove_wound(datum/wound/W)
	if(!W || QDELETED(W))
		return FALSE

	// Самые опасные вещи снимаем всегда.
	if(istype(W, /datum/wound/artery))
		return TRUE
	if(istype(W, /datum/wound/fracture))
		return TRUE

	// И вообще любой wound, который продолжает кровить.
	if(!isnull(W.bleed_rate) && W.bleed_rate > 0)
		return TRUE

	return FALSE

/proc/human_npc_remove_dangerous_wounds(mob/living/target)
	if(!target || QDELETED(target))
		return FALSE

	var/changed = FALSE

	if(length(target.simple_wounds))
		var/list/simple_to_remove = list()
		for(var/datum/wound/W as anything in target.simple_wounds)
			if(human_npc_should_remove_wound(W))
				simple_to_remove += W

		for(var/datum/wound/W as anything in simple_to_remove)
			if(QDELETED(W))
				continue
			W.set_bleed_rate(0)
			W.remove_from_mob()
			changed = TRUE

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		for(var/obj/item/bodypart/BP as anything in C.bodyparts)
			if(!BP?.wounds || !length(BP.wounds))
				continue

			var/list/bodypart_to_remove = list()
			for(var/datum/wound/W as anything in BP.wounds)
				if(human_npc_should_remove_wound(W))
					bodypart_to_remove += W

			for(var/datum/wound/W as anything in bodypart_to_remove)
				if(QDELETED(W))
					continue
				W.set_bleed_rate(0)
				W.remove_from_bodypart()
				changed = TRUE

	return changed

/proc/human_npc_stabilize_blood_and_oxy(mob/living/target)
	if(!target || QDELETED(target))
		return FALSE

	var/changed = FALSE

	if(target.blood_volume < BLOOD_VOLUME_OKAY)
		target.blood_volume = BLOOD_VOLUME_OKAY
		changed = TRUE

	target.bleed_rate = target.get_bleed_rate()
	if(target.getOxyLoss())
		target.adjustOxyLoss(-target.getOxyLoss())
		changed = TRUE

	return changed

/proc/human_npc_stabilize_bound_target(mob/living/target)
	if(human_npc_prisoner_is_unsalvageable(target))
		return FALSE

	if(!human_npc_target_already_bound(target))
		return FALSE

	human_npc_remove_dangerous_wounds(target)
	human_npc_stabilize_blood_and_oxy(target)

	return TRUE

/proc/human_npc_same_faction(mob/living/a, mob/living/b)
	if(!a || !b)
		return FALSE

	if(islist(a.faction) && islist(b.faction))
		for(var/entry as anything in a.faction)
			if(entry in b.faction)
				return TRUE
		return FALSE

	return a.faction == b.faction

/proc/human_npc_is_active_hostile(mob/living/pawn, mob/living/other)
	if(!pawn || !other || pawn == other)
		return FALSE
	if(other.stat >= UNCONSCIOUS)
		return FALSE
	if(human_npc_target_yielded(other))
		return FALSE
	if(human_npc_target_already_bound(other))
		return FALSE
	if(human_npc_same_faction(pawn, other))
		return FALSE
	return TRUE

/proc/human_npc_has_nearby_active_hostiles(mob/living/pawn, mob/living/ignored_target = null, range = 7)
	if(!pawn)
		return FALSE

	for(var/mob/living/other in view(range, pawn))
		if(other == ignored_target)
			continue
		if(human_npc_is_active_hostile(pawn, other))
			return TRUE

	return FALSE

/proc/human_npc_should_ignore_captive_loot(obj/item/I)
	if(!I || QDELETED(I))
		return TRUE

	var/item_name = lowertext(I.name)
	if(findtext(item_name, "collar"))
		return TRUE
	if(findtext(item_name, "flower of eora"))
		return TRUE

	return FALSE

/proc/human_npc_cleanup_capture_loot(list/captive_loot, turf/reference_turf, max_dist = 1)
	var/list/cleaned = list()
	if(!islist(captive_loot))
		return cleaned

	for(var/obj/item/I as anything in captive_loot)
		if(QDELETED(I))
			continue
		if(!isturf(I.loc))
			continue
		if(reference_turf && get_dist(reference_turf, I) > max_dist)
			continue
		cleaned += I

	return cleaned

/proc/human_npc_get_weapon_skill_score(mob/living/carbon/human/pawn, obj/item/rogueweapon/W)
	if(!pawn || !W)
		return 0

	var/datum/skill/skill_type = W.associated_skill
	if(!skill_type)
		return 0

	var/skill_level = pawn.get_skill_level(skill_type)
	if(skill_level > 0)
		return 1

	return 0

/proc/human_npc_get_item_armor_total(obj/item/I)
	if(!I)
		return 0

	var/datum/armor/A = I.armor
	if(!istype(A))
		return 0

	return A.blunt + A.slash + A.stab + A.piercing

/proc/human_npc_get_armor_class_rank(mob/living/carbon/human/pawn)
	if(!pawn)
		return 0
	if(HAS_TRAIT(pawn, TRAIT_HEAVYARMOR))
		return 3
	if(HAS_TRAIT(pawn, TRAIT_MEDIUMARMOR))
		return 2
	return 1

/proc/human_npc_get_item_armor_class_rank(obj/item/I)
	if(!I)
		return 0

	var/type_text = lowertext("[I.type]")

	if(findtext(type_text, "/heavy") || findtext(type_text, "plate"))
		return 3
	if(findtext(type_text, "/medium") || findtext(type_text, "chain") || findtext(type_text, "brigandine"))
		return 2
	return 1

/proc/human_npc_should_preserve_capture_target(mob/living/target)
	if(!target)
		return FALSE
	if(!ishuman(target))
		return FALSE
	if(human_npc_target_already_bound(target))
		return TRUE
	if(target.stat >= UNCONSCIOUS)
		return TRUE
	if(human_npc_target_yielded(target))
		return TRUE
	return FALSE

/proc/human_npc_is_capture_consumable(obj/item/I)
	if(!I || QDELETED(I))
		return FALSE

	if(istype(I, /obj/item/reagent_containers/glass/bottle))
		return TRUE
	if(istype(I, /obj/item/natural/cloth/bandage))
		return TRUE
	if(istype(I, /obj/item/needle))
		return TRUE
	if(istype(I, /obj/item/natural/fibers))
		return TRUE

	return FALSE

/proc/human_npc_get_consumable_score(obj/item/I)
	if(!human_npc_is_capture_consumable(I))
		return 0

	if(istype(I, /obj/item/reagent_containers/glass/bottle))
		return 3
	if(istype(I, /obj/item/natural/cloth/bandage))
		return 2
	if(istype(I, /obj/item/needle))
		return 2
	if(istype(I, /obj/item/natural/fibers))
		return 2

	return 1

/proc/human_npc_get_weapon_in_hand(mob/living/carbon/human/pawn, want_shield = FALSE)
	if(!pawn)
		return null

	var/obj/item/r_held = pawn.get_item_for_held_index(1)
	var/obj/item/l_held = pawn.get_item_for_held_index(2)

	if(want_shield)
		if(istype(r_held, /obj/item/rogueweapon/shield))
			return r_held
		if(istype(l_held, /obj/item/rogueweapon/shield))
			return l_held
		return null

	if(istype(r_held, /obj/item/rogueweapon) && !istype(r_held, /obj/item/rogueweapon/shield))
		return r_held
	if(istype(l_held, /obj/item/rogueweapon) && !istype(l_held, /obj/item/rogueweapon/shield))
		return l_held

	return null

/proc/human_npc_get_equipped_competitor(mob/living/carbon/human/pawn, obj/item/candidate)
	if(!pawn || !candidate)
		return null

	if(istype(candidate, /obj/item/rogueweapon/shield))
		return human_npc_get_weapon_in_hand(pawn, TRUE)

	if(istype(candidate, /obj/item/rogueweapon))
		return human_npc_get_weapon_in_hand(pawn, FALSE)

	for(var/obj/item/I in pawn)
		if(I == candidate)
			continue

		if(istype(candidate, /obj/item/clothing/shoes) && istype(I, /obj/item/clothing/shoes))
			return I
		if(istype(candidate, /obj/item/clothing/head) && istype(I, /obj/item/clothing/head))
			return I
		if(istype(candidate, /obj/item/clothing/wrists) && istype(I, /obj/item/clothing/wrists))
			return I
		if(istype(candidate, /obj/item/clothing/gloves) && istype(I, /obj/item/clothing/gloves))
			return I
		if(istype(candidate, /obj/item/clothing/neck) && istype(I, /obj/item/clothing/neck))
			return I
		if(istype(candidate, /obj/item/clothing/mask) && istype(I, /obj/item/clothing/mask))
			return I
		if(istype(candidate, /obj/item/clothing/under) && istype(I, /obj/item/clothing/under))
			return I
		if(istype(candidate, /obj/item/clothing/suit) && istype(I, /obj/item/clothing/suit))
			return I

		if(candidate.slot_flags && I.slot_flags && (I.slot_flags & candidate.slot_flags))
			return I

	return null

/proc/human_npc_prepare_captive_loot_swap(mob/living/carbon/human/pawn, obj/item/candidate)
	if(!pawn || !candidate)
		return FALSE

	var/obj/item/current_item = human_npc_get_equipped_competitor(pawn, candidate)
	if(!current_item)
		return TRUE

	if(current_item == candidate)
		return FALSE

	pawn.dropItemToGround(current_item)
	return TRUE

/proc/human_npc_find_storage_for_consumable(mob/living/carbon/human/pawn)
	if(!pawn)
		return null

	var/list/storage_candidates = list()

	for(var/obj/item/I in pawn)
		if(QDELETED(I))
			continue

		var/datum/component/storage/STR = I.GetComponent(/datum/component/storage)
		if(!STR)
			continue

		storage_candidates += I

	if(!length(storage_candidates))
		return null

	// Сначала предпочитаем поясные хранилища.
	for(var/obj/item/I as anything in storage_candidates)
		if(istype(I, /obj/item/storage/belt))
			return I

	// Фолбэк — любое доступное хранилище.
	return storage_candidates[1]

/proc/human_npc_try_store_consumable(mob/living/carbon/human/pawn, obj/item/I)
	if(!pawn || !I || QDELETED(I))
		return FALSE
	if(get_dist(pawn, I) > 1)
		return FALSE

	var/obj/item/storage_item = human_npc_find_storage_for_consumable(pawn)
	if(!storage_item)
		return FALSE

	var/datum/component/storage/STR = storage_item.GetComponent(/datum/component/storage)
	if(!STR)
		return FALSE

	if(!STR.can_be_inserted(I, TRUE, pawn))
		return FALSE

	return STR.handle_item_insertion(I, TRUE, pawn)

/proc/human_npc_get_weapon_score(mob/living/carbon/human/pawn, obj/item/rogueweapon/W)
	if(!pawn || !W)
		return 0

	var/score = 0
	if(human_npc_get_weapon_skill_score(pawn, W))
		score++

	var/obj/item/current_item = null
	if(istype(W, /obj/item/rogueweapon/shield))
		current_item = human_npc_get_weapon_in_hand(pawn, TRUE)
	else
		current_item = human_npc_get_weapon_in_hand(pawn, FALSE)

	var/current_force = 0
	if(istype(current_item, /obj/item))
		current_force = current_item.force

	if(W.force > current_force)
		score++

	return score

/proc/human_npc_get_armor_score(mob/living/carbon/human/pawn, obj/item/candidate)
	if(!pawn || !candidate)
		return 0

	var/allowed_class = human_npc_get_armor_class_rank(pawn)
	var/item_class = human_npc_get_item_armor_class_rank(candidate)
	if(item_class > allowed_class)
		return 0

	var/score = 1
	var/obj/item/current_item = human_npc_get_equipped_competitor(pawn, candidate)

	var/current_integrity = 0
	var/current_armor = 0
	if(current_item)
		current_integrity = current_item.obj_integrity
		current_armor = human_npc_get_item_armor_total(current_item)

	var/integrity_delta = max(0, candidate.obj_integrity - current_integrity)
	score += round(integrity_delta / 10)

	var/candidate_armor = human_npc_get_item_armor_total(candidate)
	if(candidate_armor > current_armor)
		score += max(1, round((candidate_armor - current_armor) / 10))

	return score

/proc/human_npc_choose_best_captive_loot(mob/living/carbon/human/pawn, list/captive_loot)
	if(!pawn || !islist(captive_loot) || !length(captive_loot))
		return null

	var/obj/item/best_item = null
	var/best_score = 0

	for(var/obj/item/I as anything in captive_loot)
		if(QDELETED(I))
			continue
		if(!isturf(I.loc))
			continue
		if(get_dist(pawn, I) > 1)
			continue
		if(human_npc_should_ignore_captive_loot(I))
			continue

		var/score = 0

		if(istype(I, /obj/item/rogueweapon))
			var/obj/item/rogueweapon/W = I
			score = human_npc_get_weapon_score(pawn, W)
			if(score >= 2)
				return W
		else if(istype(I, /obj/item/clothing))
			score = human_npc_get_armor_score(pawn, I)
		else if(human_npc_is_capture_consumable(I))
			score = human_npc_get_consumable_score(I)

		if(score <= 0)
			continue
		if(score > best_score)
			best_score = score
			best_item = I

	return best_item

GLOBAL_LIST_EMPTY(human_npc_captive_delivery_points)
GLOBAL_LIST_EMPTY(human_npc_captive_delivery_z_map)

/proc/human_npc_ensure_captive_delivery_points()
	if(!islist(GLOB.human_npc_captive_delivery_points) || !length(GLOB.human_npc_captive_delivery_points))
		init_human_npc_captive_delivery_points()

	if(!islist(GLOB.human_npc_captive_delivery_z_map))
		GLOB.human_npc_captive_delivery_z_map = list()

/proc/init_human_npc_captive_delivery_points()
	GLOB.human_npc_captive_delivery_points = list()
	GLOB.human_npc_captive_delivery_z_map = list()

	var/list/roguetest_points = list()
	roguetest_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS] = list(
		list(24, 24, 2),
		list(25, 24, 2),
	)
	roguetest_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS] = list(
		list(24, 25, 2),
		list(25, 25, 2),
	)
	roguetest_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_DEFAULT] = list(
		list(24, 24, 2),
		list(25, 25, 2),
	)
	GLOB.human_npc_captive_delivery_points[HUMAN_NPC_CAPTURE_DELIVERY_MAP_ROGUETEST] = roguetest_points

	var/list/rockhill_points = list()
	rockhill_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS] = list(
		list(30, 30, 3),
		list(31, 30, 3),
	)
	rockhill_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS] = list(
		list(30, 31, 3),
		list(31, 31, 3),
	)
	rockhill_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_DEFAULT] = list(
		list(30, 30, 3),
		list(31, 31, 3),
	)
	GLOB.human_npc_captive_delivery_points[HUMAN_NPC_CAPTURE_DELIVERY_MAP_ROCKHILL] = rockhill_points

	var/list/dun_world_points = list()
	dun_world_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS] = list(
		list(20, 372, 4),
		list(21, 372, 4),
	)
	dun_world_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS] = list(
		list(20, 373, 4),
		list(21, 373, 4),
	)
	dun_world_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_DEFAULT] = list(
		list(20, 372, 4),
		list(21, 373, 4),
	)
	GLOB.human_npc_captive_delivery_points[HUMAN_NPC_CAPTURE_DELIVERY_MAP_DUN_WORLD] = dun_world_points

	var/list/default_points = list()
	default_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS] = list(
		list(24, 24, 2),
		list(25, 24, 2),
	)
	default_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS] = list(
		list(24, 25, 2),
		list(25, 25, 2),
	)
	default_points[HUMAN_NPC_CAPTURE_DELIVERY_FACTION_DEFAULT] = list(
		list(24, 24, 2),
		list(25, 25, 2),
	)
	GLOB.human_npc_captive_delivery_points[HUMAN_NPC_CAPTURE_DELIVERY_MAP_DEFAULT] = default_points

/proc/human_npc_get_delivery_map_alias(map_key)
	map_key = human_npc_normalize_delivery_key(map_key)
	if(!map_key)
		return null

	if(map_key == HUMAN_NPC_CAPTURE_DELIVERY_MAP_DUN_WORLD || findtext(map_key, "dun_world"))
		return HUMAN_NPC_CAPTURE_DELIVERY_MAP_DUN_WORLD

	if(map_key == HUMAN_NPC_CAPTURE_DELIVERY_MAP_ROCKHILL || findtext(map_key, "rockhill"))
		return HUMAN_NPC_CAPTURE_DELIVERY_MAP_ROCKHILL

	if(map_key == HUMAN_NPC_CAPTURE_DELIVERY_MAP_ROGUETEST || findtext(map_key, "roguetest") || findtext(map_key, "rogue_test"))
		return HUMAN_NPC_CAPTURE_DELIVERY_MAP_ROGUETEST

	return map_key

/proc/human_npc_normalize_delivery_key(value)
	if(isnull(value))
		return null

	var/text = lowertext("[value]")
	text = replacetext(text, " ", "_")
	text = replacetext(text, "-", "_")
	text = replacetext(text, ".dmm", "")
	text = replacetext(text, ".json", "")
	return text

/proc/human_npc_get_delivery_faction_alias(faction_key)
	faction_key = human_npc_normalize_delivery_key(faction_key)
	if(!faction_key)
		return null

	if(faction_key == HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS || findtext(faction_key, "bandit"))
		return HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS
	if(faction_key == HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS || findtext(faction_key, "goblin"))
		return HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS

	return faction_key

/proc/human_npc_known_delivery_map_key(map_key)
	if(!map_key)
		return null

	human_npc_ensure_captive_delivery_points()

	map_key = human_npc_get_delivery_map_alias(map_key)
	if(GLOB.human_npc_captive_delivery_points[map_key])
		return map_key

	return null

/proc/human_npc_register_captive_delivery_point(map_key, faction_key, x, y, z)
	map_key = human_npc_normalize_delivery_key(map_key)
	faction_key = human_npc_normalize_delivery_key(faction_key)
	if(!map_key || !faction_key || !x || !y || !z)
		return FALSE

	human_npc_ensure_captive_delivery_points()

	if(!GLOB.human_npc_captive_delivery_points[map_key])
		GLOB.human_npc_captive_delivery_points[map_key] = list()
	if(!GLOB.human_npc_captive_delivery_points[map_key][faction_key])
		GLOB.human_npc_captive_delivery_points[map_key][faction_key] = list()

	GLOB.human_npc_captive_delivery_points[map_key][faction_key] += list(list(x, y, z))
	return TRUE

/proc/human_npc_register_captive_delivery_z_map(z, map_key)
	map_key = human_npc_known_delivery_map_key(map_key)
	if(!z || !map_key)
		return FALSE

	if(!GLOB.human_npc_captive_delivery_z_map)
		GLOB.human_npc_captive_delivery_z_map = list()

	GLOB.human_npc_captive_delivery_z_map["[z]"] = map_key
	return TRUE

/proc/human_npc_get_current_delivery_map_key(atom/source)
	human_npc_ensure_captive_delivery_points()

	var/turf/source_turf = get_turf(source)
	if(source_turf && GLOB.human_npc_captive_delivery_z_map)
		var/z_map_key = human_npc_known_delivery_map_key(GLOB.human_npc_captive_delivery_z_map["[source_turf.z]"])
		if(z_map_key)
			return z_map_key

	if(SSmapping?.config)
		var/list/candidates = list()
		if(SSmapping.config.map_name)
			candidates += SSmapping.config.map_name
		if(SSmapping.config.map_file)
			if(islist(SSmapping.config.map_file))
				for(var/map_file as anything in SSmapping.config.map_file)
					candidates += map_file
			else
				candidates += SSmapping.config.map_file
		if(SSmapping.config.map_path)
			candidates += SSmapping.config.map_path

		for(var/candidate as anything in candidates)
			var/map_key = human_npc_known_delivery_map_key(candidate)
			if(map_key)
				return map_key

	return HUMAN_NPC_CAPTURE_DELIVERY_MAP_DEFAULT

/proc/human_npc_get_delivery_faction_keys(mob/living/carbon/human/pawn)
	var/list/result = list()
	if(!pawn)
		return result

	if(islist(pawn.faction))
		for(var/faction_key as anything in pawn.faction)
			faction_key = human_npc_get_delivery_faction_alias(faction_key)
			if(faction_key)
				result |= faction_key
	else if(pawn.faction)
		var/faction_key = human_npc_get_delivery_faction_alias(pawn.faction)
		if(faction_key)
			result |= faction_key

	// Если faction записана нестандартно, всё равно дадим двум основным лагерям шанс.
	// Для теста это важнее, чем молча не выбрать точку.
	result |= HUMAN_NPC_CAPTURE_DELIVERY_FACTION_BANDITS
	result |= HUMAN_NPC_CAPTURE_DELIVERY_FACTION_GOBLINS
	result |= HUMAN_NPC_CAPTURE_DELIVERY_FACTION_DEFAULT
	return result

/proc/human_npc_pick_delivery_turf_from_faction_points(list/points)
	if(!islist(points) || !length(points))
		return null

	var/list/shuffled_points = points.Copy()
	while(length(shuffled_points))
		var/point_index = rand(1, length(shuffled_points))
		var/list/coords = shuffled_points[point_index]
		shuffled_points.Cut(point_index, point_index + 1)
		if(!islist(coords) || length(coords) < 3)
			continue

		var/turf/destination = locate(coords[1], coords[2], coords[3])
		if(destination)
			return destination

	return null

/proc/human_npc_get_captive_delivery_turf(mob/living/carbon/human/pawn)
	if(!pawn)
		return null

	human_npc_ensure_captive_delivery_points()

	var/list/map_keys = list(human_npc_get_current_delivery_map_key(pawn), HUMAN_NPC_CAPTURE_DELIVERY_MAP_DEFAULT)
	var/list/faction_keys = human_npc_get_delivery_faction_keys(pawn)

	for(var/map_key as anything in map_keys)
		map_key = human_npc_known_delivery_map_key(map_key)
		if(!map_key)
			continue

		var/list/map_points = GLOB.human_npc_captive_delivery_points[map_key]
		if(!islist(map_points))
			continue

		for(var/faction_key as anything in faction_keys)
			faction_key = human_npc_normalize_delivery_key(faction_key)
			var/turf/destination = human_npc_pick_delivery_turf_from_faction_points(map_points[faction_key])
			if(destination)
				return destination

	return null

/proc/human_npc_is_valid_delivery_captive(mob/living/target)
	if(!target || QDELETED(target))
		return FALSE
	if(!ishuman(target))
		return FALSE
	if(!human_npc_target_already_bound(target))
		return FALSE
	if(human_npc_prisoner_is_unsalvageable(target))
		return FALSE
	return TRUE

/proc/human_npc_pick_up_captive(mob/living/carbon/human/pawn, mob/living/carbon/human/captive)
	if(!pawn || !captive)
		return FALSE
	if(QDELETED(pawn) || QDELETED(captive))
		return FALSE
	if(!human_npc_is_valid_delivery_captive(captive))
		return FALSE
	if(captive.loc == pawn)
		return TRUE
	if(!pawn.Adjacent(captive))
		return FALSE

	pawn.visible_message(span_warning("[pawn] lifts [captive] onto [pawn.p_their()] shoulder."))
	captive.forceMove(pawn)
	return TRUE

/proc/human_npc_drop_off_captive(mob/living/carbon/human/pawn, mob/living/carbon/human/captive, turf/destination)
	if(!pawn || !captive || !destination)
		return FALSE
	if(QDELETED(pawn) || QDELETED(captive))
		return FALSE

	if(captive.loc != pawn)
		return FALSE

	captive.forceMove(destination)
	captive.setDir(pawn.dir)
	pawn.visible_message(span_warning("[pawn] drops [captive] here."))
	return TRUE

/*
// Portal delivery variant. Пока оставлено как заготовка, не включать до отдельного баланса/визуала.
/proc/human_npc_portal_delivery_captive(mob/living/carbon/human/pawn, mob/living/carbon/human/captive, turf/destination)
	if(!pawn || !captive || !destination)
		return FALSE
	if(!human_npc_is_valid_delivery_captive(captive))
		return FALSE
	if(!pawn.Adjacent(captive))
		return FALSE

	pawn.visible_message(span_warning("[pawn] opens a dark portal under [captive]."))
	if(!do_after(pawn, 10 SECONDS, target = captive))
		return FALSE
	if(!human_npc_is_valid_delivery_captive(captive))
		return FALSE

	captive.forceMove(destination)
	captive.visible_message(span_warning("[captive] falls out of a dark portal."))
	return TRUE
*/
