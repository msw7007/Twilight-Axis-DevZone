
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

type TabData = { id: string; name: string };
type RegionData = { id: string; name: string };
type RegionOption = { id: string; name: string };

type CulinaryEntry = {
  name: string;
  quality?: string;
  icon?: string;
  path?: string;
};

type CulinaryPanel = {
  fav_food: CulinaryEntry;
  fav_drink: CulinaryEntry;
  hated_food: CulinaryEntry;
  hated_drink: CulinaryEntry;
  picker_mode?: string;
  picker_target?: string;
  picker_target_label?: string;
  food_options: CulinaryEntry[];
  drink_options: CulinaryEntry[];
};

type FamiliarPanel = {
  name?: string;
  pronouns?: string;
  headshot?: string;
  flavortext?: string;
  ooc_notes?: string;
  ooc_extra_link?: string;
  specie_name?: string;
  lore_blurb?: string;
  in_queue?: boolean;
};

type ViceEntry = {
  index: number;
  name: string;
  desc?: string;
};

type VicePanel = {
  items: ViceEntry[];
  can_add?: boolean;
};

type VirtueChoiceEntry = {
  index: number;
  name: string;
  tooltip?: string;
};

type VirtuePanel = {
  name?: string;
  desc?: string;
  picked_choices: VirtueChoiceEntry[];
  can_add_choice?: boolean;
};

type Data = {
  main_tabs: TabData[];
  sub_tabs: Record<string, TabData[]>;
  body_regions: RegionData[];
  book: {
    main_tab: string;
    sub_tab: string;
    selected_region: string;
  };
  expanded_panel?: string | null;
  header: {
    player_quality_text?: string;
    player_quality_color?: string;
    real_name: string;
    nickname: string;
    nickname_color: string;
    species: string;
    subspecies: string;
    voice_pack: string;
  };
  character_page: {
    identity: Record<string, string | number | boolean>;
    voice: Record<string, string | number | boolean>;
    lore: Record<string, string | number | boolean>;
    prefs: Record<string, string | number | boolean>;
    descriptors: string[];
    selected_region: {
      id: string;
      name: string;
      options: RegionOption[];
    };
  };
  settings_page: {
    general: Record<string, string | number | boolean>;
    ooc: Record<string, string | number | boolean>;
    keybinds_notice: string;
  };
  culinary_panel?: CulinaryPanel;
  familiar_panel?: FamiliarPanel;
  vice_panel?: VicePanel;
  virtue_panel?: VirtuePanel;
  virtue_two_panel?: VirtuePanel;
};

