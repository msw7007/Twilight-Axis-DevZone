/datum/ai_controller/human_npc/TryPossessPawn(atom/new_pawn)
	. = ..()
	var/mob/living/living_pawn = new_pawn
	RegisterSignal(new_pawn, COMSIG_MOB_MOVESPEED_UPDATED, PROC_REF(update_movespeed))
	movement_delay = living_pawn.cached_multiplicative_slowdown
	new_pawn.AddComponent(/datum/component/ai_inventory_manager)
	new_pawn.AddElement(/datum/element/interrupt_on_damage)
	new_pawn.AddComponent(/datum/component/combat_vocalizer)
	_insert_bind_capture_subtrees()

/datum/ai_controller/human_npc/proc/_insert_bind_capture_subtrees()
	var/datum/ai_planning_subtree/bind_rope_subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/human_npc_bind_capture/rope]
	var/datum/ai_planning_subtree/bind_chain_subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/human_npc_bind_capture/chain]

	if(!bind_rope_subtree || !bind_chain_subtree)
		return

	var/list/new_subtrees = list()
	var/inserted = FALSE

	for(var/datum/ai_planning_subtree/tree as anything in planning_subtrees)
		if(!inserted)
			if(istype(tree, /datum/ai_planning_subtree/ranged_attack_subtree) || istype(tree, /datum/ai_planning_subtree/basic_melee_attack_subtree/human_npc))
				if(!(bind_rope_subtree in new_subtrees))
					new_subtrees += bind_rope_subtree
				if(!(bind_chain_subtree in new_subtrees))
					new_subtrees += bind_chain_subtree
				inserted = TRUE
		if(tree == bind_rope_subtree || tree == bind_chain_subtree)
			continue
		new_subtrees += tree

	if(!inserted)
		if(!(bind_rope_subtree in new_subtrees))
			new_subtrees += bind_rope_subtree
		if(!(bind_chain_subtree in new_subtrees))
			new_subtrees += bind_chain_subtree

	planning_subtrees = new_subtrees
