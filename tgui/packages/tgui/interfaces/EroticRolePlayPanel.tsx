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

export type SexSessionData = {
  title: string;
  session_name?: string;

  actor_name: string;

  // партнёры для выпадающего списка
  partners: PartnerEntry[];
  current_partner_ref?: string | null;

  // органы
  actor_organs: OrgNode[];
  partner_organs: OrgNode[];
  selected_actor_organ?: string;
  selected_partner_organ?: string;

  // скорость / сила
  speed: number;
  force: number;
  speed_names: string[];
  force_names: string[];

  // возбуждение
  actor_arousal: number;
  partner_arousal: number;

  frozen?: boolean;
  do_until_finished?: boolean;
  has_knotted_penis?: boolean;
  do_knot_action?: boolean;

  // действия
  actions: SexAction[];
  can_perform: string[];
  available_tags?: string[];
  current_action?: string;

  // настройка органа
  target_sensitivity?: number;
  target_pain?: number;

  // “поддаться”
  yield_to_partner?: boolean;

  // лог “роман”
  romance_log?: string[];
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
            {org.name}
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
}> = ({ actorName, partnerLabel, actorArousal, partnerArousal }) => (
  <Section>
    <LabeledList>
      <LabeledList.Item label={actorName || 'Источник'}>
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
              width: `${actorArousal}%`,
              background: '#d146f5',
            }}
          />
        </Box>
      </LabeledList.Item>
      <LabeledList.Item label={partnerLabel || 'Цель'}>
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
              width: `${partnerArousal}%`,
              background: '#f05ee1',
            }}
          />
        </Box>
      </LabeledList.Item>
    </LabeledList>
  </Section>
);

const OrganTuningControls: React.FC<{
  partnerSelected?: OrgNode;
  sensitivity?: number;
  pain?: number;
  onEdit: (field: 'sensitivity' | 'pain') => void;
}> = ({ partnerSelected, sensitivity, pain, onEdit }) => (
  <>
    <Stack.Item>
      <Button
        inline
        compact
        color="transparent"
        disabled={!partnerSelected}
        onClick={() => onEdit('sensitivity')}
      >
        ЧУВСТВИТЕЛЬН.: {partnerSelected ? sensitivity ?? 0 : '—'}
      </Button>
    </Stack.Item>
    <Stack.Item>
      <Button
        inline
        compact
        color="transparent"
        disabled={!partnerSelected}
        onClick={() => onEdit('pain')}
      >
        БОЛЬ: {partnerSelected ? pain ?? 0 : '—'}
      </Button>
    </Stack.Item>
  </>
);

