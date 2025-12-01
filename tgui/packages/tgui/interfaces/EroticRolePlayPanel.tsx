import { type CSSProperties, type ReactNode, useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Divider,
  Input,
  Modal,
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
  fullness?: number;
  erect?: number;
  manual?: boolean;
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

  actor_organs?: OrgNode[];
  partner_organs?: OrgNode[];
  status_organs?: OrgNode[];
  selected_actor_organ?: string;
  selected_partner_organ?: string;

  speed: number;
  force: number;
  speed_names: string[];
  force_names: string[];

  actor_arousal?: number;
  partner_arousal?: number;
  partner_arousal_hidden?: boolean;

  frozen?: boolean;
  do_until_finished?: boolean;
  do_knot_action?: boolean;
  has_knotted_penis?: boolean;
  can_knot_now?: boolean;
  yield_to_partner?: boolean;

  actions?: SexAction[];
  can_perform?: string[];
  available_tags?: string[];
  organ_filtered?: string[];

  current_action?: string;
  current_actions?: string[];

  active_links?: ActiveLink[];
};

const fmt2 = (value?: number) =>
  value === undefined || value === null
    ? '0'
    : Number(value).toFixed(2);

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

const OrganList: React.FC<{
  title: string;
  organs: OrgNode[];
  selectedId?: string;
  onSelect: (id: string) => void;
}> = ({ title, organs, selectedId, onSelect }) => (
  <Section title={title} fill>
    <Stack vertical>
      {organs.map((org) => {
        const isSelected = selectedId === org.id;
        const isBusy = !!org.busy;
        const baseColor = isBusy ? '#a05080' : '#c080ff';

        const style: CSSProperties = {
          border: isSelected
            ? '2px solid rgba(255, 180, 255, 0.9)'
            : '1px solid rgba(255,255,255,0.2)',
          boxShadow: isSelected
            ? '0 0 8px rgba(255, 150, 255, 0.9)'
            : undefined,
          background: isSelected
            ? 'rgba(255, 150, 255, 0.18)'
            : 'rgba(255,255,255,0.05)',
          color: baseColor,
          textAlign: 'center',
          justifyContent: 'center',
        };

        return (
          <Stack.Item key={org.id}>
            <Button
              fluid
              selected={isSelected}
              disabled={isBusy}
              style={style}
              onClick={() => onSelect(org.id)}
            >
              <Box as="span">
                {org.name}
                {isBusy ? (
                  <Box as="span" ml={1} color="bad">
                    ●
                  </Box>
                ) : null}
              </Box>
            </Button>
          </Stack.Item>
        );
      })}
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

const BarRow: React.FC<{
  label: string;
  valuePercent: number;
  color: string;
  clickable?: boolean;
  onClick?: () => void;
}> = ({ label, valuePercent, color, clickable, onClick }) => {
  const content = (
    <Box
      style={{
        position: 'relative',
        height: 22,
        width: '100%',
        border: '1px solid rgba(255,255,255,0.35)',
        borderRadius: 6,
        overflow: 'hidden',
      }}
    >
      <Box
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          height: '100%',
          width: `${valuePercent}%`,
          background: color,
          transition: 'width 0.2s',
        }}
      />
      <Box
        style={{
          position: 'relative',
          zIndex: 1,
          height: '100%',
          width: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 6px',
          fontSize: 11,
          color: '#fff',
          textShadow: '0 0 3px #000',
        }}
      >
        <span>{label}</span>
        <span>
          {Math.round(valuePercent)} / 100 ({Math.round(valuePercent)}%)
        </span>
      </Box>
    </Box>
  );

  if (clickable && onClick) {
    return (
      <Button
        inline
        color="transparent"
        onClick={onClick}
        style={{ width: '100%', padding: 0 }}
      >
        {content}
      </Button>
    );
  }

  return content;
};

