/datum/ai_controller/mirespider_lurker
	movement_delay = MIRESPIDER_MOVEMENT_SPEED

	ai_movement = /datum/ai_movement/hybrid_pathing

	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/simple_find_target/closest,
		/datum/ai_planning_subtree/basic_ranged_attack_subtree/mirespider_lurker,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target
	)

	idle_behavior = /datum/idle_behavior/idle_random_walk
