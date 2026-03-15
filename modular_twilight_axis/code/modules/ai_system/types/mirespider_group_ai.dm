/// ===========================================================
/// Mire spider group AI
/// Entire spider implementation in one file
/// ===========================================================

#define SPIDER_MODE_IMMOBILIZE "spider_immobilize"
#define SPIDER_MODE_WRAP "spider_wrap"

#define AIROLE_LURKER "lurker"
#define AIROLE_SWARMER "swarmer"
#define AIROLE_PARALYTIC "paralytic"
#define AIROLE_WRAPPER "wrapper"

#define AISIG_SPIDER_CLAIM_WRAP "spider_claim_wrap"

/datum/group_ai_driver/simple_hostile/spider
	owner = null

/datum/group_ai_driver/simple_hostile/spider/lurker/do_special(atom/target)
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/L = owner
	if(!istype(L) || !can_act() || QDELETED(target))
		return FALSE
	return L.try_wrap_target(target)

/datum/group_ai_order/spider_wrap_target
	id = "spider_wrap_target"
	timeout = 20

/datum/group_ai_order/spider_wrap_target/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	if(host.driver.get_dist_to(target) > 1)
	{
		host.step_towards_target(target)
		return TRUE
	}

	if(host.do_special(target))
		return finish()

	return TRUE

/datum/group_ai_order/spider_guard_wrapper
	id = "spider_guard_wrapper"
	timeout = 8

/datum/group_ai_order/spider_guard_wrapper/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	var/datum/group_ai_host/wrapper = target
	if(QDELETED(wrapper))
		return fail()

	if(host.driver.get_dist_to(wrapper.get_owner()) > 2)
	{
		host.step_towards_target(wrapper.get_owner())
		return TRUE
	}

	var/atom/enemy = host.group?.current_target
	if(enemy && host.driver.get_dist_to(enemy) <= 1)
		host.do_melee(enemy)

	return TRUE

/datum/group_ai_role/spider_lurker
	id = AIROLE_LURKER