const ActionControlRow: React.FC<{
  data: SexSessionData;
  actorSelected?: OrgNode;
  partnerSelected?: OrgNode;
  currentActionName?: string;
  onToggleFinished: () => void;
  onChangeSpeed: (delta: number) => void;
  onChangeForce: (delta: number) => void;
  onStopCurrent: () => void;
  onToggleFrozen: () => void;
  onToggleKnot: () => void;
  onEditTuning: (field: 'sensitivity' | 'pain') => void;
}> = ({
  data,
  actorSelected,
  partnerSelected,
  currentActionName,
  onToggleFinished,
  onChangeSpeed,
  onChangeForce,
  onStopCurrent,
  onToggleFrozen,
  onToggleKnot,
  onEditTuning,
}) => (
  <Section>
    <Stack align="center" justify="space-between">
      {/* Режим */}
      <Stack.Item grow>
        <Button
          inline
          compact
          color="transparent"
          onClick={onToggleFinished}
        >
          {data.do_until_finished
            ? 'РЕЖИМ: ДО ЗАВЕРШЕНИЯ'
            : 'РЕЖИМ: ПОКА НЕ ОСТАНОВЛЮСЬ'}
        </Button>
      </Stack.Item>

      {/* Скорость */}
      <Stack.Item shrink>
        <Button inline compact onClick={() => onChangeSpeed(-1)}>
          {'<'}
        </Button>{' '}
        <Box
          as="span"
          bold
          style={{
            color: speedColors[data.speed - 1],
            display: 'inline-block',
            minWidth: 110,
            textAlign: 'center',
          }}
        >
          {data.speed_names[data.speed - 1]}
        </Box>{' '}
        <Button inline compact onClick={() => onChangeSpeed(1)}>
          {'>'}
        </Button>
      </Stack.Item>

      {/* Название действия / стоп */}
      <Stack.Item grow>
        <Box textAlign="center">
          <Button
            inline
            compact
            selected={!!data.current_action}
            disabled={!actorSelected || !partnerSelected}
            onClick={onStopCurrent}
          >
            {currentActionName || 'ДЕЙСТВИЕ НЕ ВЫБРАНО'}
          </Button>
        </Box>
      </Stack.Item>

      {/* Сила */}
      <Stack.Item shrink>
        <Button inline compact onClick={() => onChangeForce(-1)}>
          {'<'}
        </Button>{' '}
        <Box
          as="span"
          bold
          style={{
            color: forceColors[data.force - 1],
            display: 'inline-block',
            minWidth: 90,
            textAlign: 'center',
          }}
        >
          {data.force_names[data.force - 1]}
        </Box>{' '}
        <Button inline compact onClick={() => onChangeForce(1)}>
          {'>'}
        </Button>
      </Stack.Item>

      {/* Чувствительность / боль */}
      <Stack.Item shrink>
        <Stack vertical align="end">
          <OrganTuningControls
            partnerSelected={partnerSelected}
            sensitivity={data.target_sensitivity}
            pain={data.target_pain}
            onEdit={onEditTuning}
          />
        </Stack>
      </Stack.Item>
    </Stack>
    <Box textAlign="center" mt={1}>
      <Button
        inline
        compact
        color="transparent"
        onClick={onToggleFrozen}
      >
        {data.frozen ? 'НЕ ИЗМЕНЯТЬ' : 'ИЗМЕНЯТЬ'}
      </Button>
      {!!data.has_knotted_penis && (
        <>
          {' | '}
          <Button
            inline
            compact
            color="transparent"
            onClick={onToggleKnot}
          >
            <Box
              as="span"
              bold
              style={{
                color: data.do_knot_action ? '#d146f5' : '#eac8de',
              }}
            >
              {data.do_knot_action
                ? 'НЕ ИСПОЛЬЗОВАТЬ УЗЕЛ'
                : 'ИСПОЛЬЗОВАТЬ УЗЕЛ'}
            </Box>
          </Button>
        </>
      )}
    </Box>
  </Section>
);

