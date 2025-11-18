import { type ReactNode, useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, Divider, Input, LabeledList, NoticeBox, Section, Stack } from 'tgui-core/components';

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

export type EroticRolePlayPanelData = {
  title: string;
  session_name?: string;
  actor_name: string;
  partner_name: string;
  actor_organs: OrgNode[];
  partner_organs: OrgNode[];
  selected_actor_organ?: string;
  selected_partner_organ?: string;
  speed: number;
  force: number;
  speed_names: string[];
  force_names: string[];
  arousal: number;
  frozen?: boolean;
  do_until_finished?: boolean;
  has_knotted_penis?: boolean;
  do_knot_action?: boolean;
  actions: SexAction[];
  can_perform: string[];
  available_tags?: string[];
  current_action?: string;
};

const Pill: React.FC<{ selected?: boolean; disabled?: boolean; onClick?: () => void; children?: ReactNode }>
  = ({ selected, disabled, onClick, children }) => (
  <Button inline compact disabled={disabled} selected={!!selected} style={{ borderRadius: 9999, padding: '2px 10px', margin: 2 }} onClick={onClick}>
    {children}
  </Button>
);

const speedColors = ['#eac8de', '#e9a8d1', '#f05ee1', '#d146f5'];
const forceColors = ['#eac8de', '#e9a8d1', '#f05ee1', '#d146f5'];

