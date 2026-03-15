// Generic Group AI defines and globals.

#define BB_GROUP_AI_HANDLE "group_ai_handle"
#define BB_GROUP_AI_ROLE "group_ai_role"
#define BB_GROUP_AI_TASK "group_ai_task"
#define BB_GROUP_AI_SLOT_KEY "group_ai_slot_key"
#define BB_GROUP_AI_SLOT_TURF "group_ai_slot_turf"
#define BB_GROUP_AI_RESERVE_TURF "group_ai_reserve_turf"
#define BB_GROUP_AI_ANCHOR_TURF "group_ai_anchor_turf"
#define BB_GROUP_AI_SHARED_TARGET "group_ai_shared_target"
#define BB_GROUP_AI_LAST_SEEN_TARGET "group_ai_last_seen_target"
#define BB_GROUP_AI_ENGAGEMENT_ID "group_ai_engagement_id"
#define BB_GROUP_AI_OUTER_TURF "group_ai_outer_turf"

#define GROUP_AI_DIRTY_NONE 0
#define GROUP_AI_DIRTY_LEADER (1<<0)
#define GROUP_AI_DIRTY_TARGET (1<<1)
#define GROUP_AI_DIRTY_SLOTS (1<<2)
#define GROUP_AI_DIRTY_TASKS (1<<3)
#define GROUP_AI_DIRTY_MORALE (1<<4)
#define GROUP_AI_DIRTY_MEMBERSHIP (1<<5)
#define GROUP_AI_DIRTY_ALL (GROUP_AI_DIRTY_LEADER | GROUP_AI_DIRTY_TARGET | GROUP_AI_DIRTY_SLOTS | GROUP_AI_DIRTY_TASKS | GROUP_AI_DIRTY_MORALE | GROUP_AI_DIRTY_MEMBERSHIP)

#define GROUP_AI_MORALE_BROKEN 1
#define GROUP_AI_MORALE_SHAKEN 2
#define GROUP_AI_MORALE_STEADY 3
#define GROUP_AI_MORALE_PRESSURE 4

#define GROUP_AI_ROLE_LEADER "leader"
#define GROUP_AI_ROLE_RANGED "ranged"
#define GROUP_AI_ROLE_MELEE "melee"
#define GROUP_AI_ROLE_SKIRMISHER "skirmisher"
#define GROUP_AI_ROLE_SUPPORT "support"

#define GROUP_AI_TASK_NONE "none"
#define GROUP_AI_TASK_COMMAND "command"
#define GROUP_AI_TASK_RANGED_HOLD "ranged_hold"
#define GROUP_AI_TASK_PRIMARY "primary"
#define GROUP_AI_TASK_RESERVE "reserve"
#define GROUP_AI_TASK_OUTER "outer"
#define GROUP_AI_TASK_RECOVERY "recovery"
#define GROUP_AI_TASK_DISENGAGE "disengage"

#define GROUP_AI_MATRIX_PRIMARY list("2", "4", "6", "8")
#define GROUP_AI_MATRIX_RESERVE list("1", "3", "7", "9")

var/global/list/group_ai_groups = list()
var/global/list/group_ai_membership = list()

/proc/group_ai_cardinals()
	return list(NORTH, SOUTH, EAST, WEST)
