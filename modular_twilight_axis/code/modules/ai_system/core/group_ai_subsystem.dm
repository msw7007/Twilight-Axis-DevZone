SUBSYSTEM_DEF(group_ai)
	name = "Group AI"
	wait = 1
	flags = SS_KEEP_TIMING
	priority = FIRE_PRIORITY_NPC

	var/list/datum/group_ai_group/groups = list()
	var/list/datum/group_ai_host/hosts = list()

/datum/controller/subsystem/group_ai/fire(resumed)
	for(var/datum/group_ai_group/group as anything in groups)
		if(QDELETED(group))
			continue
		group.process(wait * 0.1)

/datum/controller/subsystem/group_ai/proc/register_group(datum/group_ai_group/group)
	if(QDELETED(group))
		return
	groups |= group

/datum/controller/subsystem/group_ai/proc/unregister_group(datum/group_ai_group/group)
	groups -= group

/datum/controller/subsystem/group_ai/proc/register_host(datum/group_ai_host/host)
	if(QDELETED(host))
		return
	hosts |= host

/datum/controller/subsystem/group_ai/proc/unregister_host(datum/group_ai_host/host)
	hosts -= host
