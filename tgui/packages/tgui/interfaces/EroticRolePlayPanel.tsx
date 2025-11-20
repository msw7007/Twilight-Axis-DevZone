import { type ReactNode, useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Divider,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

export type OrgNode = {
  id: string;
  name: string;
  busy?: boolean;
  side?: 'actor' | 'partner';
  sensitivity?: number;
  pain?: number;
};

export type SexAction = {
  type: string;
  name: string;
  tags?: string[];
};

export type PartnerEntry = {
  ref: string;
  name: string;
};

export type ActiveLink = {
  id: string;
  actor_organ_id: string;
  partner_organ_id: string;
  action_type: string;
  action_name: string;
  speed: number;
  force: number;
  do_until_finished?: boolean;
  sensitivity?: number;
  pain?: number;
};

export type SexSessionData = {
  title: string;
  session_name?: string;

  actor_name: string;
  partner_name?: string;

  partners?: PartnerEntry[];
  current_partner_ref?: string | null;

  status_organs?: OrgNode[];
  partner_organs?: OrgNode[];
  selected_actor_organ?: string;
  selected_partner_organ?: string;

  speed: number;
  force: number;
  speed_names: string[];
  force_names: string[];

  actor_arousal?: number;
  partner_arousal?: number;
  show_partner_arousal?: boolean;

  frozen?: boolean;
  do_until_finished?: boolean;
  do_knot_action?: boolean;
  yield_to_partner?: boolean;

  actions?: SexAction[];
  can_perform?: string[];
  available_tags?: string[];
  current_action?: string;

  active_links?: ActiveLink[];
};

const speedColors = ['#eac8de', '#e9a8d1', '#f05ee1', '#d146f5'];
const forceColors = ['#eac8de', '#e9a8d1', '#f05ee1', '#d146f5'];

const Pill: React.FC<{
  selected?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  children?: ReactNode;
}> = ({ selected, disabled, onClick, children }) => (
  <Button
    inline
    compact
    disabled={disabled}
    selected={!!selected}
    style={{
      borderRadius: 9999,
      padding: '2px 10px',
      margin: 2,
    }}
    onClick={onClick}
  >
    {children}
  </Button>
);

const prettyOrgName = (name: string) =>
  name
    .replace(/(\d+[^]*)$/u, '')
    .trim();

const OrganList: React.FC<{
  title: string;
  organs: OrgNode[];
  selectedId?: string;
  onSelect: (id: string) => void;
}> = ({ title, organs, selectedId, onSelect }) => (
  <Section title={title} fill>
    <Stack vertical>
      {organs.map((org) => (
        <Stack.Item key={org.id}>
          <Button
            fluid
            selected={selectedId === org.id}
            disabled={!!org.busy}
            onClick={() => onSelect(org.id)}
          >
            <Box as="span">
              {prettyOrgName(org.name)}
              {org.busy && (
                <Box as="span" ml={1} color="bad">
                  ●
                </Box>
              )}
            </Box>
          </Button>
        </Stack.Item>
      ))}
    </Stack>
  </Section>
);

const PartnerSelector: React.FC<{
  actorName: string;
  partners: PartnerEntry[];
  currentRef?: string | null;
  onChange: (ref: string) => void;
}> = ({ actorName, partners, currentRef, onChange }) => {
  const [open, setOpen] = useState(false);

  const current =
    partners.find((p) => p.ref === currentRef) || partners[0] || null;

  return (
    <Section>
      <Box textAlign="center" bold>
        {actorName}{' '}
        <Box as="span" color="label">
          {' ↔ '}
        </Box>
        <Button
          inline
          compact
          onClick={() => setOpen((prev) => !prev)}
          selected={open}
        >
          {current ? current.name : '—'}
        </Button>
      </Box>
      {open && partners.length > 1 && (
        <Box mt={1}>
          <Stack justify="center" wrap>
            {partners.map((p) => (
              <Stack.Item key={p.ref} style={{ margin: 2 }}>
                <Button
                  inline
                  compact
                  selected={current?.ref === p.ref}
                  onClick={() => {
                    onChange(p.ref);
                    setOpen(false);
                  }}
                >
                  {p.name}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Box>
      )}
    </Section>
  );
};

const ArousalBars: React.FC<{
  actorName: string;
  partnerLabel: string;
  actorArousal: number;
  partnerArousal: number;
  showPartnerBar: boolean;
  onSetActor: () => void;
  onSetPartner: () => void;
}> = ({
  actorName,
  partnerLabel,
  actorArousal,
  partnerArousal,
  showPartnerBar,
  onSetActor,
  onSetPartner,
}) => {
  const maxArousal = 100;

  const clamp01 = (v: number) => Math.max(0, Math.min(1, v));

  const actorFrac = clamp01(actorArousal / maxArousal);
  const partnerFrac = clamp01(partnerArousal / maxArousal);

  const actorPct = Math.round(actorFrac * 100);
  const partnerPct = Math.round(partnerFrac * 100);

  return (
    <Section>
      <LabeledList>
        <LabeledList.Item
          label={actorName || 'Источник'}
          buttons={
            <Box as="span" ml={1} color="label">
              {actorArousal} / {maxArousal} ({actorPct}%)
            </Box>
          }
        >
          <Button
            inline
            color="transparent"
            onClick={onSetActor}
            style={{ width: '100%' }}
          >
            <Box
              style={{
                height: 10,
                width: '100%',
                border: '1px solid rgba(255,255,255,0.2)',
                borderRadius: 6,
                overflow: 'hidden',
              }}
            >
              <Box
                style={{
                  height: '100%',
                  width: `${actorPct}%`,
                  background: '#d146f5',
                }}
              />
            </Box>
          </Button>
        </LabeledList.Item>

        {showPartnerBar && (
          <LabeledList.Item
            label={partnerLabel || 'Цель'}
            buttons={
              <Box as="span" ml={1} color="label">
                {partnerArousal} / {maxArousal} ({partnerPct}%)
              </Box>
            }
          >
            <Button
              inline
              color="transparent"
              onClick={onSetPartner}
              style={{ width: '100%' }}
            >
              <Box
                style={{
                  height: 10,
                  width: '100%',
                  border: '1px solid rgba(255,255,255,0.2)',
                  borderRadius: 6,
                  overflow: 'hidden',
                }}
              >
                <Box
                  style={{
                    height: '100%',
                    width: `${partnerPct}%`,
                    background: '#f05ee1',
                  }}
                />
              </Box>
            </Button>
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};

const StatusPanel: React.FC<{
  data: SexSessionData;
  actorOrgans: OrgNode[];
  actorName: string;
  onEditOrgan: (id: string, field: 'sensitivity' | 'pain') => void;
}> = ({ data, actorOrgans, actorName, onEditOrgan }) => {
  const links = data.active_links || [];

  const speedName = (v: number) => {
    const idx = Math.max(1, Math.min(data.speed_names.length, v)) - 1;
    return data.speed_names[idx] || '?';
  };

  const forceName = (v: number) => {
    const idx = Math.max(1, Math.min(data.force_names.length, v)) - 1;
    return data.force_names[idx] || '?';
  };

  return (
    <Section title={`Состояние: ${actorName}`} fill scrollable>
      {actorOrgans.map((org) => {
        const affecting = links.filter(
          (l) =>
            l.actor_organ_id === org.id ||
            l.partner_organ_id === org.id,
        );

        // БЕРЁМ ИМЕННО ИЗ ОРГАНА
        const sens = org.sensitivity ?? 0;
        const pain = org.pain ?? 0;

        return (
          <Box key={org.id} mb={1.5}>
            <Stack justify="space-between" align="center">
              <Stack.Item>
                <Box bold>{prettyOrgName(org.name)}</Box>
              </Stack.Item>
              <Stack.Item>
                <Stack align="center">
                  <Stack.Item style={{ marginRight: 8 }}>
                    <Button
                      inline
                      compact
                      color="transparent"
                      onClick={() => onEditOrgan(org.id, 'sensitivity')}
                    >
                      Чувствительность:{' '}
                      <Box as="span" color="good">
                        {sens}
                      </Box>
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Box>
                      Боль:{' '}
                      <Box as="span" color="bad">
                        {pain}
                      </Box>
                    </Box>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>

            {affecting.length ? (
              <Stack vertical mt={0.5}>
                {affecting.map((l) => {
                  const isSource = l.actor_organ_id === org.id;
                  const labelSide = isSource ? 'Источник' : 'Цель';
                  return (
                    <Box key={l.id} ml={1}>
                      <Box as="span" color="label">
                        [{labelSide}]
                      </Box>{' '}
                      {l.action_name || '—'}{' '}
                      <Box as="span" color="label">
                        ({speedName(l.speed)}, {forceName(l.force)})
                      </Box>
                    </Box>
                  );
                })}
              </Stack>
            ) : (
              <Box ml={1} color="label">
                Нет активных воздействий.
              </Box>
            )}
          </Box>
        );
      })}
    </Section>
  );
};

const SensitivityInline: React.FC<{
  sensitivity?: number;
  disabled?: boolean;
  onEdit: () => void;
}> = ({ sensitivity, disabled, onEdit }) => (
  <Button
    inline
    compact
    color="transparent"
    disabled={disabled}
    onClick={onEdit}
  >
    ЧУВСТВИТЕЛЬН.: {disabled ? '—' : sensitivity ?? 0}
  </Button>
);

const ActiveLinksPanel: React.FC<{
  data: SexSessionData;
  actorOrgans: OrgNode[];
  partnerOrgans: OrgNode[];
  onSetSpeed: (id: string, value: number) => void;
  onSetForce: (id: string, value: number) => void;
  onToggleFinished: (id: string) => void;
  onStop: (id: string) => void;
  onEditSensitivity: (id: string) => void;
}> = ({
  data,
  actorOrgans,
  partnerOrgans,
  onSetSpeed,
  onSetForce,
  onToggleFinished,
  onStop,
  onEditSensitivity,
}) => {
  const links = data.active_links || [];
  if (!links.length) return null;

  const getOrg = (id: string, list: OrgNode[]) =>
    list.find((o) => o.id === id);

  const speedNames = data.speed_names || [];
  const forceNames = data.force_names || [];

  const clampIndex = (v: number, names: string[]) => {
    const len = names.length || 1;
    const idx = Math.max(1, Math.min(len, v || 1)) - 1;
    return idx;
  };

  return (
    <Stack vertical>
      {links.map((link) => {
        const actorOrg = getOrg(link.actor_organ_id, actorOrgans);
        const partnerOrg = getOrg(link.partner_organ_id, partnerOrgans);

        const speedIdx = clampIndex(link.speed, speedNames);
        const forceIdx = clampIndex(link.force, forceNames);

        const speedLabel = speedNames[speedIdx] || '?';
        const forceLabel = forceNames[forceIdx] || '?';

        return (
          <Section key={link.id}>
            {/* Верхняя строка: органы + скорость/сила + название действия */}
            <Stack align="center" justify="space-between">
              <Stack.Item shrink>
                <Box bold>
                  {actorOrg ? prettyOrgName(actorOrg.name) : '—'}
                </Box>
              </Stack.Item>

              <Stack.Item>
                <Button
                  inline
                  compact
                  onClick={() => onSetSpeed(link.id, link.speed - 1)}
                >
                  {'<'}
                </Button>{' '}
                <Box
                  as="span"
                  bold
                  style={{
                    color: speedColors[speedIdx % speedColors.length],
                    display: 'inline-block',
                    minWidth: 110,
                    textAlign: 'center',
                  }}
                >
                  {speedLabel}
                </Box>{' '}
                <Button
                  inline
                  compact
                  onClick={() => onSetSpeed(link.id, link.speed + 1)}
                >
                  {'>'}
                </Button>
              </Stack.Item>

              <Stack.Item grow>
                <Box textAlign="center">
                  <Button
                    inline
                    compact
                    color="transparent"
                    selected
                    onClick={() => onStop(link.id)}
                  >
                    {link.action_name || 'ДЕЙСТВИЕ'}
                  </Button>
                </Box>
              </Stack.Item>

              <Stack.Item>
                <Button
                  inline
                  compact
                  onClick={() => onSetForce(link.id, link.force - 1)}
                >
                  {'<'}
                </Button>{' '}
                <Box
                  as="span"
                  bold
                  style={{
                    color: forceColors[forceIdx % forceColors.length],
                    display: 'inline-block',
                    minWidth: 90,
                    textAlign: 'center',
                  }}
                >
                  {forceLabel}
                </Box>{' '}
                <Button
                  inline
                  compact
                  onClick={() => onSetForce(link.id, link.force + 1)}
                >
                  {'>'}
                </Button>
              </Stack.Item>

              <Stack.Item shrink>
                <Box bold>
                  {partnerOrg ? prettyOrgName(partnerOrg.name) : '—'}
                </Box>
              </Stack.Item>
            </Stack>

            {/* Нижняя строка: до завершения / чувствительность / стоп */}
            <Stack
              align="center"
              justify="space-between"
              style={{ marginTop: 4 }}
            >
              <Stack.Item>
                <Button
                  inline
                  compact
                  color="transparent"
                  onClick={() => onToggleFinished(link.id)}
                >
                  {link.do_until_finished
                    ? 'ДО ЗАВЕРШЕНИЯ'
                    : 'ПОКА НЕ ОСТАНОВЛЮСЬ'}
                </Button>
              </Stack.Item>

              <Stack.Item>
                <SensitivityInline
                  sensitivity={link.sensitivity}
                  disabled={!partnerOrg}
                  onEdit={() => onEditSensitivity(link.id)}
                />
              </Stack.Item>

              <Stack.Item>
                <Button
                  inline
                  compact
                  color="transparent"
                  onClick={() => onStop(link.id)}
                >
                  ОСТАНОВИТЬСЯ
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        );
      })}
    </Stack>
  );
};

const ActionsFilter: React.FC<{
  searchText: string;
  onSearchChange: (value: string) => void;
  availableTags: string[];
  activeTags: string[];
  onToggleTag: (tag: string) => void;
}> = ({
  searchText,
  onSearchChange,
  availableTags,
  activeTags,
  onToggleTag,
}) => (
  <Section title="ДОСТУПНЫЕ ДЕЙСТВИЯ">
    <Input
      fluid
      placeholder="Поиск взаимодействия..."
      value={searchText}
      onChange={onSearchChange}
    />
    {!!availableTags.length && (
      <Box mt={1}>
        <Stack wrap>
          {availableTags.map((tag) => (
            <Stack.Item key={tag}>
              <Pill
                selected={activeTags.includes(tag)}
                onClick={() => onToggleTag(tag)}
              >
                {tag}
              </Pill>
            </Stack.Item>
          ))}
        </Stack>
      </Box>
    )}
  </Section>
);

const ActionsList: React.FC<{
  actorSelected?: OrgNode;
  partnerSelected?: OrgNode;
  actions: SexAction[];
  currentAction?: string;
  canPerform: string[];
  onClickAction: (type: string) => void;
}> = ({
  actorSelected,
  partnerSelected,
  actions,
  currentAction,
  canPerform,
  onClickAction,
}) => {
  const leftColumn = actions.filter((_, i) => i % 2 === 0);
  const rightColumn = actions.filter((_, i) => i % 2 === 1);

  return (
    <Section fill scrollable>
      {!actorSelected || !partnerSelected ? (
        <NoticeBox info>
          Выберите по одному органу слева и справа, чтобы увидеть доступные
          действия.
        </NoticeBox>
      ) : (
        <Stack fill>
          <Stack.Item basis="50%">
            <Stack vertical>
              {leftColumn.map((action) => {
                const isCurrent = currentAction === action.type;
                const isAvailable = canPerform.includes(action.type);
                return (
                  <Stack.Item key={action.type}>
                    <Button
                      inline
                      color="transparent"
                      selected={isCurrent}
                      disabled={!isAvailable}
                      onClick={() => onClickAction(action.type)}
                      style={{ justifyContent: 'flex-start', width: '100%' }}
                    >
                      {action.name}
                    </Button>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Stack.Item>
          <Stack.Item basis="50%">
            <Stack vertical>
              {rightColumn.map((action) => {
                const isCurrent = currentAction === action.type;
                const isAvailable = canPerform.includes(action.type);
                return (
                  <Stack.Item key={action.type}>
                    <Button
                      fluid
                      selected={isCurrent}
                      disabled={!isAvailable}
                      onClick={() => onClickAction(action.type)}
                    >
                      {action.name}
                    </Button>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
};

const BottomControls: React.FC<{
  yieldToPartner?: boolean;
  onFlipLeft: () => void;
  onFlipRight: () => void;
  onStopAll: () => void;
  onToggleYield: () => void;
}> = ({ yieldToPartner, onFlipLeft, onFlipRight, onStopAll, onToggleYield }) => (
  <Section>
    <Stack justify="center">
      <Stack.Item style={{ marginInline: 4 }}>
        <Button onClick={onFlipLeft}>ПЕРЕВЕРНУТЬ ВЛЕВО</Button>
      </Stack.Item>
      <Stack.Item style={{ marginInline: 4 }}>
        <Button onClick={onStopAll}>ОСТАНОВИТЬСЯ</Button>
      </Stack.Item>
      <Stack.Item style={{ marginInline: 4 }}>
        <Button selected={!!yieldToPartner} onClick={onToggleYield}>
          ПОДДАТЬСЯ
        </Button>
      </Stack.Item>
      <Stack.Item style={{ marginInline: 4 }}>
        <Button onClick={onFlipRight}>ПЕРЕВЕРНУТЬ ВПРАВО</Button>
      </Stack.Item>
    </Stack>
  </Section>
);

export const EroticRolePlayPanel: React.FC = () => {
  const { act, data } = useBackend<SexSessionData>();

  const partners = data.partners ?? [];
  const actorOrgans = data.status_organs ?? [];
  const partnerOrgans = data.partner_organs ?? [];
  const actions = data.actions ?? [];
  const canPerform = data.can_perform ?? [];
  const availableTags = data.available_tags ?? [];

  const [searchText, setSearchText] = useState('');
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<'status' | 'actions'>('status');

  const toggleTag = (tag: string) => {
    setActiveTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag],
    );
  };

  const actorSelected = useMemo(
    () => actorOrgans.find((o) => o.id === data.selected_actor_organ),
    [actorOrgans, data.selected_actor_organ],
  );
  const partnerSelected = useMemo(
    () => partnerOrgans.find((o) => o.id === data.selected_partner_organ),
    [partnerOrgans, data.selected_partner_organ],
  );

  const currentPartner = useMemo(() => {
    if (!partners.length) return null;
    return (
      partners.find((p) => p.ref === data.current_partner_ref) || partners[0]
    );
  }, [partners, data.current_partner_ref]);

  const filteredActions = useMemo(() => {
    const q = searchText.trim().toLowerCase();
    return actions.filter((a) => {
      if (q && !a.name.toLowerCase().includes(q)) return false;
      if (
        activeTags.length &&
        !(a.tags || []).some((t) => activeTags.includes(t))
      ) {
        return false;
      }
      if (!canPerform.includes(a.type)) return false;
      if (!actorSelected || !partnerSelected) return false;
      return true;
    });
  }, [actions, canPerform, searchText, activeTags, actorSelected, partnerSelected]);

  const onClickActionButton = (actionType: string) => {
    if (data.current_action === actionType) {
      act('stop_action');
    } else {
      act('start_action', { action_type: actionType });
    }
  };

  const setArousal = (target: 'actor' | 'partner') => {
    const current =
      target === 'actor'
        ? data.actor_arousal ?? 0
        : data.partner_arousal ?? 0;
    const raw = window.prompt('Введите возбуждение 0–120', String(current));
    if (raw === null) return;
    const value = Number(raw);
    if (Number.isNaN(value)) return;
    act('set_arousal_value', { target, amount: value });
  };

  const actorArousal = Math.max(0, data.actor_arousal ?? 0);
  const partnerArousal = Math.max(0, data.partner_arousal ?? 0);

  const editTuningForLink = (linkId: string) => {
    const raw = window.prompt('Чувствительность 0–10', '0');
    if (raw === null) return;
    const value = Number(raw);
    if (Number.isNaN(value)) return;
    act('set_link_tuning', { id: linkId, field: 'sensitivity', value });
  };

  const editOrganField = (id: string, field: 'sensitivity' | 'pain') => {
    const title = field === 'sensitivity' ? 'Чувствительность 0–10' : 'Боль 0–10';
    const raw = window.prompt(title, '0');
    if (raw === null) return;
    const value = Number(raw);
    if (Number.isNaN(value)) return;
    act('set_organ_tuning', { id, field, value });
  };

  const showPartnerBar: boolean =
    !!(
      data.show_partner_arousal ??
      (data.current_partner_ref &&
        data.current_partner_ref !== (partners[0]?.ref ?? null))
    );

  return (
    <Window title="Утолить Желания" width={1000} height={720}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <PartnerSelector
              actorName={data.actor_name}
              partners={partners}
              currentRef={data.current_partner_ref}
              onChange={(ref) => act('set_partner', { ref })}
            />
          </Stack.Item>

          <Stack.Item>
            <ArousalBars
              actorName={data.actor_name}
              partnerLabel={currentPartner?.name || 'Цель'}
              actorArousal={actorArousal}
              partnerArousal={partnerArousal}
              showPartnerBar={showPartnerBar}
              onSetActor={() => setArousal('actor')}
              onSetPartner={() => setArousal('partner')}
            />
          </Stack.Item>

          <Stack.Item>
            <Section>
              <Stack justify="center">
                <Stack.Item style={{ marginInline: 4 }}>
                  <Button
                    selected={activeTab === 'status'}
                    onClick={() => setActiveTab('status')}
                  >
                    СТАТУС
                  </Button>
                </Stack.Item>
                <Stack.Item style={{ marginInline: 4 }}>
                  <Button
                    selected={activeTab === 'actions'}
                    onClick={() => setActiveTab('actions')}
                  >
                    ДЕЙСТВИЯ
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {activeTab === 'status' && (
            <Stack.Item grow>
              <StatusPanel
                data={data}
                actorOrgans={actorOrgans}
                actorName={data.actor_name}
                onEditOrgan={editOrganField}
              />
            </Stack.Item>
          )}

          {activeTab === 'actions' && (
            <>
              <Stack.Item>
                <BottomControls
                  yieldToPartner={data.yield_to_partner}
                  onFlipLeft={() => act('flip', { dir: -1 })}
                  onFlipRight={() => act('flip', { dir: 1 })}
                  onStopAll={() => act('stop_all')}
                  onToggleYield={() => act('quick', { op: 'yield' })}
                />
              </Stack.Item>

              <Stack.Item>
                <Section>
                  <Stack fill align="stretch">
                    <Stack.Item basis="18%">
                      <OrganList
                        title={data.actor_name}
                        organs={actorOrgans}
                        selectedId={data.selected_actor_organ}
                        onSelect={(id) =>
                          act('select_organ', { side: 'actor', id })
                        }
                      />
                    </Stack.Item>

                    <Stack.Item grow>
                      <Stack vertical fill>
                        <Stack.Item>
                          <ActionsFilter
                            searchText={searchText}
                            onSearchChange={setSearchText}
                            availableTags={availableTags}
                            activeTags={activeTags}
                            onToggleTag={toggleTag}
                          />
                        </Stack.Item>
                        <Stack.Item grow>
                          <ActionsList
                            actorSelected={actorSelected}
                            partnerSelected={partnerSelected}
                            actions={filteredActions}
                            currentAction={data.current_action}
                            canPerform={canPerform}
                            onClickAction={onClickActionButton}
                          />
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>

                    <Stack.Item basis="18%">
                      <OrganList
                        title={currentPartner?.name || 'Партнёр'}
                        organs={partnerOrgans}
                        selectedId={data.selected_partner_organ}
                        onSelect={(id) =>
                          act('select_organ', { side: 'partner', id })
                        }
                      />
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>

              <Stack.Item>
                <ActiveLinksPanel
                  data={data}
                  actorOrgans={actorOrgans}
                  partnerOrgans={partnerOrgans}
                  onSetSpeed={(id, value) =>
                    act('set_link_speed', { id, value })
                  }
                  onSetForce={(id, value) =>
                    act('set_link_force', { id, value })
                  }
                  onToggleFinished={(id) =>
                    act('toggle_link_finished', { id })
                  }
                  onStop={(id) => act('stop_link', { id })}
                  onEditSensitivity={editTuningForLink}
                />
              </Stack.Item>
            </>
          )}
        </Stack>
        <Divider />
      </Window.Content>
    </Window>
  );
};

export default EroticRolePlayPanel;
