// =====================================================================
//  Mirespiders — group AI integration + lurker combat AI
// =====================================================================

// ---- Species-specific defines ----
#define GROUP_TACTIC_ELIMINATE      "mirespider_eliminate"
#define GROUP_TACTIC_COCOON_CAPTURE "mirespider_cocoon_capture"
#define GROUP_COMM_ENGAGE  "engage"
#define GROUP_COMM_CAPTURE "capture"
#define GROUP_COMM_RETREAT "retreat"
#define BB_LURKER_KITE     "bb_lurker_kite"
#define LURKER_KITE_DIST   3

// ========================= GROUP =========================

/datum/ai_group/mirespider
	cohesion_range = 10
	role_paths = list(
		/datum/ai_group_role/mirespider_cocooner,
		/datum/ai_group_role/mirespider_fighter,
	)
	tactic_paths = list(
		/datum/ai_tactic/mirespider_retreat,
		/datum/ai_tactic/mirespider_cocoon_capture,
		/datum/ai_tactic/mirespider_eliminate,
	)

// ========================= ROLES =========================

// Cocooner — lurker only, max 1, needs 2+ members
/datum/ai_group_role/mirespider_cocooner
	id = "cocooner"
	name = "cocooner"
	priority = 100
	max_per_group = 1
	min_group_size = 2
	comm_messages = list(
		GROUP_COMM_CAPTURE = list("угрожающе шипит и подтягивается ближе к добыче.", "издаёт низкое шипение, готовясь опутать жертву."),
		GROUP_COMM_ENGAGE = list("злобно шипит, готовясь выплюнуть паутину."),
		GROUP_COMM_RETREAT = list("испуганно визжит и пятится назад!"),
	)

/datum/ai_group_role/mirespider_cocooner/is_valid(mob/living/M)
	return istype(M, /mob/living/simple_animal/hostile/rogue/mirespider_lurker)

/datum/ai_group_role/mirespider_cocooner/apply_bb(datum/ai_controller/C, datum/ai_group/group, mob/living/M)
	..()
	C.set_blackboard_key(BB_GROUP_CAN_CAPTURE, TRUE)

// Fighter — everyone else, fallback
/datum/ai_group_role/mirespider_fighter
	id = "fighter"
	name = "fighter"
	priority = 10
	max_per_group = 99
	comm_messages = list(
		GROUP_COMM_ENGAGE = list("резко дёргается вперёд, готовясь рвать добычу.", "щёлкает жвалами и бросается на врага."),
		GROUP_COMM_RETREAT = list("испуганно пищит и отступает!", "панически шуршит лапками, пытаясь скрыться!"),
	)

// ========================= TACTICS =========================

// Eliminate — default combat, focus fire
/datum/ai_tactic/mirespider_eliminate
	id = GROUP_TACTIC_ELIMINATE
	name = "eliminate"
	priority = 50
	comm_intent = GROUP_COMM_ENGAGE

/datum/ai_tactic/mirespider_eliminate/can_run(datum/ai_group/group)
	return !!group?.focus_target

// Cocoon capture — target in crit, cocooner cocoons, others guard
/datum/ai_tactic/mirespider_cocoon_capture
	id = GROUP_TACTIC_COCOON_CAPTURE
	name = "cocoon capture"
	priority = 100
	comm_intent = GROUP_COMM_CAPTURE
	var/min_members = 2

/datum/ai_tactic/mirespider_cocoon_capture/can_run(datum/ai_group/group)
	if(!group?.focus_target || length(group.members) < min_members)
		return FALSE
	return group_ai_is_crit(group.focus_target)

/datum/ai_tactic/mirespider_cocoon_capture/apply_bb(datum/ai_controller/C, datum/ai_group/group, mob/living/M, datum/ai_group_role/role)
	..()
	C.set_blackboard_key(BB_GROUP_SHOULD_NOT_KILL, TRUE)

// Retreat — outnumbered
/datum/ai_tactic/mirespider_retreat
	id = GROUP_TACTIC_RETREAT
	name = "retreat"
	priority = 200
	comm_intent = GROUP_COMM_RETREAT
	var/enemy_ratio = 2

/datum/ai_tactic/mirespider_retreat/can_run(datum/ai_group/group)
	if(!group || !length(group.enemies) || !length(group.members))
		return FALSE
	return length(group.enemies) >= length(group.members) * enemy_ratio

// ========================= LURKER RANGED BEHAVIOR =========================
// Subtype adds CAN_PLAN_DURING_EXECUTION so planning isn't blocked while shooting.
// Without this, lurker_combat subtree can't switch to melee when player closes in.

/datum/ai_behavior/basic_ranged_attack/lurker
	behavior_flags = AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

// ========================= LURKER COMBAT SUBTREE =========================
// Replaces basic_ranged_attack_subtree/mirespider_lurker.
// Logic: crit → cocoon, adjacent → bite + kite, far → shoot.

/datum/ai_planning_subtree/lurker_combat

/datum/ai_planning_subtree/lurker_combat/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return
	var/mob/living/pawn = controller.pawn

	// Crit → hand off to cocoon subtrees
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat || group_ai_is_crit(L))
			controller.set_blackboard_key(BB_BASIC_MOB_COCOON_TARGET, L)
			controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
			return

	// Clear followers (existing lurker mechanic)
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/lurker = pawn
	if(istype(lurker))
		lurker.clear_followers_if_any()

	var/dist = get_dist(pawn, target)

	// Kite phase: just bit, back off to LURKER_KITE_DIST
	if(controller.blackboard[BB_LURKER_KITE])
		if(dist < LURKER_KITE_DIST)
			controller.queue_behavior(/datum/ai_behavior/cover_minimum_distance, BB_BASIC_MOB_CURRENT_TARGET, LURKER_KITE_DIST)
			return SUBTREE_RETURN_FINISH_PLANNING
		// Reached safe distance → clear flag, shoot
		controller.clear_blackboard_key(BB_LURKER_KITE)

	// Adjacent → melee bite, then kite next tick
	if(dist <= 1)
		controller.set_blackboard_key(BB_LURKER_KITE, TRUE)
		controller.queue_behavior(/datum/ai_behavior/basic_melee_attack, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
		return SUBTREE_RETURN_FINISH_PLANNING

	// Far → ranged attack (lurker subtype allows replanning while shooting)
	controller.queue_behavior(/datum/ai_behavior/basic_ranged_attack/lurker, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING

// ========================= MOB PATCHES =========================

/mob/living/simple_animal/hostile/retaliate/rogue/mirespider/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ai_group_member, /datum/ai_group/mirespider)

/mob/living/simple_animal/hostile/rogue/mirespider_lurker/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ai_group_member, /datum/ai_group/mirespider)

/mob/living/simple_animal/hostile/rogue/mirespider_paralytic/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ai_group_member, /datum/ai_group/mirespider)

// ========================= CONTROLLER OVERRIDES =========================

/datum/ai_controller/mirespider
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/group_tactics,
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
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/group_tactics,
		/datum/ai_planning_subtree/lurker_combat,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)

/datum/ai_controller/mirespider_paralytic
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/group_tactics,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)
