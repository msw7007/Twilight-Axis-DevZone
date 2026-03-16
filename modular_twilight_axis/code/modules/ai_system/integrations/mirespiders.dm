// Group AI — mirespider integration.
// Order receiver: the ONLY bridge between group and mob.
// Group decides WHAT. Mob's native behaviors decide HOW.

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/proc/group_ai_attach_mirespider(mob/living/M)
	var/datum/group_ai_group/G = group_ai_get_or_create(M, null, /datum/group_ai_doctrine/mirespider_pack)
	if(G) G.try_pulse(TRUE)

/proc/group_ai_signal_damage(mob/living/M)
	var/datum/group_ai_group/G = group_ai_membership[M]
	if(G && !QDELETED(G)) G.member_damaged(M)

/proc/group_ai_signal_death(mob/living/M)
	var/datum/group_ai_group/G = group_ai_membership[M]
	if(G && !QDELETED(G)) G.member_died(M)

/proc/group_ai_signal_stun(mob/living/M)
	var/datum/group_ai_group/G = group_ai_membership[M]
	if(G && !QDELETED(G)) G.member_stunned(M)

// ──────────────────────────────────────────────────────────────────────────────
// Order receiver subtree.
// Runs first in the planning chain.
// Has group order → queue behavior + FINISH_PLANNING (block autonomy).
// No group / no order → return (mob breathes, fallback subtrees run).
// ──────────────────────────────────────────────────────────────────────────────

/datum/ai_planning_subtree/group_ai_order_receiver

/datum/ai_planning_subtree/group_ai_order_receiver/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(!controller?.pawn) return
	var/mob/living/pawn = controller.pawn

	// Get group
	var/datum/group_ai_group/G = group_ai_membership[pawn]
	if(!G || QDELETED(G)) return  // No group → breathe

	// Observer duty: report enemies to group
	for(var/mob/living/T in view(G.doctrine.max_target_scan, pawn))
		if(G.doctrine.is_valid_enemy(G, pawn, T))
			G.observe_target(pawn, T)
	G.try_pulse()

	// Read order
	var/datum/group_ai_order/O = G.orders[pawn]
	if(!O || O.task == GROUP_AI_TASK_IDLE) return  // No order → breathe

	var/datum/group_ai_profile/P = G.profiles[pawn]

	// ── Execute by task ──
	switch(O.task)

		// Non-combat: move to anchor, block everything
		if(GROUP_AI_TASK_LEADER_IDLE, GROUP_AI_TASK_GUARD_LEADER, GROUP_AI_TASK_RETREAT, GROUP_AI_TASK_REPOSITION)
			// Per ТЗ proximity: MDD/Tank in RETREAT, if adjacent to enemy → bite first
			if(O.task == GROUP_AI_TASK_RETREAT && O.target && !QDELETED(O.target))
				var/r = G.role_map[pawn] || GROUP_AI_ROLE_NONE
				if((r & (GROUP_AI_ROLE_MDD | GROUP_AI_ROLE_TANK)) && get_dist(pawn, O.target) <= 1)
					if(P) P.execute_melee(controller, pawn, O.target)
					return SUBTREE_RETURN_FINISH_PLANNING
			if(O.anchor && get_dist(pawn, O.anchor) > 0)
				controller.set_blackboard_key(BB_TRAVEL_DESTINATION, O.anchor)
				controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING

		// Melee attack: set target, queue melee, FINISH_PLANNING
		if(GROUP_AI_TASK_ATTACK_MELEE)
			if(!O.target || QDELETED(O.target)) return SUBTREE_RETURN_FINISH_PLANNING
			if(P) P.execute_melee(controller, pawn, O.target)
			return SUBTREE_RETURN_FINISH_PLANNING

		// Tank holds front slot
		if(GROUP_AI_TASK_HOLD_SLOT)
			if(!O.target || QDELETED(O.target)) return SUBTREE_RETURN_FINISH_PLANNING
			if(get_dist(pawn, O.target) <= 1)
				// Adjacent: attack
				if(P) P.execute_melee(controller, pawn, O.target)
			else if(O.slot_turf)
				// Approach slot
				controller.set_blackboard_key(BB_TRAVEL_DESTINATION, O.slot_turf)
				controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING

		// Ranged support with kiting
		if(GROUP_AI_TASK_SUPPORT)
			if(!O.target || QDELETED(O.target)) return SUBTREE_RETURN_FINISH_PLANNING
			var/dist = get_dist(pawn, O.target)
			// Per ТЗ: RDD ≤ 2 tiles from threat → retreat to 3
			if(dist <= 2)
				var/turf/back = group_ai_pick_step_away(pawn, O.target, 4)
				if(back)
					controller.set_blackboard_key(BB_TRAVEL_DESTINATION, back)
					controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_TRAVEL_DESTINATION)
				return SUBTREE_RETURN_FINISH_PLANNING
			// Too far: approach
			if(dist > 6 && O.anchor)
				controller.set_blackboard_key(BB_TRAVEL_DESTINATION, O.anchor)
				controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_TRAVEL_DESTINATION)
				return SUBTREE_RETURN_FINISH_PLANNING
			// In range: delegate to profile (LoS check, shoot, cocoon escalation)
			if(P) P.execute_ranged(controller, pawn, O.target, G.members)
			return SUBTREE_RETURN_FINISH_PLANNING

		// Control: approach back slot, then delegate to profile
		if(GROUP_AI_TASK_CONTROL)
			if(!O.target || QDELETED(O.target)) return SUBTREE_RETURN_FINISH_PLANNING
			if(get_dist(pawn, O.target) <= 2)
				// Close: profile decides (cocoon, melee, grab, etc.)
				if(P) P.execute_control(controller, pawn, O.target)
				return SUBTREE_RETURN_FINISH_PLANNING
			if(O.slot_turf)
				controller.set_blackboard_key(BB_TRAVEL_DESTINATION, O.slot_turf)
				controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_TRAVEL_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING

	// Unknown task: block
	return SUBTREE_RETURN_FINISH_PLANNING

// ──────────────────────────────────────────────────────────────────────────────
// AI controllers (modular override)
// Order receiver first → group priority.
// Fallback subtrees after → mob breathes when no group/order.
// ──────────────────────────────────────────────────────────────────────────────

/datum/ai_controller/mirespider
	planning_subtrees = list(
		/datum/ai_planning_subtree/group_ai_order_receiver,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/simple_self_recovery,
	)

/datum/ai_controller/mirespider_lurker
	planning_subtrees = list(
		/datum/ai_planning_subtree/group_ai_order_receiver,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/basic_ranged_attack_subtree/mirespider_lurker,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)

/datum/ai_controller/mirespider_paralytic
	planning_subtrees = list(
		/datum/ai_planning_subtree/group_ai_order_receiver,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)

// ──────────────────────────────────────────────────────────────────────────────
// Mob hooks
// ──────────────────────────────────────────────────────────────────────────────

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/Initialize()
	. = ..()
	group_ai_attach_mirespider(src)

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/death(gibbed)
	group_ai_signal_death(src)
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	. = ..()
	if(damage > 0) group_ai_signal_damage(src)

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/Initialize()
	. = ..()
	group_ai_attach_mirespider(src)

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/death(gibbed)
	group_ai_signal_death(src)
	return ..()

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	. = ..()
	if(damage > 0) group_ai_signal_damage(src)

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/Initialize()
	. = ..()
	group_ai_attach_mirespider(src)

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/death(gibbed)
	group_ai_signal_death(src)
	return ..()

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	. = ..()
	if(damage > 0) group_ai_signal_damage(src)