/datum/group_ai_role/spider_lurker/pick_order(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(QDELETED(target))
		return new /datum/group_ai_order/follow_leader(host, group?.leader?.get_owner())

	var/dist = host.driver.get_dist_to(target)

	var/datum/group_ai_gate/self_low_hp/low_hp = new
	if(low_hp.check(group, host, target))
	{
		qdel(low_hp)
		return new /datum/group_ai_order/retreat_target(host, target)
	}
	qdel(low_hp)

	var/datum/group_ai_group/spider_pack/spider_group = group
	if(istype(spider_group) && spider_group.current_mode == SPIDER_MODE_WRAP)
	{
		if(!spider_group.wrap_claimed_by)
			spider_group.wrap_claimed_by = host

		if(spider_group.wrap_claimed_by == host)
			return new /datum/group_ai_order/spider_wrap_target(host, target)

		return new /datum/group_ai_order/spider_guard_wrapper(host, spider_group.wrap_claimed_by)
	}

	if(group.current_mode == GROUP_MODE_LIQUIDATE)
	{
		if(dist <= 1)
			return new /datum/group_ai_order/finish_target(host, target)
		return new /datum/group_ai_order/ranged_target(host, target)
	}

	if(dist <= 1)
		return new /datum/group_ai_order/melee_then_retreat(host, target)

	return new /datum/group_ai_order/ranged_target(host, target)

/datum/group_ai_role/spider_swarmer
	id = AIROLE_SWARMER

/datum/group_ai_role/spider_swarmer/pick_order(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(QDELETED(target))
		return new /datum/group_ai_order/follow_leader(host, group?.leader?.get_owner())

	var/datum/group_ai_group/spider_pack/spider_group = group
	if(istype(spider_group) && spider_group.current_mode == SPIDER_MODE_WRAP && spider_group.wrap_claimed_by && spider_group.wrap_claimed_by != host)
		return new /datum/group_ai_order/spider_guard_wrapper(host, spider_group.wrap_claimed_by)

	if(group.current_mode == GROUP_MODE_LIQUIDATE)
		return new /datum/group_ai_order/fill_melee_slot(host, target)

	return new /datum/group_ai_order/fill_melee_slot(host, target)

/datum/group_ai_role/spider_paralytic
	id = AIROLE_PARALYTIC

/datum/group_ai_role/spider_paralytic/pick_order(datum/group_ai_group/group, datum/group_ai_host/host, atom/target)
	if(QDELETED(target))
		return new /datum/group_ai_order/follow_leader(host, group?.leader?.get_owner())

	var/datum/group_ai_group/spider_pack/spider_group = group
	if(istype(spider_group) && spider_group.current_mode == SPIDER_MODE_WRAP && spider_group.wrap_claimed_by && spider_group.wrap_claimed_by != host)
		return new /datum/group_ai_order/spider_guard_wrapper(host, spider_group.wrap_claimed_by)

	if(group.current_mode == GROUP_MODE_LIQUIDATE)
		return new /datum/group_ai_order/fill_melee_slot(host, target)

	return new /datum/group_ai_order/fill_melee_slot(host, target)

/datum/group_ai_group/spider_pack
	id = "spider_pack"
	var/datum/group_ai_host/wrap_claimed_by

/datum/group_ai_group/spider_pack/add_host(datum/group_ai_host/host)
	..()
	var/mob/living/owner = host.get_owner()
	if(istype(owner, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		leader = host

/datum/group_ai_group/spider_pack/remove_host(datum/group_ai_host/host)
	if(wrap_claimed_by == host)
		wrap_claimed_by = null
	..()

/datum/group_ai_group/spider_pack/recalculate_mode()
	if(QDELETED(current_target))
	{
		current_mode = GROUP_MODE_IDLE
		wrap_claimed_by = null
		return
	}

	if(get_group_health_ratio() <= 0.75)
	{
		current_mode = GROUP_MODE_LIQUIDATE
		wrap_claimed_by = null
		return
	}

	if(is_target_prone(current_target))
	{
		current_mode = SPIDER_MODE_WRAP
		return
	}

	current_mode = SPIDER_MODE_IMMOBILIZE
	wrap_claimed_by = null

/datum/group_ai_group/spider_pack/assign_roles()
	if(!leader && length(members))
	{
		for(var/datum/group_ai_host/host as anything in members)
			var/mob/living/owner = host.get_owner()
			if(istype(owner, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
			{
				leader = host
				break
			}
		if(!leader)
			leader = members[1]
	}

	for(var/datum/group_ai_host/host as anything in members)
		var/mob/living/owner = host.get_owner()
		if(QDELETED(owner))
			continue

		if(istype(owner, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		{
			host.current_role_id = AIROLE_LURKER
			continue
		}

		if(istype(owner, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
		{
			host.current_role_id = AIROLE_PARALYTIC
			continue
		}

		host.current_role_id = AIROLE_SWARMER

/datum/group_ai_group/spider_pack/get_role_datum(datum/group_ai_host/host)
	switch(host.current_role_id)
		if(AIROLE_LURKER)
			return new /datum/group_ai_role/spider_lurker
		if(AIROLE_SWARMER)
			return new /datum/group_ai_role/spider_swarmer
		if(AIROLE_PARALYTIC)
			return new /datum/group_ai_role/spider_paralytic
	return null

/proc/find_existing_spider_pack(mob/living/source, radius = 10)
	for(var/mob/living/M in view(radius, source))
		if(M == source)
			continue

		if(!istype(M, /mob/living/simple_animal/hostile/retaliate/rogue/mirespider) && \
		   !istype(M, /mob/living/simple_animal/hostile/rogue/mirespider_lurker) && \
		   !istype(M, /mob/living/simple_animal/hostile/rogue/mirespider_paralytic))
			continue

		var/datum/group_ai_host/H = M.group_ai_host
		if(H?.group)
			return H.group

	return null

/proc/bootstrap_spider_group_ai(mob/living/source, list/role_ids, leader_candidate = FALSE)
	var/datum/group_ai_driver/driver
	if(istype(source, /mob/living/simple_animal/hostile/rogue/mirespider_lurker))
		driver = new /datum/group_ai_driver/simple_hostile/spider/lurker(source)
	else
		driver = new /datum/group_ai_driver/simple_hostile/spider(source)

	var/datum/group_ai_host/host = new /datum/group_ai_host(driver)
	var/datum/group_ai_group/spider_pack/group = find_existing_spider_pack(source)

	host.is_leader_candidate = leader_candidate
	for(var/role_id in role_ids)
		host.add_role(role_id)

	if(!group)
		group = new /datum/group_ai_group/spider_pack

	group.add_host(host)
	return host

/mob/living
	var/datum/group_ai_host/group_ai_host

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/Initialize()
	. = ..()
	update_icon()
	ADD_TRAIT(src, TRAIT_NOPAINSTUN, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_KNEESTINGER_IMMUNITY, INNATE_TRAIT)

	AIStatus = AI_OFF
	can_have_ai = FALSE
	QDEL_NULL(ai_controller)

	group_ai_host = bootstrap_spider_group_ai(src, list(AIROLE_SWARMER))
	if(group_ai_host)
		group_ai_host.hot_swap_recent_damage_threshold = 15

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NOPAINSTUN, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_KNEESTINGER_IMMUNITY, INNATE_TRAIT)

	AIStatus = AI_OFF
	can_have_ai = FALSE
	QDEL_NULL(ai_controller)

	group_ai_host = bootstrap_spider_group_ai(src, list(AIROLE_LURKER), TRUE)
	if(group_ai_host)
		group_ai_host.can_claim_melee_slot = FALSE
		group_ai_host.allow_hot_swap = FALSE
		group_ai_host.ranged_cd = 20
		group_ai_host.special_cd = 30

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/Initialize()
	. = ..()

	AIStatus = AI_OFF
	can_have_ai = FALSE
	QDEL_NULL(ai_controller)

	group_ai_host = bootstrap_spider_group_ai(src, list(AIROLE_PARALYTIC))
	if(group_ai_host)
		group_ai_host.hot_swap_recent_damage_threshold = 18

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/Destroy()
	QDEL_NULL(group_ai_host)
	return ..()

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/Destroy()
	QDEL_NULL(group_ai_host)
	return ..()

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/Destroy()
	QDEL_NULL(group_ai_host)
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/taunted(mob/user)
	emote("aggro")
	if(group_ai_host)
		group_ai_host.push_signal(AISIG_TAUNT, user)
	return

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/Life()
	. = ..()
	spider_group_ai_sense()

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/Life()
	. = ..()
	spider_group_ai_sense()

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/Life()
	. = ..()
	spider_group_ai_sense()

/mob/living/simple_animal/proc/spider_group_ai_sense()
	return

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/spider_group_ai_sense()
	if(!group_ai_host)
		return

	for(var/mob/living/L in view(vision_range, src))
		if(L == src)
			continue
		if(L.stat >= DEAD)
			continue
		if(faction_check_mob(L, TRUE))
			continue

		group_ai_host.push_signal(AISIG_SEE_ENEMY, L)
		if(!(L.mobility_flags & MOBILITY_STAND) || L.stat >= UNCONSCIOUS)
			group_ai_host.push_signal(AISIG_TARGET_PRONE, L)
		break

	if(pulledby)
		group_ai_host.push_signal(AISIG_PULL, pulledby)

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/spider_group_ai_sense()
	if(!group_ai_host)
		return

	for(var/mob/living/L in view(vision_range, src))
		if(L == src)
			continue
		if(L.stat >= DEAD)
			continue
		if(faction_check_mob(L, TRUE))
			continue

		group_ai_host.push_signal(AISIG_SEE_ENEMY, L)
		if(!(L.mobility_flags & MOBILITY_STAND) || L.stat >= UNCONSCIOUS)
			group_ai_host.push_signal(AISIG_TARGET_PRONE, L)
		break

	if(pulledby)
		group_ai_host.push_signal(AISIG_PULL, pulledby)

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/spider_group_ai_sense()
	if(!group_ai_host)
		return

	for(var/mob/living/L in view(vision_range, src))
		if(L == src)
			continue
		if(L.stat >= DEAD)
			continue
		if(faction_check_mob(L, TRUE))
			continue

		group_ai_host.push_signal(AISIG_SEE_ENEMY, L)
		if(!(L.mobility_flags & MOBILITY_STAND) || L.stat >= UNCONSCIOUS)
			group_ai_host.push_signal(AISIG_TARGET_PRONE, L)
		break

	if(pulledby)
		group_ai_host.push_signal(AISIG_PULL, pulledby)

/mob/living/simple_animal/proc/group_ai_report_damage(atom/attacker, amount)
	return

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/group_ai_report_damage(atom/attacker, amount)
	if(group_ai_host)
		group_ai_host.push_signal(AISIG_TAKE_DAMAGE, attacker, list("amount" = amount))

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/group_ai_report_damage(atom/attacker, amount)
	if(group_ai_host)
		group_ai_host.push_signal(AISIG_TAKE_DAMAGE, attacker, list("amount" = amount))

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/group_ai_report_damage(atom/attacker, amount)
	if(group_ai_host)
		group_ai_host.push_signal(AISIG_TAKE_DAMAGE, attacker, list("amount" = amount))

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/proc/try_wrap_target(atom/target)
	return FALSE