const ActionsFilter: React.FC<{
  searchText: string;
  onSearchChange: (value: string) => void;
  availableTags?: string[];
  activeTags: string[];
  onToggleTag: (tag: string) => void;
}> = ({ searchText, onSearchChange, availableTags, activeTags, onToggleTag }) => (
  <Section title="ДОСТУПНЫЕ ДЕЙСТВИЯ">
    <Input
      fluid
      placeholder="Поиск взаимодействия..."
      value={searchText}
      onChange={onSearchChange}
    />
    {!!availableTags?.length && (
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
  leftColumn: SexAction[];
  rightColumn: SexAction[];
  currentAction?: string;
  canPerform: string[];
  onClickAction: (type: string) => void;
}> = ({
  actorSelected,
  partnerSelected,
  leftColumn,
  rightColumn,
  currentAction,
  canPerform,
  onClickAction,
}) => (
  <Section fill scrollable>
    {!actorSelected || !partnerSelected ? (
      <NoticeBox info>
        Выберите по одному элементу слева и справа, чтобы увидеть доступные
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

const RomanceLogView: React.FC<{ log?: string[] }> = ({ log }) => (
  <Section fill>
    {log && log.length ? (
      <Stack vertical>
        {log.map((line, idx) => (
          <Stack.Item key={idx}>
            <Box>{line}</Box>
          </Stack.Item>
        ))}
      </Stack>
    ) : (
      <Box italic color="label">
        Здесь пока тихо.
      </Box>
    )}
  </Section>
);

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
        <Button onClick={onFlipRight}>ПЕРЕВЕРНУТЬ ВПРАВО</Button>
      </Stack.Item>
      <Stack.Item style={{ marginInline: 4 }}>
        <Button selected={!!yieldToPartner} onClick={onToggleYield}>
          ПОДДАТЬСЯ
        </Button>
      </Stack.Item>
    </Stack>
  </Section>
);

export const EroticRolePlayPanel: React.FC = () => {
  const { act, data } = useBackend<SexSessionData>();
  const [searchText, setSearchText] = useState('');
  const [activeTags, setActiveTags] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState<'actions' | 'romance'>('actions');

  const toggleTag = (tag: string) => {
    setActiveTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag],
    );
  };

  const actorSelected = useMemo(
    () => data.actor_organs.find((o) => o.id === data.selected_actor_organ),
    [data.actor_organs, data.selected_actor_organ],
  );
  const partnerSelected = useMemo(
    () => data.partner_organs.find((o) => o.id === data.selected_partner_organ),
    [data.partner_organs, data.selected_partner_organ],
  );

  const currentPartner = useMemo(() => {
    if (!data.partners?.length) return null;
    return (
      data.partners.find((p) => p.ref === data.current_partner_ref) ||
      data.partners[0]
    );
  }, [data.partners, data.current_partner_ref]);

  const currentActionObj = useMemo(
    () => data.actions.find((a) => a.type === data.current_action),
    [data.actions, data.current_action],
  );

  const filteredActions = useMemo(() => {
    const q = searchText.trim().toLowerCase();
    return data.actions.filter((a) => {
      if (q && !a.name.toLowerCase().includes(q)) return false;
      if (activeTags.length && !(a.tags || []).some((t) => activeTags.includes(t))) {
        return false;
      }
      if (!data.can_perform.includes(a.type)) return false;
      if (!actorSelected || !partnerSelected) return false;
      return true;
    });
  }, [data.actions, data.can_perform, searchText, activeTags, actorSelected, partnerSelected]);

  const leftColumn = filteredActions.filter((_, i) => i % 2 === 0);
  const rightColumn = filteredActions.filter((_, i) => i % 2 === 1);

  const onClickActionButton = (actionType: string) => {
    if (data.current_action === actionType) {
      act('stop_action');
    } else {
      act('start_action', { action_type: actionType });
    }
  };

  const editTuning = (field: 'sensitivity' | 'pain') => {
    if (!data.selected_partner_organ) return;
    const current =
      field === 'sensitivity'
        ? data.target_sensitivity ?? 0
        : data.target_pain ?? 0;

    const raw = window.prompt('Введите значение от 0 до 2', String(current));
    if (raw === null) return;
    const value = Number(raw);
    if (Number.isNaN(value)) return;

    act('set_organ_tuning', {
      side: 'partner',
      id: data.selected_partner_organ,
      field,
      value,
    });
  };

  const actorArousalWidth = Math.max(0, Math.min(100, data.actor_arousal ?? 0));
  const partnerArousalWidth = Math.max(
    0,
    Math.min(100, data.partner_arousal ?? 0),
  );

  return (
    <Window title="Утолить Желания" width={1000} height={720}>
      <Window.Content scrollable>
        <Stack fill>
          {/* Левая колонка – органы актёра */}
          <Stack.Item basis="22%">
            <OrganList
              title={data.actor_name}
              organs={data.actor_organs}
              selectedId={data.selected_actor_organ}
              onSelect={(id) => act('select_organ', { side: 'actor', id })}
            />
          </Stack.Item>

          {/* Центр */}
          <Stack.Item grow>
            <Stack vertical fill>
              {/* Выбор партнёра */}
              <Stack.Item>
                <PartnerSelector
                  actorName={data.actor_name}
                  partners={data.partners}
                  currentRef={data.current_partner_ref}
                  onChange={(ref) => act('set_partner', { ref })}
                />
              </Stack.Item>

              {/* Две полосы возбуждения */}
              <Stack.Item>
                <ArousalBars
                  actorName={data.actor_name}
                  partnerLabel={currentPartner?.name || 'Цель'}
                  actorArousal={actorArousalWidth}
                  partnerArousal={partnerArousalWidth}
                />
              </Stack.Item>

              {/* Строка управления действием */}
              <Stack.Item>
                <ActionControlRow
                  data={data}
                  actorSelected={actorSelected}
                  partnerSelected={partnerSelected}
                  currentActionName={currentActionObj?.name}
                  onToggleFinished={() => act('toggle_finished')}
                  onChangeSpeed={(delta) =>
                    act('set_speed', {
                      value: Math.max(1, Math.min(4, data.speed + delta)),
                    })
                  }
                  onChangeForce={(delta) =>
                    act('set_force', {
                      value: Math.max(1, Math.min(4, data.force + delta)),
                    })
                  }
                  onStopCurrent={() => {
                    if (data.current_action) {
                      act('stop_action');
                    }
                  }}
                  onToggleFrozen={() => act('freeze_arousal')}
                  onToggleKnot={() => act('toggle_knot')}
                  onEditTuning={editTuning}
                />
              </Stack.Item>

              {/* Вкладки */}
              <Stack.Item>
                <Section>
                  <Stack justify="center">
                    <Stack.Item style={{ marginInline: 4 }}>
                      <Button
                        selected={activeTab === 'actions'}
                        onClick={() => setActiveTab('actions')}
                      >
                        ДЕЙСТВИЯ
                      </Button>
                    </Stack.Item>
                    <Stack.Item style={{ marginInline: 4 }}>
                      <Button
                        selected={activeTab === 'romance'}
                        onClick={() => setActiveTab('romance')}
                      >
                        РОМАН
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>

              {/* Контент вкладок */}
              {activeTab === 'actions' ? (
                <>
                  <Stack.Item>
                    <ActionsFilter
                      searchText={searchText}
                      onSearchChange={setSearchText}
                      availableTags={data.available_tags}
                      activeTags={activeTags}
                      onToggleTag={toggleTag}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <ActionsList
                      actorSelected={actorSelected}
                      partnerSelected={partnerSelected}
                      leftColumn={leftColumn}
                      rightColumn={rightColumn}
                      currentAction={data.current_action}
                      canPerform={data.can_perform}
                      onClickAction={onClickActionButton}
                    />
                  </Stack.Item>
                </>
              ) : (
                <Stack.Item grow>
                  <RomanceLogView log={data.romance_log} />
                </Stack.Item>
              )}

              {/* Нижняя панель */}
              <Stack.Item>
                <BottomControls
                  yieldToPartner={data.yield_to_partner}
                  onFlipLeft={() => act('flip', { dir: -1 })}
                  onFlipRight={() => act('flip', { dir: 1 })}
                  onStopAll={() => act('stop_all')}
                  onToggleYield={() => act('quick', { op: 'yield' })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>

          {/* Правая колонка – органы партнёра */}
          <Stack.Item basis="22%">
            <OrganList
              title={currentPartner?.name || 'Партнёр'}
              organs={data.partner_organs}
              selectedId={data.selected_partner_organ}
              onSelect={(id) => act('select_organ', { side: 'partner', id })}
            />
          </Stack.Item>
        </Stack>
        <Divider />
      </Window.Content>
    </Window>
  );
};

export default EroticRolePlayPanel;