const ArousalBars: React.FC<{
  actorName: string;
  partnerLabel: string;
  actorArousal: number;
  partnerArousal: number;
  showPartnerBar: boolean;
  onSetActor: () => void;
}> = ({
  actorName,
  partnerLabel,
  actorArousal,
  partnerArousal,
  showPartnerBar,
  onSetActor,
}) => (
  <Section>
    <Stack vertical>
      <Stack.Item>
        <BarRow
          label={actorName || 'Я'}
          valuePercent={actorArousal}
          color="#d146f5"
          clickable
          onClick={onSetActor}
        />
      </Stack.Item>
      {showPartnerBar && (
        <Stack.Item mt={0.5}>
          <BarRow
            label={partnerLabel || 'Партнёр'}
            valuePercent={partnerArousal}
            color="#f05ee1"
          />
        </Stack.Item>
      )}
    </Stack>
  </Section>
);

// helper: вычисляем текущий режим эрекции по данным органа
const getErectModeForOrg = (org: OrgNode | undefined): 'auto' | 'none' | 'partial' | 'hard' => {
  if (!org) return 'auto';
  if (!org.manual) return 'auto';
  const e = org.erect ?? 0;
  if (e >= 2) return 'hard';
  if (e === 1) return 'partial';
  return 'none';
};