export const EroticRolePlayPanel: React.FC = () => {
  const { act, data } = useBackend<EroticRolePlayPanelData>();
  const [searchText, setSearchText] = useState('');
  const [activeTags, setActiveTags] = useState<string[]>([]);

  const toggleTag = (tag: string) => {
    setActiveTags((prev) => (prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]));
  };

  const actorSelected = useMemo(() => data.actor_organs.find((o) => o.id === data.selected_actor_organ), [data.actor_organs, data.selected_actor_organ]);
  const partnerSelected = useMemo(() => data.partner_organs.find((o) => o.id === data.selected_partner_organ), [data.partner_organs, data.selected_partner_organ]);

  const filteredActions = useMemo(() => {
    const q = searchText.trim().toLowerCase();
    return data.actions.filter((a) => {
      if (q && !a.name.toLowerCase().includes(q)) return false;
      if (activeTags.length && !(a.tags || []).some((t) => activeTags.includes(t))) return false;
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

  return (
    <Window title="Утолить Желания" width={1000} height={720}>
      <Window.Content scrollable>
        <Stack fill>
          <Stack.Item basis="22%">
            <Section title={data.actor_name} fill>
              <Stack vertical>
                {data.actor_organs.map((org) => (
                  <Stack.Item key={org.id}>
                    <Button fluid selected={data.selected_actor_organ === org.id} disabled={!!org.busy} onClick={() => act('select_organ', { side: 'actor', id: org.id })}>
                      {org.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Stack vertical fill>
              <Stack.Item>
                <Box textAlign="center" bold fontSize="1.1em">КТО С КЕМ</Box>
                {data.session_name && data.session_name !== 'Private Session' && (
                  <Box textAlign="center" color="label" fontSize="0.9em">{data.session_name}</Box>
                )}
              </Stack.Item>

              <Stack.Item>
                <Section>
                  <LabeledList>
                    <LabeledList.Item label="Источник">
                      <Box bold>{actorSelected ? actorSelected.name : '—'}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Цель">
                      <Box bold>{partnerSelected ? partnerSelected.name : '—'}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Скорость">
                      <Button inline compact onClick={() => act('set_speed', { value: Math.max(1, data.speed - 1) })}>&lt;</Button>{' '}
                      <Box as="span" bold style={{ color: speedColors[data.speed - 1], display: 'inline-block', minWidth: 110, textAlign: 'center' }}>{data.speed_names[data.speed - 1]}</Box>{' '}
                      <Button inline compact onClick={() => act('set_speed', { value: Math.min(4, data.speed + 1) })}>&gt;</Button>
                    </LabeledList.Item>
                    <LabeledList.Item label="Сила">
                      <Button inline compact onClick={() => act('set_force', { value: Math.max(1, data.force - 1) })}>&lt;</Button>{' '}
                      <Box as="span" bold style={{ color: forceColors[data.force - 1], display: 'inline-block', minWidth: 90, textAlign: 'center' }}>{data.force_names[data.force - 1]}</Box>{' '}
                      <Button inline compact onClick={() => act('set_force', { value: Math.min(4, data.force + 1) })}>&gt;</Button>
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section>
                  <Stack justify="center" align="center">
                    <Stack.Item>
                      <Box bold>ВОЗБУЖДЕНИЕ</Box>
                      <Box style={{ height: 14, width: 320, border: '1px solid rgba(255,255,255,0.2)', borderRadius: 6, overflow: 'hidden' }}>
                        <Box style={{ height: '100%', width: `${Math.max(0, Math.min(100, data.arousal))}%`, background: '#d146f5' }} />
                      </Box>
                    </Stack.Item>
                  </Stack>
                  <Box textAlign="center" mt={1}>
                    <Button inline compact color="transparent" onClick={() => act('toggle_finished')}>
                      {data.do_until_finished ? 'ПОКА НЕ ЗАВЕРШИТСЯ' : 'ПОКА НЕ ОСТАНОВЛЮСЬ'}
                    </Button>{' | '}
                    <Button inline compact color="transparent" onClick={() => act('freeze_arousal')}>
                      {data.frozen ? 'НЕ ИЗМЕНЯТЬ' : 'ИЗМЕНЯТЬ'}
                    </Button>{' | '}
                    <Button inline compact color="transparent" disabled={!data.current_action} onClick={() => act('stop_action')}>
                      ОСТАНОВИТЬСЯ
                    </Button>
                    {!!data.has_knotted_penis && (
                      <>
                        {' | '}
                        <Button inline compact color="transparent" onClick={() => act('toggle_knot')}>
                          <Box as="span" bold style={{ color: data.do_knot_action ? '#d146f5' : '#eac8de' }}>
                            {data.do_knot_action ? 'НЕ ИСПОЛЬЗОВАТЬ УЗЕЛ' : 'ИСПОЛЬЗОВАТЬ УЗЕЛ'}
                          </Box>
                        </Button>
                      </>
                    )}
                  </Box>
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section title="ДОСТУПНЫЕ ДЕЙСТВИЯ">
                  <Input fluid placeholder="Поиск взаимодействия..." value={searchText} onChange={setSearchText} />
                  {!!data.available_tags?.length && (
                    <Box mt={1}>
                      <Stack wrap>
                        {data.available_tags.map((tag) => (
                          <Stack.Item key={tag}>
                            <Pill selected={activeTags.includes(tag)} onClick={() => toggleTag(tag)}>{tag}</Pill>
                          </Stack.Item>
                        ))}
                      </Stack>
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item grow>
                <Section fill scrollable>
                  {!actorSelected || !partnerSelected ? (
                    <NoticeBox info>Выберите по одному элементу слева и справа, чтобы увидеть доступные действия.</NoticeBox>
                  ) : (
                    <Stack fill>
                      <Stack.Item basis="50%">
                        <Stack vertical>
                          {leftColumn.map((action) => {
                            const isCurrent = data.current_action === action.type;
                            const isAvailable = data.can_perform.includes(action.type);
                            return (
                              <Stack.Item key={action.type}>
                                <Button fluid selected={isCurrent} disabled={!isAvailable} onClick={() => onClickActionButton(action.type)}>
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
                            const isCurrent = data.current_action === action.type;
                            const isAvailable = data.can_perform.includes(action.type);
                            return (
                              <Stack.Item key={action.type}>
                                <Button fluid selected={isCurrent} disabled={!isAvailable} onClick={() => onClickActionButton(action.type)}>
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
              </Stack.Item>

              <Stack.Item>
                <Section>
                  <Stack justify="center">
                    <Stack.Item style={{ marginInline: 4 }}>
                      <Button onClick={() => act('quick', { op: 'increase' })}>УСИЛИТЬ</Button>
                    </Stack.Item>
                    <Stack.Item style={{ marginInline: 4 }}>
                      <Button onClick={() => act('stop_action')}>ОСТАНОВИТЬСЯ</Button>
                    </Stack.Item>
                    <Stack.Item style={{ marginInline: 4 }}>
                      <Button onClick={() => act('quick', { op: 'yield' })}>ПОДДАТЬСЯ / ПОВЕРНУТЬСЯ</Button>
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item basis="22%">
            <Section title={data.partner_name} fill>
              <Stack vertical>
                {data.partner_organs.map((org) => (
                  <Stack.Item key={org.id}>
                    <Button fluid selected={data.selected_partner_organ === org.id} disabled={!!org.busy} onClick={() => act('select_organ', { side: 'partner', id: org.id })}>
                      {org.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
        <Divider />
      </Window.Content>
    </Window>
  );
};

export default EroticRolePlayPanel;
