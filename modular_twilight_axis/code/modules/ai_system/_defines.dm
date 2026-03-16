// Group AI — FEAR-level. Defines.

// ── Tasks (what group tells mob to do) ──
#define GROUP_AI_TASK_IDLE           "idle"
#define GROUP_AI_TASK_LEADER_IDLE    "leader_idle"
#define GROUP_AI_TASK_GUARD_LEADER   "guard_leader"
#define GROUP_AI_TASK_ATTACK_MELEE   "attack_melee"
#define GROUP_AI_TASK_HOLD_SLOT      "hold_slot"
#define GROUP_AI_TASK_SUPPORT        "support"
#define GROUP_AI_TASK_CONTROL        "control"
#define GROUP_AI_TASK_RETREAT        "retreat"
#define GROUP_AI_TASK_REPOSITION     "reposition"

// ── Roles (combinable bitfield) ──
#define GROUP_AI_ROLE_NONE     0
#define GROUP_AI_ROLE_LEADER   (1<<0)
#define GROUP_AI_ROLE_MDD      (1<<1)
#define GROUP_AI_ROLE_RDD      (1<<2)
#define GROUP_AI_ROLE_TANK     (1<<3)
#define GROUP_AI_ROLE_CONTROL  (1<<4)

// ── Morale states ──
#define GROUP_AI_MORALE_BROKEN     1
#define GROUP_AI_MORALE_SHAKEN     2
#define GROUP_AI_MORALE_STEADY     3
#define GROUP_AI_MORALE_AGGRESSIVE 4

// ── Events ──
#define GROUP_AI_EVENT_SPOTTED     "spotted"
#define GROUP_AI_EVENT_LOST        "lost"
#define GROUP_AI_EVENT_DAMAGED     "damaged"
#define GROUP_AI_EVENT_DIED        "died"
#define GROUP_AI_EVENT_STUNNED     "stunned"
#define GROUP_AI_EVENT_LEADER_DIED "leader_died"

// ── Formation slots ──
#define GROUP_AI_SLOT_FRONT       "front"
#define GROUP_AI_SLOT_FRONT_LEFT  "front_left"
#define GROUP_AI_SLOT_FRONT_RIGHT "front_right"
#define GROUP_AI_SLOT_BACK        "back"
#define GROUP_AI_SLOT_LEFT        "left"
#define GROUP_AI_SLOT_RIGHT       "right"
#define GROUP_AI_SLOT_BACK_LEFT   "back_left"
#define GROUP_AI_SLOT_BACK_RIGHT  "back_right"

// ── Chain priority (higher displaces lower) ──
#define GROUP_AI_CHAIN_MDD     10
#define GROUP_AI_CHAIN_TANK    20
#define GROUP_AI_CHAIN_CONTROL 30

// ── Tunables ──
#define GROUP_AI_RETREAT_HP_PCT       25
#define GROUP_AI_MORALE_HIT_LEADER    25
#define GROUP_AI_MORALE_HIT_DEATH     12
#define GROUP_AI_MORALE_HIT_STUN      6
#define GROUP_AI_MORALE_HIT_DAMAGE    4
#define GROUP_AI_EMOTE_COOLDOWN       40
#define GROUP_AI_MIN_PER_TARGET       3
#define GROUP_AI_LEADER_REASSIGN_DELAY (1 MINUTES)

// ── Globals ──
var/global/list/group_ai_groups     = list()
var/global/list/group_ai_membership = list()