const StatusPanel: React.FC<{
  data: SexSessionData;
  actorOrgans: OrgNode[];
  actorName: string;
  partnerLabel?: string;
  editable?: boolean;
  onEditOrgan: (id: string, field: 'sensitivity' | 'pain') => void;
  onSetErectState?: (id: string, state: 'auto' | 'none' | 'partial' | 'hard') => void;
  // 🔥 НОВОЕ: в каком режиме показываем — что делает актёр или что принимает цель
  viewAs?: 'actor' | 'target';
}> = ({
  data,
  actorOrgans,
  actorName,
  partnerLabel,
  editable,
  onEditOrgan,
  onSetErectState,
  viewAs = 'actor',
}) => {
  const links = data.active_links || [];
  const canEdit = editable !== false;

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
        // 🔥 КЛЮЧЕВОЕ МЕСТО
        // viewAs = 'actor'  → показываем только то, что ИСХОДИТ от этих органов
        // viewAs = 'target' → только то, что НАПРАВЛЕНО в эти органы
        const affecting = links.filter((l) => {
          if (viewAs === 'actor') {
            return l.actor_organ_id === org.id;
          }
          // режим жертвы
          return l.partner_organ_id === org.id;
        });

        const sens = (org as any).sensitivity ?? 0;
        const pain = (org as any).pain ?? 0;
        const fullness = (org as any).fullness ?? 0;

        const isPenis = org.id === 'genital_p';
        const erectMode = isPenis ? getErectModeForOrg(org) : 'auto';

        return (
          <Box key={org.id} mb={1.5}>
            <Stack justify="space-between" align="center">
              <Stack.Item>
                <Box bold>
                  {org ? org.name : '—'}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Stack align="center">
                  <Stack.Item style={{ marginRight: 8 }}>
                    <Button
                      inline
                      compact
                      color="transparent"
                      disabled={!canEdit}
                      onClick={
                        canEdit
                          ? () => onEditOrgan(org.id, 'sensitivity')
                          : undefined
                      }
                    >
                      Чувствительность:{' '}
                      <Box as="span" color="good">
                        {fmt2(sens)}
                      </Box>
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="bad">
                      Боль: {fmt2(pain)}
                    </Box>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>

            {isPenis && onSetErectState && (
              <Box mt={0.25} ml={1}>
                <Box as="div" style={{ fontSize: 11 }} color="label">
                  Возбуждение:
                </Box>
                <Stack wrap align="center">
                  <Stack.Item>
                    <Pill
                      selected={erectMode === 'auto'}
                      onClick={() => onSetErectState(org.id, 'auto')}
                    >
                      АВТО
                    </Pill>
                  </Stack.Item>
                  <Stack.Item>
                    <Pill
                      selected={erectMode === 'none'}
                      onClick={() => onSetErectState(org.id, 'none')}
                    >
                      МЯГКИЙ
                    </Pill>
                  </Stack.Item>
                  <Stack.Item>
                    <Pill
                      selected={erectMode === 'partial'}
                      onClick={() => onSetErectState(org.id, 'partial')}
                    >
                      ПРИПОДНЯТ
                    </Pill>
                  </Stack.Item>
                  <Stack.Item>
                    <Pill
                      selected={erectMode === 'hard'}
                      onClick={() => onSetErectState(org.id, 'hard')}
                    >
                      ВСТАЛО
                    </Pill>
                  </Stack.Item>
                </Stack>
              </Box>
            )}

            {fullness > 0 && (
              <Box
                mt={0.25}
                textAlign="right"
                style={{ fontSize: 10 }}
                color="label"
              >
                Заполненность: {Math.round(fullness)}%
              </Box>
            )}

            {affecting.length ? (
              <Stack vertical mt={0.5}>
                {affecting.map((l) => {
                  // для режима жертвы всё, что здесь есть — уже "что со мной делают"
                  const whoLabel =
                    viewAs === 'actor'
                      ? (actorName || 'Вы')
                      : (partnerLabel || 'Партнёр');

                  return (
                    <Box key={l.id} ml={1}>
                      <Box as="span" color="label">
                        {whoLabel}:{' '}
                      </Box>
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
    ЧУВСТВИТЕЛЬН.: {disabled ? '—' : fmt2(sensitivity) ?? 0}
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
  hasKnottedPenis?: boolean;
  canKnotNow?: boolean;
  doKnotAction?: boolean;
  onToggleKnot?: () => void;
}> = ({
  data,
  actorOrgans,
  partnerOrgans,
  onSetSpeed,
  onSetForce,
  onToggleFinished,
  onStop,
  onEditSensitivity,
  hasKnottedPenis,
  canKnotNow,
  doKnotAction,
  onToggleKnot,
}) => {
  const links = data.active_links || [];
  if (!links.length) return null;

  const getOrg = (id: string, list: OrgNode[]) =>
    list.find((o) => o.id === id);

  return (
    <Stack vertical>
      {hasKnottedPenis && canKnotNow && onToggleKnot && (
        <Box mb={0.5} textAlign="center">
          <Button
            inline
            compact
            selected={!!doKnotAction}
            onClick={onToggleKnot}
          >
            {doKnotAction ? 'ДО УЗЛА' : 'БЕЗ УЗЛА'}
          </Button>
        </Box>
      )}

      {links.map((link) => {
        const actorOrg = getOrg(link.actor_organ_id, actorOrgans);
        const partnerOrg = getOrg(link.partner_organ_id, partnerOrgans);
        const speedIdx = Math.max(1, Math.min(4, link.speed)) - 1;
        const forceIdx = Math.max(1, Math.min(4, link.force)) - 1;

        return (
          <Section key={link.id}>
            <Stack align="center" justify="space-between">
              <Stack.Item shrink>
                <Box bold>
                  {actorOrg ? actorOrg.name : '—'}
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
                    color: speedColors[speedIdx],
                    display: 'inline-block',
                    minWidth: 110,
                    textAlign: 'center',
                  }}
                >
                  {data.speed_names[speedIdx]}
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
                    color: forceColors[forceIdx],
                    display: 'inline-block',
                    minWidth: 90,
                    textAlign: 'center',
                  }}
                >
                  {data.force_names[forceIdx]}
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
                  {partnerOrg ? partnerOrg.name : '—'}
                </Box>
              </Stack.Item>
            </Stack>
            <Box mt={0.5} textAlign="center">
              <Stack justify="center" align="center">
                <Stack.Item style={{ marginInline: 12 }}>
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

                <Stack.Item style={{ marginInline: 12 }}>
                  <SensitivityInline
                    sensitivity={link.sensitivity}
                    disabled={!partnerOrg}
                    onEdit={() => onEditSensitivity(link.id)}
                  />
                </Stack.Item>

                <Stack.Item style={{ marginInline: 12 }}>
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
            </Box>
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
      onChange={(value) => onSearchChange(value)}
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
  currentActionTypes?: string[];
  canPerform: string[];
  onClickAction: (type: string) => void;
}> = ({
  actorSelected,
  partnerSelected,
  actions,
  currentActionTypes,
  canPerform,
  onClickAction,
}) => {
  const leftColumn = actions.filter((_, i) => i % 2 === 0);
  const rightColumn = actions.filter((_, i) => i % 2 === 1);
  const activeSet = new Set(currentActionTypes ?? []);

  const renderButton = (action: SexAction) => {
    const isCurrent = activeSet.has(action.type);
    const isAvailable = canPerform.includes(action.type);

    const style: CSSProperties = {
      justifyContent: 'center',
      width: '100%',
      background: isCurrent
        ? 'rgba(255, 140, 255, 0.23)'
        : isAvailable
          ? 'rgba(255, 160, 255, 0.08)'
          : 'rgba(255,255,255,0.02)',
      boxShadow: isCurrent
        ? '0 0 8px rgba(255, 140, 255, 0.9)'
        : undefined,
      color: !isAvailable
        ? '#777'
        : isCurrent
          ? '#ffe6ff'
          : '#f5b3ff',
      textAlign: 'center',
    };

    return (
      <Button
        key={action.type}
        inline
        color="transparent"
        selected={isCurrent}
        disabled={!isAvailable}
        onClick={() => onClickAction(action.type)}
        style={style}
      >
        {action.name}
      </Button>
    );
  };

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
              {leftColumn.map((action) => (
                <Stack.Item key={action.type}>{renderButton(action)}</Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
          <Stack.Item basis="50%">
            <Stack vertical>
              {rightColumn.map((action) => (
                <Stack.Item key={action.type}>{renderButton(action)}</Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
        </Stack>
      )}
    </Section>
  );
};

const BottomControls: React.FC<{
  yieldToPartner?: boolean;
  frozen?: boolean;
  onFlipPose: () => void;
  onStopAll: () => void;
  onToggleYield: () => void;
  onToggleFreeze: () => void;
}> = ({ yieldToPartner, frozen, onFlipPose, onStopAll, onToggleYield, onToggleFreeze }) => (
  <Section>
    <Stack justify="center">
      <Stack.Item style={{ marginInline: 4 }}>
        <Button onClick={onFlipPose}>ПЕРЕВЕРНУТЬСЯ</Button>
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
        <Button selected={!!frozen} onClick={onToggleFreeze}>
          {frozen ? 'НЕ ВОЗБУЖДАТЬСЯ (ВКЛ)' : 'НЕ ВОЗБУЖДАТЬСЯ'}
        </Button>
      </Stack.Item>
    </Stack>
  </Section>
);

type EditContext =
  | { kind: 'arousal_actor' }
  | { kind: 'link_sens'; id: string }
  | { kind: 'organ'; id: string; field: 'sensitivity' | 'pain' };

export const EroticRolePlayPanel: React.FC = () => {
  const { act, data } = useBackend<SexSessionData>();

  const partners = data.partners ?? [];
  const actorOrgansBase = data.actor_organs ?? [];
  const partnerOrgans = data.partner_organs ?? [];
  const statusOrgans = data.status_organs ?? [];
  const actions = data.actions ?? [];
  const canPerform = data.can_perform ?? [];
  const availableTags = data.available_tags ?? [];
  const organFilteredTypes = data.organ_filtered ?? [];

  const [searchText, setSearchText] = useState('');
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<'status' | 'actions'>('actions');

  const [editContext, setEditContext] = useState<EditContext | null>(null);
  const [editTitle, setEditTitle] = useState('');
  const [editValue, setEditValue] = useState('');

  const toggleTag = (tag: string) => {
    setActiveTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag],
    );
  };

  const actorSelected = useMemo(
    () => actorOrgansBase.find((o) => o.id === data.selected_actor_organ),
    [actorOrgansBase, data.selected_actor_organ],
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

      if (
        organFilteredTypes.length &&
        !organFilteredTypes.includes(a.type)
      ) {
        return false;
      }

      if (!actorSelected || !partnerSelected) return false;

      return true;
    });
  }, [
    actions,
    searchText,
    activeTags,
    organFilteredTypes,
    actorSelected,
    partnerSelected,
  ]);

  const onClickActionButton = (actionType: string) => {
    act('start_action', { action_type: actionType });
  };

  const actorArousalWidth = Math.max(
    0,
    Math.min(100, data.actor_arousal ?? 0),
  );
  const partnerArousalWidth = Math.max(
    0,
    Math.min(100, data.partner_arousal ?? 0),
  );

  const showPartnerBar = !!(
    typeof data.partner_arousal === 'number' &&
    !data.partner_arousal_hidden
  );

  const openNumericModal = (
    ctx: EditContext,
    title: string,
    initial: number,
  ) => {
    setEditContext(ctx);
    setEditTitle(title);
    setEditValue(String(Math.round(initial)));
  };

  const handleNumericConfirm = () => {
    if (!editContext) return;
    const num = Number(editValue);
    if (Number.isNaN(num)) {
      setEditContext(null);
      return;
    }

    switch (editContext.kind) {
      case 'arousal_actor':
        act('set_arousal_value', { target: 'actor', amount: num });
        break;

      case 'link_sens':
        act('set_link_tuning', {
          id: editContext.id,
          field: 'sensitivity',
          value: num,
        });
        break;

      case 'organ':
        act('set_organ_tuning', {
          id: editContext.id,
          field: editContext.field,
          value: num,
        });
        break;
    }

    setEditContext(null);
  };

  const handleNumericCancel = () => {
    setEditContext(null);
  };

  const startEditArousalActor = () => {
    openNumericModal(
      { kind: 'arousal_actor' },
      'Возбуждение 0–100',
      data.actor_arousal ?? 0,
    );
  };

  const editTuningForLink = (linkId: string) => {
    const link = (data.active_links || []).find((l) => l.id === linkId);
    openNumericModal(
      { kind: 'link_sens', id: linkId },
      'Чувствительность 0–2',
      link?.sensitivity ?? 0,
    );
  };

  const editOrganField = (id: string, field: 'sensitivity' | 'pain') => {
    const org = statusOrgans.find((o) => o.id === id);
    const current =
      field === 'sensitivity' ? org?.sensitivity ?? 0 : org?.pain ?? 0;
    const title =
      field === 'sensitivity' ? 'Чувствительность 0–2' : 'Боль 0–2';

    openNumericModal({ kind: 'organ', id, field }, title, current);
  };

  return (
    <Window title="Утолить Желания" width={680} height={900}>
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
              partnerLabel={currentPartner?.name || 'Партнёр'}
              actorArousal={actorArousalWidth}
              partnerArousal={partnerArousalWidth}
              showPartnerBar={showPartnerBar}
              onSetActor={startEditArousalActor}
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
                actorOrgans={statusOrgans}
                actorName={data.actor_name}
                partnerLabel={currentPartner?.name}
                editable
                onEditOrgan={editOrganField}
                onSetErectState={(id, state) =>
                  act('toggle_erect', { id, state })
                }
              />
            </Stack.Item>
          )}

          {activeTab === 'actions' && (
            <>
              <Stack.Item>
                <BottomControls
                  yieldToPartner={data.yield_to_partner}
                  frozen={data.frozen}
                  onFlipPose={() => act('flip', { dir: 1 })}
                  onStopAll={() => act('stop_all')}
                  onToggleYield={() => act('quick', { op: 'yield' })}
                  onToggleFreeze={() => act('freeze_arousal')}
                />
              </Stack.Item>

              <Stack.Item>
                <Section>
                  <Stack fill align="stretch">
                    <Stack.Item basis="18%">
                      <OrganList
                        title={data.actor_name}
                        organs={actorOrgansBase}
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
                            currentActionTypes={data.current_actions ?? []}
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
                  actorOrgans={actorOrgansBase}
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
                  hasKnottedPenis={data.has_knotted_penis}
                  canKnotNow={data.can_knot_now}
                  doKnotAction={data.do_knot_action}
                  onToggleKnot={() => act('toggle_knot')}
                />
              </Stack.Item>
            </>
          )}
        </Stack>
        <Divider />
      </Window.Content>

      {editContext && (
        <Modal>
          <Section title={editTitle}>
            <Input
              autoFocus
              value={editValue}
              onChange={(value) => setEditValue(value)}
            />
            <Box mt={1} textAlign="right">
              <Button onClick={handleNumericCancel}>Отмена</Button>{' '}
              <Button onClick={handleNumericConfirm}>OK</Button>
            </Box>
          </Section>
        </Modal>
      )}
    </Window>
  );
};

export default EroticRolePlayPanel;