export const PreferencesBook = () => {
  const { act, data } = useBackend<Data>();
  const { main_tabs = [], sub_tabs = {}, book, header } = data;

  const currentMainTab = book?.main_tab || 'character';
  const currentSubTab = book?.sub_tab || 'appearance';
  const currentSubTabs = sub_tabs[currentMainTab] || [];

  return (
    <Window title="Character Book" width={1360} height={860}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Header">
              <Stack align="center">
                <Stack.Item>
                  <Button
                    onClick={() => act('open_pref_menu', { which: 'pq' })}
                    textColor={header?.player_quality_color || '#ffffff'}>
                    PQ: {header?.player_quality_text || 'Unknown'}
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Button fluid onClick={() => act('open_pref_menu', { which: 'changeslot' })}>
                    {header?.real_name || 'Unnamed'}
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button onClick={() => act('save_prefs')}>SAVE</Button>
                </Stack.Item>
                <Stack.Item>
                  <Button onClick={() => act('done_prefs')}>DONE</Button>
                </Stack.Item>
                <Stack.Item basis="150px">
                  <b>OOC Nickname</b>
                </Stack.Item>
                <Stack.Item grow>
                  <Input
                    fluid
                    value={header?.nickname || ''}
                    onChange={(value) => act('set_pref', { pref_id: 'nickname', value })}
                  />
                </Stack.Item>
                <Stack.Item basis="140px">
                  <Button
                    fluid
                    onClick={() => act('open_pref_menu', { which: 'nickname_color' })}
                    textColor={header?.nickname_color || '#ffffff'}>
                    Change color
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Book">
              <Tabs fluid>
                {main_tabs.map((tab) => (
                  <Tabs.Tab
                    key={tab.id}
                    selected={currentMainTab === tab.id}
                    onClick={() => act('set_main_tab', { tab: tab.id })}>
                    {tab.name}
                  </Tabs.Tab>
                ))}
              </Tabs>

              <Box mt={1}>
                {currentMainTab === 'character' && <CharacterPage />}
                {currentMainTab === 'loadout' && (
                  <PlaceholderPage
                    title="Loadout"
                    text="Phase 1: leave page in the book, open existing loadout UI from here."
                    buttonText="Open current loadout menu"
                    onButtonClick={() => act('open_loadout')}
                  />
                )}
                {currentMainTab === 'roles' && (
                  <PlaceholderPage
                    title="Roles"
                    text="Phase 1: leave page in the book, route to current class / role selection flow."
                    buttonText="Open current role menu"
                    onButtonClick={() => act('open_roles')}
                  />
                )}
                {currentMainTab === 'settings' && <SettingsPage />}
              </Box>

              <Box mt={2}>
                <Tabs fluid>
                  {currentSubTabs.map((tab) => (
                    <Tabs.Tab
                      key={tab.id}
                      selected={currentSubTab === tab.id}
                      onClick={() => act('set_sub_tab', { sub_tab: tab.id })}>
                      {tab.name}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const PlaceholderPage = (props: {
  title: string;
  text: string;
  buttonText: string;
  onButtonClick: () => void;
}) => (
  <Section title={props.title}>
    <NoticeBox>{props.text}</NoticeBox>
    <Box mt={1}>
      <Button onClick={props.onButtonClick}>{props.buttonText}</Button>
    </Box>
  </Section>
);

const CharacterPage = () => {
  const { act, data } = useBackend<Data>();
  const {
    body_regions = [],
    character_page,
    book,
    expanded_panel,
    culinary_panel,
    familiar_panel,
    vice_panel,
    virtue_panel,
    virtue_two_panel,
  } = data;
  const selected = character_page?.selected_region;
  const showVirtueTwo = Boolean(character_page?.prefs?.show_virtue_two);

  return (
    <Stack fill>
      <Stack.Item basis="34%">
        <Section title="Identity">
          <Field
            label="Name"
            value={String(character_page?.identity?.real_name || '')}
            onChange={(value) => act('set_pref', { pref_id: 'real_name', value })}
          />
          <ActionField label="Age" value={String(character_page?.identity?.age || '')} onClick={() => act('open_pref_menu', { which: 'age' })} />
          <ActionField label="Body Type" value={String(character_page?.identity?.body_type || '')} onClick={() => act('open_pref_menu', { which: 'body_type' })} />
          <ActionField label="Clothing" value={String(character_page?.identity?.clothing_type || '')} onClick={() => act('open_pref_menu', { which: 'clothing_type' })} />
          <ActionField label="Title" value={String(character_page?.identity?.titles_pref || '')} onClick={() => act('open_pref_menu', { which: 'titles_pref' })} />
          <ActionField label="Pronouns" value={String(character_page?.identity?.pronouns || '')} onClick={() => act('open_pref_menu', { which: 'pronouns' })} />
          <ActionField label="Race" value={String(character_page?.identity?.race || '')} onClick={() => act('open_pref_menu', { which: 'race' })} />
          <ActionField label="Subrace" value={String(character_page?.identity?.subrace || '')} onClick={() => act('open_pref_menu', { which: 'subrace' })} />
          <ActionField label="Race Bonus" value={String(character_page?.identity?.race_bonus || '')} onClick={() => act('open_pref_menu', { which: 'race_bonus' })} />
          <ActionField label="Language" value={String(character_page?.identity?.language || '')} onClick={() => act('open_pref_menu', { which: 'language' })} />
          <ActionField label="Origin" value={String(character_page?.identity?.origin || '')} onClick={() => act('open_pref_menu', { which: 'origin' })} />
        </Section>

        <Section title="Voice / Lore" mt={1}>
          <ActionField label="Voice Pack" value={String(character_page?.voice?.voice_pack || '')} onClick={() => act('open_pref_menu', { which: 'voice_pack' })} />
          <ActionField label="Voice Identity" value={String(character_page?.voice?.voice_type || '')} onClick={() => act('open_pref_menu', { which: 'voice_type' })} />
          <ColorActionField label="Voice Color" colorValue={String(character_page?.voice?.voice_color || '#ffffff')} onClick={() => act('open_pref_menu', { which: 'voice_color' })} />
          <ActionField label="Voice Pitch" value={String(character_page?.voice?.voice_pitch || '')} onClick={() => act('open_pref_menu', { which: 'voice_pitch' })} />
          <ActionField label="Faith" value={String(character_page?.lore?.faith || '')} onClick={() => act('open_pref_menu', { which: 'faith' })} />
          <ActionField label="God" value={String(character_page?.lore?.god || '')} onClick={() => act('open_pref_menu', { which: 'patron' })} />
          <ActionField label="Dominance" value={String(character_page?.lore?.dominance || '')} onClick={() => act('open_pref_menu', { which: 'domhand' })} />
          <ActionField label="Combat Music" value={String(character_page?.voice?.combat_music || '')} onClick={() => act('open_pref_menu', { which: 'combat_music' })} />
          <ActionField label="Unrevivable" value={String(character_page?.lore?.unrevivable || '')} onClick={() => act('toggle_unrevivable')} />
          <ActionField label="Food" value={String(character_page?.prefs?.food || '')} onClick={() => act('toggle_panel', { panel: 'food' })} />
          <EmbeddedFoodPanel expanded={expanded_panel === 'food'} culinaryPanel={culinary_panel} />
          <ActionField label="Familiar" value={String(character_page?.prefs?.familiar || '')} onClick={() => act('toggle_panel', { panel: 'familiar' })} />
          <EmbeddedFamiliarPanel expanded={expanded_panel === 'familiar'} familiarPanel={familiar_panel} />
          <ActionField label="Statpack" value={String(character_page?.prefs?.statpack || '')} onClick={() => act('open_pref_menu', { which: 'statpack' })} />
          <ActionField label="Vice" value={String(character_page?.prefs?.vice || '')} onClick={() => act('toggle_panel', { panel: 'vice' })} />
          <EmbeddedVicePanel expanded={expanded_panel === 'vice'} vicePanel={vice_panel} />
          <ActionField label="Virtue I" value={String(character_page?.prefs?.virtue || '')} onClick={() => act('open_pref_menu', { which: 'virtue' })} />
          <EmbeddedVirtuePanel expanded={expanded_panel === 'virtue'} panel={virtue_panel} prefix="virtue" />
          {showVirtueTwo && (
            <>
              <ActionField label="Virtue II" value={String(character_page?.prefs?.virtue_two || '')} onClick={() => act('open_pref_menu', { which: 'virtue_two' })} />
              <EmbeddedVirtuePanel expanded={expanded_panel === 'virtue_two'} panel={virtue_two_panel} prefix="virtue_two" />
            </>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item basis="32%">
        <Section title="Body Preview">
          <BodyPreview selectedRegion={String(book?.selected_region || 'head')} />
        </Section>

        <Section title="Colors / Quick Actions" mt={1}>
          <ActionField label="Skin Tone" value={String(character_page?.selected_region?.id === 'face' ? 'Edit skin' : 'Edit skin')} onClick={() => act('open_pref_menu', { which: 's_tone' })} />
          <ActionField label="Descriptors" value="Open editor" onClick={() => act('open_pref_menu', { which: 'descriptors' })} />
          <ActionField label="Body Markings" value="Open editor" onClick={() => act('open_pref_menu', { which: 'body_markings' })} />
          <ActionField label="Customizers" value="Open editor" onClick={() => act('open_pref_menu', { which: 'customizers' })} />
        </Section>
      </Stack.Item>

      <Stack.Item grow basis={0}>
        <Section title={`Region: ${selected?.name || 'None'}`}>
          <Box mb={1}>
            {body_regions.map((region) => (
              <Button
                key={region.id}
                selected={region.id === book?.selected_region}
                mr={0.5}
                mb={0.5}
                onClick={() => act('select_body_region', { region: region.id })}>
                {region.name}
              </Button>
            ))}
          </Box>
          <Box mt={1}>
            {(selected?.options || []).map((option) => (
              <Button
                key={option.id}
                mr={0.5}
                mb={0.5}
                onClick={() => act('open_pref_menu', { which: option.id })}>
                {option.name}
              </Button>
            ))}
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const EmbeddedFoodPanel = (props: { expanded: boolean; culinaryPanel?: CulinaryPanel }) => {
  const { act } = useBackend<Data>();
  const culinary = props.culinaryPanel;
  if (!props.expanded || !culinary) {
    return null;
  }
  const pickerTitle = culinary.picker_target_label || 'Select option';
  const pickerOptions = culinary.picker_mode === 'drink' ? culinary.drink_options : culinary.food_options;
  return (
    <Section title="Culinary Preferences" mt={1}>
      <CompactFoodRow label="Favourite Food" entry={culinary.fav_food} onClick={() => act('culinary_open_picker', { target: 'fav_food' })} />
      <CompactFoodRow label="Favourite Drink" entry={culinary.fav_drink} onClick={() => act('culinary_open_picker', { target: 'fav_drink' })} />
      <CompactFoodRow label="Hated Food" entry={culinary.hated_food} onClick={() => act('culinary_open_picker', { target: 'hated_food' })} />
      <CompactFoodRow label="Hated Drink" entry={culinary.hated_drink} onClick={() => act('culinary_open_picker', { target: 'hated_drink' })} />
      <Box mt={1}>
        <Button onClick={() => act('culinary_reset')}>Reset defaults</Button>
      </Box>
      {!!culinary.picker_target && (
        <Section title={pickerTitle} mt={1}>
          <Box mb={1}>
            <Button onClick={() => act('culinary_close_picker')}>Close</Button>
          </Box>
          <Stack vertical>
            {pickerOptions.map((option) => (
              <Stack.Item key={option.path || option.name}>
                <Button fluid onClick={() => act('culinary_select', { path: option.path })}>
                  <Stack align="center">
                    <Stack.Item basis="28px">
                      {option.icon ? <img src={option.icon} style={{ width: '22px', height: '22px', objectFit: 'contain' }} /> : '-'}
                    </Stack.Item>
                    <Stack.Item grow>{option.name}</Stack.Item>
                    <Stack.Item>({option.quality || '-'})</Stack.Item>
                  </Stack>
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      )}
    </Section>
  );
};

const CompactFoodRow = (props: { label: string; entry?: CulinaryEntry; onClick: () => void }) => (
  <Stack align="center" mb={0.5}>
    <Stack.Item basis="120px">
      <b>{props.label}</b>
    </Stack.Item>
    <Stack.Item basis="30px">
      {props.entry?.icon ? <img src={props.entry.icon} style={{ width: '22px', height: '22px', objectFit: 'contain' }} /> : '-'}
    </Stack.Item>
    <Stack.Item grow>
      <Button fluid onClick={props.onClick}>
        {props.entry?.name || 'None'}{props.entry?.quality ? ` (${props.entry.quality})` : ''}
      </Button>
    </Stack.Item>
  </Stack>
);

const EmbeddedFamiliarPanel = (props: { expanded: boolean; familiarPanel?: FamiliarPanel }) => {
  const { act } = useBackend<Data>();
  const fam = props.familiarPanel;
  if (!props.expanded || !fam) {
    return null;
  }
  return (
    <Section title="Familiar Preferences" mt={1}>
      <ActionField label="Name" value={fam.name || 'Set name'} onClick={() => act('familiar_edit', { field: 'familiar_name' })} />
      <ActionField label="Pronouns" value={fam.pronouns || 'they/them'} onClick={() => act('familiar_pick_pronouns')} />
      <ActionField label="Type" value={fam.specie_name || 'None selected'} onClick={() => act('familiar_pick_specie')} />
      {!!fam.lore_blurb && <NoticeBox mt={1}>{fam.lore_blurb}</NoticeBox>}
      <ActionField label="Headshot" value={fam.headshot ? 'Change headshot' : 'Set headshot'} onClick={() => act('familiar_edit', { field: 'familiar_headshot' })} />
      {!!fam.headshot && (
        <Box mt={1} textAlign="center">
          <img src={fam.headshot} style={{ maxWidth: '120px', maxHeight: '120px', objectFit: 'contain' }} />
        </Box>
      )}
      <ActionField label="Flavortext" value={fam.flavortext ? 'Edit flavortext' : 'Set flavortext'} onClick={() => act('familiar_edit', { field: 'familiar_flavortext' })} />
      <ActionField label="OOC Notes" value={fam.ooc_notes ? 'Edit OOC notes' : 'Set OOC notes'} onClick={() => act('familiar_edit', { field: 'familiar_ooc_notes' })} />
      <ActionField label="OOC Extra" value={fam.ooc_extra_link ? 'Edit extra media' : 'Set extra media'} onClick={() => act('familiar_edit', { field: 'familiar_ooc_extra' })} />
      <Box mt={1}>
        <Button onClick={() => act('familiar_toggle_queue')}>
          {fam.in_queue ? 'Leave Queue' : 'Join Queue'}
        </Button>
      </Box>
    </Section>
  );
};

const EmbeddedVicePanel = (props: { expanded: boolean; vicePanel?: VicePanel }) => {
  const { act } = useBackend<Data>();
  const panel = props.vicePanel;
  if (!props.expanded || !panel) {
    return null;
  }
  return (
    <Section title="Vices" mt={1}>
      <Box mb={1}>
        <Button disabled={!panel.can_add} onClick={() => act('vice_add')}>
          Add vice
        </Button>
      </Box>
      {panel.items.map((item) => (
        <Section key={item.index} title={item.name} mt={1}>
          <Box>{item.desc || '-'}</Box>
          <Box mt={1}>
            <Button onClick={() => act('vice_remove', { index: item.index })}>Remove</Button>
          </Box>
        </Section>
      ))}
    </Section>
  );
};

const EmbeddedVirtuePanel = (props: { expanded: boolean; panel?: VirtuePanel; prefix: 'virtue' | 'virtue_two' }) => {
  const { act } = useBackend<Data>();
  const panel = props.panel;
  if (!props.expanded || !panel) {
    return null;
  }
  const addAction = props.prefix === 'virtue' ? 'virtue_add_choice' : 'virtue_two_add_choice';
  const removeAction = props.prefix === 'virtue' ? 'virtue_remove_choice' : 'virtue_two_remove_choice';
  const tooltipAction = props.prefix === 'virtue' ? 'virtue_tooltip' : 'virtue_two_tooltip';
  return (
    <Section title={panel.name || 'Virtue'} mt={1}>
      {!!panel.desc && <NoticeBox>{panel.desc}</NoticeBox>}
      <Box mt={1}>
        <Button disabled={!panel.can_add_choice} onClick={() => act(addAction)}>
          Add variation
        </Button>
      </Box>
      {(panel.picked_choices || []).map((choice) => (
        <Stack key={choice.index} align="center" mt={0.5}>
          <Stack.Item grow>
            <Box>{choice.name}</Box>
          </Stack.Item>
          {!!choice.tooltip && (
            <Stack.Item>
              <Button onClick={() => act(tooltipAction, { tooltip: choice.name })}>?</Button>
            </Stack.Item>
          )}
          <Stack.Item>
            <Button onClick={() => act(removeAction, { index: choice.index })}>Remove</Button>
          </Stack.Item>
        </Stack>
      ))}
    </Section>
  );
};

const BodyPreview = (props: { selectedRegion: string }) => {
  const { act } = useBackend<Data>();

  const zoneStyle = (selected: boolean, top: string, left: string, width: string, height: string) => ({
    position: 'absolute' as const,
    top,
    left,
    width,
    height,
    border: selected ? '2px solid rgba(255, 210, 80, 0.95)' : '1px solid rgba(255,255,255,0.18)',
    background: selected ? 'rgba(255, 210, 80, 0.18)' : 'rgba(255,255,255,0.04)',
    borderRadius: '10px',
    cursor: 'pointer',
    transition: 'all 120ms ease',
  });

  const zoneButton = (
    id: string,
    label: string,
    top: string,
    left: string,
    width: string,
    height: string,
  ) => (
    <div
      key={label}
      style={zoneStyle(props.selectedRegion === id, top, left, width, height)}
      onClick={() => act('select_body_region', { region: id })}
      title={label}
    />
  );

  return (
    <Box
      style={{
        position: 'relative',
        width: '260px',
        height: '520px',
        margin: '0 auto',
        borderRadius: '16px',
        background: 'linear-gradient(180deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02))',
        border: '1px solid rgba(255,255,255,0.08)',
      }}>
      <div
        style={{
          position: 'absolute',
          top: '18px',
          left: '92px',
          width: '76px',
          height: '76px',
          borderRadius: '999px',
          background: 'rgba(220,220,220,0.18)',
          border: '1px solid rgba(255,255,255,0.12)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '95px',
          left: '118px',
          width: '24px',
          height: '24px',
          borderRadius: '999px',
          background: 'rgba(220,220,220,0.14)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '120px',
          left: '78px',
          width: '104px',
          height: '142px',
          borderRadius: '26px',
          background: 'rgba(220,220,220,0.18)',
          border: '1px solid rgba(255,255,255,0.12)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '120px',
          left: '38px',
          width: '30px',
          height: '160px',
          borderRadius: '20px',
          background: 'rgba(220,220,220,0.16)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '120px',
          right: '38px',
          width: '30px',
          height: '160px',
          borderRadius: '20px',
          background: 'rgba(220,220,220,0.16)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '265px',
          left: '98px',
          width: '64px',
          height: '58px',
          borderRadius: '18px',
          background: 'rgba(220,220,220,0.18)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '322px',
          left: '88px',
          width: '34px',
          height: '160px',
          borderRadius: '22px',
          background: 'rgba(220,220,220,0.16)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          top: '322px',
          left: '138px',
          width: '34px',
          height: '160px',
          borderRadius: '22px',
          background: 'rgba(220,220,220,0.16)',
        }}
      />

      {zoneButton('head', 'Forehead / Head', '20px', '88px', '84px', '30px')}
      {zoneButton('face', 'Face', '50px', '86px', '88px', '52px')}
      {zoneButton('torso', 'Torso', '122px', '74px', '112px', '118px')}
      {zoneButton('arms', 'Left Arm', '126px', '28px', '46px', '152px')}
      {zoneButton('arms', 'Right Arm', '126px', '186px', '46px', '152px')}
      {zoneButton('organs', 'Groin', '248px', '94px', '72px', '68px')}
      {zoneButton('legs', 'Left Leg', '322px', '78px', '48px', '166px')}
      {zoneButton('legs', 'Right Leg', '322px', '134px', '48px', '166px')}

      <Box
        style={{
          position: 'absolute',
          bottom: '10px',
          left: '0',
          width: '100%',
          textAlign: 'center',
          opacity: 0.8,
          fontSize: '12px',
        }}>
        Selected: {props.selectedRegion}
      </Box>
    </Box>
  );
};

const SettingsPage = () => {
  const { act, data } = useBackend<Data>();
  const { book, settings_page } = data;
  const subTab = book?.sub_tab || 'general';

  if (subTab === 'keybinds') {
    return (
      <Section title="Keybinds">
        <NoticeBox>{settings_page?.keybinds_notice || 'Placeholder'}</NoticeBox>
      </Section>
    );
  }

  return (
    <Stack fill>
      <Stack.Item basis="50%">
        <Section title="General">
          <BooleanField label="Ambient Occlusion" value={Boolean(settings_page?.general?.ambientocclusion)} onClick={() => act('toggle_bool', { pref_id: 'ambientocclusion' })} />
          <BooleanField label="Widescreen" value={Boolean(settings_page?.general?.widescreenpref)} onClick={() => act('toggle_bool', { pref_id: 'widescreenpref' })} />
          <BooleanField label="Auto fit viewport" value={Boolean(settings_page?.general?.auto_fit_viewport)} onClick={() => act('toggle_bool', { pref_id: 'auto_fit_viewport' })} />
          <Field label="Pixel size" value={String(settings_page?.general?.pixel_size || '')} readOnly />
          <Box mt={1}>
            <Button onClick={() => act('open_theme_picker')}>Open theme picker</Button>
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Section title="OOC / UI">
          <Field label="OOC color" value={String(settings_page?.ooc?.ooccolor || '')} onChange={(value) => act('set_pref', { pref_id: 'ooccolor', value })} />
          <Field label="ASAY color" value={String(settings_page?.ooc?.asaycolor || '')} onChange={(value) => act('set_pref', { pref_id: 'asaycolor', value })} />
          <Field label="UI style" value={String(settings_page?.ooc?.UI_style || '')} onChange={(value) => act('set_pref', { pref_id: 'UI_style', value })} />
          <BooleanField label="Chat on map" value={Boolean(settings_page?.ooc?.chat_on_map)} onClick={() => act('toggle_bool', { pref_id: 'chat_on_map' })} />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const Field = (props: { label: string; value: string; onChange?: (value: string) => void; readOnly?: boolean }) => (
  <Stack align="center" mb={0.5}>
    <Stack.Item basis="120px"><b>{props.label}</b></Stack.Item>
    <Stack.Item grow>
      {props.readOnly ? (
        <Box p={0.5} style={{ border: '1px solid rgba(255, 255, 255, 0.2)', borderRadius: '4px', minHeight: '24px', lineHeight: '24px' }}>
          {props.value || '-'}
        </Box>
      ) : (
        <Input fluid value={props.value} onChange={(value) => props.onChange?.(String(value))} />
      )}
    </Stack.Item>
  </Stack>
);

const BooleanField = (props: { label: string; value: boolean; onClick: () => void }) => (
  <Stack align="center" mb={0.5}>
    <Stack.Item basis="180px"><b>{props.label}</b></Stack.Item>
    <Stack.Item>
      <Button selected={props.value} onClick={props.onClick}>
        {props.value ? 'On' : 'Off'}
      </Button>
    </Stack.Item>
  </Stack>
);

const ActionField = (props: { label: string; value: string; onClick: () => void }) => (
  <Stack align="center" mb={0.5}>
    <Stack.Item basis="120px"><b>{props.label}</b></Stack.Item>
    <Stack.Item grow>
      <Button fluid onClick={props.onClick}>{props.value || '-'}</Button>
    </Stack.Item>
  </Stack>
);

const ColorActionField = (props: { label: string; colorValue: string; onClick: () => void }) => (
  <Stack align="center" mb={0.5}>
    <Stack.Item basis="120px"><b>{props.label}</b></Stack.Item>
    <Stack.Item grow>
      <Button fluid onClick={props.onClick} textColor={props.colorValue || '#ffffff'}>
        Change color
      </Button>
    </Stack.Item>
  </Stack>
);
