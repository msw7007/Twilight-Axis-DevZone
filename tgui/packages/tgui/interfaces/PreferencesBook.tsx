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

type Data = {
  main_tabs: TabData[];
  sub_tabs: Record<string, TabData[]>;
  body_regions: RegionData[];
  book: {
    main_tab: string;
    sub_tab: string;
    selected_region: string;
  };
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
    identity: Record<string, string | number>;
    voice: Record<string, string | number>;
    lore: Record<string, string | number>;
    prefs: Record<string, string | number>;
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
};

export const PreferencesBook = () => {
  const { act, data } = useBackend<Data>();
  const { main_tabs = [], sub_tabs = {}, book, header } = data;

  const currentMainTab = book?.main_tab || 'character';
  const currentSubTab = book?.sub_tab || 'appearance';
  const currentSubTabs = sub_tabs[currentMainTab] || [];

  const handleSetMainTab = (tabId: string) =>
    act('set_main_tab', { tab: tabId });

  const handleSetSubTab = (tabId: string) =>
    act('set_sub_tab', { sub_tab: tabId });

  const handleOpenLoadout = () =>
    act('open_loadout');

  const handleOpenRoles = () =>
    act('open_roles');

  const handleOpenCharacterSlot = () =>
    act('open_pref_menu', { which: 'changeslot' });

  const handleOpenPQ = () =>
    act('open_pref_menu', { which: 'pq' });

  const handleSavePrefs = () =>
    act('save_prefs');

  const handleDonePrefs = () =>
    act('done_prefs');

  const handleSetNickname = (value: string) =>
    act('set_pref', { pref_id: 'nickname', value });

  const handleOpenNicknameColor = () =>
    act('open_pref_menu', { which: 'nickname_color' });

  return (
    <Window title="Character Book" width={1220} height={820}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Header">
              <Stack align="center">
                <Stack.Item>
                  <Button
                    onClick={handleOpenPQ}
                    textColor={header?.player_quality_color || '#ffffff'}
                  >
                    PQ: {header?.player_quality_text || 'Unknown'}
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Button fluid onClick={handleOpenCharacterSlot}>
                    {header?.real_name || 'Unnamed'}
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button onClick={handleSavePrefs}>SAVE</Button>
                </Stack.Item>
                <Stack.Item>
                  <Button onClick={handleDonePrefs}>DONE</Button>
                </Stack.Item>
                <Stack.Item basis="150px">
                  <b>OOC Nickname</b>
                </Stack.Item>
                <Stack.Item grow>
                  <Input fluid value={header?.nickname || ''} onChange={handleSetNickname} />
                </Stack.Item>
                <Stack.Item basis="140px">
                  <Button
                    fluid
                    onClick={handleOpenNicknameColor}
                    textColor={header?.nickname_color || '#ffffff'}
                  >
                    Change color
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Book">
              <Tabs fluid>
                {main_tabs.map((tab) => {
                  const handleClickMainTab = () => handleSetMainTab(tab.id);

                  return (
                    <Tabs.Tab
                      key={tab.id}
                      selected={currentMainTab === tab.id}
                      onClick={handleClickMainTab}
                    >
                      {tab.name}
                    </Tabs.Tab>
                  );
                })}
              </Tabs>

              <Box mt={1}>
                {currentMainTab === 'character' && (
                  <CharacterPage />
                )}
                {currentMainTab === 'loadout' && (
                  <PlaceholderPage
                    title="Loadout"
                    text="Phase 1: leave page in the book, open existing loadout UI from here."
                    buttonText="Open current loadout menu"
                    onButtonClick={handleOpenLoadout}
                  />
                )}
                {currentMainTab === 'roles' && (
                  <PlaceholderPage
                    title="Roles"
                    text="Phase 1: leave page in the book, route to current class / role selection flow."
                    buttonText="Open current role menu"
                    onButtonClick={handleOpenRoles}
                  />
                )}
                {currentMainTab === 'settings' && (
                  <SettingsPage />
                )}
              </Box>

              <Box mt={2}>
                <Tabs fluid>
                  {currentSubTabs.map((tab) => {
                    const handleClickSubTab = () => handleSetSubTab(tab.id);

                    return (
                      <Tabs.Tab
                        key={tab.id}
                        selected={currentSubTab === tab.id}
                        onClick={handleClickSubTab}
                      >
                        {tab.name}
                      </Tabs.Tab>
                    );
                  })}
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
}) => {
  const handleButtonClick = props.onButtonClick;

  return (
    <Section title={props.title}>
      <NoticeBox>{props.text}</NoticeBox>
      <Box mt={1}>
        <Button onClick={handleButtonClick}>{props.buttonText}</Button>
      </Box>
    </Section>
  );
};

const CharacterPage = () => {
  const { act, data } = useBackend<Data>();
  const { body_regions = [], character_page, book } = data;
  const selected = character_page?.selected_region;

  const handleSetRealName = (value: string) =>
    act('set_pref', { pref_id: 'real_name', value });

  const handleOpenAge = () =>
    act('open_pref_menu', { which: 'age' });

  const handleOpenBodyType = () =>
    act('open_pref_menu', { which: 'body_type' });

  const handleOpenClothingType = () =>
    act('open_pref_menu', { which: 'clothing_type' });

  const handleOpenTitlesPref = () =>
    act('open_pref_menu', { which: 'titles_pref' });

  const handleOpenPronouns = () =>
    act('open_pref_menu', { which: 'pronouns' });

  const handleOpenRace = () =>
    act('open_pref_menu', { which: 'race' });

  const handleOpenSubrace = () =>
    act('open_pref_menu', { which: 'subrace' });

  const handleOpenRaceBonus = () =>
    act('open_pref_menu', { which: 'race_bonus' });

  const handleOpenLanguage = () =>
    act('open_pref_menu', { which: 'language' });

  const handleOpenOrigin = () =>
    act('open_pref_menu', { which: 'origin' });

  const handleOpenVoicePack = () =>
    act('open_pref_menu', { which: 'voice_pack' });

  const handleOpenVoiceType = () =>
    act('open_pref_menu', { which: 'voice_type' });

  const handleOpenVoiceColor = () =>
    act('open_pref_menu', { which: 'voice_color' });

  const handleOpenVoicePitch = () =>
    act('open_pref_menu', { which: 'voice_pitch' });

  const handleOpenFaith = () =>
    act('open_pref_menu', { which: 'faith' });

  const handleOpenPatron = () =>
    act('open_pref_menu', { which: 'patron' });

  const handleOpenDomhand = () =>
    act('open_pref_menu', { which: 'domhand' });

  const handleOpenCombatMusic = () =>
    act('open_pref_menu', { which: 'combat_music' });

  const handleOpenUnrevivable = () =>
    act('toggle_unrevivable');

  const handleSelectBodyRegion = (regionId: string) =>
    act('select_body_region', { region: regionId });

  const handleOpenRegionOption = (optionId: string) =>
    act('open_pref_menu', { which: optionId });

  return (
    <Stack fill>
      <Stack.Item basis="50%">
        <Section title="Identity">
          <Field
            label="Name"
            value={String(character_page?.identity?.real_name || '')}
            onChange={handleSetRealName}
          />
          <ActionField
            label="Age"
            value={String(character_page?.identity?.age || '')}
            onClick={handleOpenAge}
          />
          <ActionField
            label="Body Type"
            value={String(character_page?.identity?.body_type || '')}
            onClick={handleOpenBodyType}
          />
          <ActionField
            label="Clothing"
            value={String(character_page?.identity?.clothing_type || '')}
            onClick={handleOpenClothingType}
          />
          <ActionField
            label="Title"
            value={String(character_page?.identity?.titles_pref || '')}
            onClick={handleOpenTitlesPref}
          />
          <ActionField
            label="Pronouns"
            value={String(character_page?.identity?.pronouns || '')}
            onClick={handleOpenPronouns}
          />
          <ActionField
            label="Race"
            value={String(character_page?.identity?.race || '')}
            onClick={handleOpenRace}
          />
          <ActionField
            label="Subrace"
            value={String(character_page?.identity?.subrace || '')}
            onClick={handleOpenSubrace}
          />
          <ActionField
            label="Race Bonus"
            value={String(character_page?.identity?.race_bonus || '')}
            onClick={handleOpenRaceBonus}
          />
          <ActionField
            label="Language"
            value={String(character_page?.identity?.language || '')}
            onClick={handleOpenLanguage}
          />
          <ActionField
            label="Origin"
            value={String(character_page?.identity?.origin || '')}
            onClick={handleOpenOrigin}
          />
        </Section>

        <Section title="Voice / Lore" mt={1}>
          <ActionField
            label="Voice Pack"
            value={String(character_page?.voice?.voice_pack || '')}
            onClick={handleOpenVoicePack}
          />
          <ActionField
            label="Voice Identity"
            value={String(character_page?.voice?.voice_type || '')}
            onClick={handleOpenVoiceType}
          />
          <ColorActionField
            label="Voice Color"
            colorValue={String(character_page?.voice?.voice_color || '#ffffff')}
            onClick={handleOpenVoiceColor}
          />
          <ActionField
            label="Voice Pitch"
            value={String(character_page?.voice?.voice_pitch || '')}
            onClick={handleOpenVoicePitch}
          />
          <ActionField
            label="Faith"
            value={String(character_page?.lore?.faith || '')}
            onClick={handleOpenFaith}
          />
          <ActionField
            label="God"
            value={String(character_page?.lore?.god || '')}
            onClick={handleOpenPatron}
          />
          <ActionField
            label="Dominance"
            value={String(character_page?.lore?.dominance || '')}
            onClick={handleOpenDomhand}
          />
          <ActionField
            label="Combat Music"
            value={String(character_page?.voice?.combat_music || '')}
            onClick={handleOpenCombatMusic}
          />
          <ActionField
            label="Unrevivable"
            value={String(character_page?.lore?.unrevivable || '')}
            onClick={handleOpenUnrevivable}
          />
          <Field
            label="Food"
            value={String(character_page?.prefs?.food || '')}
            readOnly
          />
          <Field
            label="Familiar"
            value={String(character_page?.prefs?.familiar || '')}
            readOnly
          />
          <Field
            label="Statpack"
            value={String(character_page?.prefs?.statpack || '')}
            readOnly
          />
          <Field
            label="Vice"
            value={String(character_page?.prefs?.vice || '')}
            readOnly
          />
          <Field
            label="Virtue"
            value={String(character_page?.prefs?.virtue || '')}
            readOnly
          />
        </Section>
      </Stack.Item>

      <Stack.Item grow basis={0}>
        <Section title="Appearance">
          <Stack>
            <Stack.Item grow>
              <Section title="Body Preview">
                <BodyPreview selectedRegion={book?.selected_region} />
              </Section>
            </Stack.Item>
            <Stack.Item basis="240px">
              <Section title="Descriptors / Color">
                <Button fluid onClick={() => act('open_pref_menu', { which: 'descriptors' })}>
                  Open descriptors editor
                </Button>
                <Button fluid mt={1} onClick={() => act('open_pref_menu', { which: 'body_markings' })}>
                  Open markings editor
                </Button>
              </Section>
            </Stack.Item>
          </Stack>

          <Section title={`Region: ${selected?.name || 'None'}`} mt={1}>
            <Box mb={1}>
              {body_regions.map((region) => {
                const handleClickRegion = () => handleSelectBodyRegion(region.id);

                return (
                  <Button
                    key={region.id}
                    selected={region.id === book?.selected_region}
                    mr={0.5}
                    mb={0.5}
                    onClick={handleClickRegion}
                  >
                    {region.name}
                  </Button>
                );
              })}
            </Box>
            <Box mt={1}>
              {(selected?.options || []).map((option) => {
                const handleClickOption = () => handleOpenRegionOption(option.id);

                return (
                  <Button
                    key={option.id}
                    mr={0.5}
                    mb={0.5}
                    onClick={handleClickOption}
                  >
                    {option.name}
                  </Button>
                );
              })}
            </Box>
          </Section>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const BodyPreview = (props: { selectedRegion: string }) => {
  const { act } = useBackend<Data>();

  const renderBodyButton = (id: string, label: string) => {
    const handleSelectRegion = () =>
      act('select_body_region', { region: id });

    return (
      <Button
        fluid
        selected={props.selectedRegion === id}
        onClick={handleSelectRegion}
        mb={0.5}
      >
        {label}
      </Button>
    );
  };

  return (
    <Stack vertical align="center">
      <Stack.Item width="220px">{renderBodyButton('head', 'Head')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('face', 'Face')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('torso', 'Torso')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('arms', 'Arms')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('hands', 'Hands')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('legs', 'Legs')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('feet', 'Feet')}</Stack.Item>
      <Stack.Item width="220px">{renderBodyButton('organs', 'Organs')}</Stack.Item>
    </Stack>
  );
};

const SettingsPage = () => {
  const { act, data } = useBackend<Data>();
  const { book, settings_page } = data;
  const subTab = book?.sub_tab || 'general';

  const handleToggleAmbientOcclusion = () =>
    act('toggle_bool', { pref_id: 'ambientocclusion' });

  const handleToggleWidescreen = () =>
    act('toggle_bool', { pref_id: 'widescreenpref' });

  const handleToggleAutoFitViewport = () =>
    act('toggle_bool', { pref_id: 'auto_fit_viewport' });

  const handleOpenThemePicker = () =>
    act('open_theme_picker');

  const handleSetOocColor = (value: string) =>
    act('set_pref', { pref_id: 'ooccolor', value });

  const handleSetAsayColor = (value: string) =>
    act('set_pref', { pref_id: 'asaycolor', value });

  const handleSetUiStyle = (value: string) =>
    act('set_pref', { pref_id: 'UI_style', value });

  const handleToggleChatOnMap = () =>
    act('toggle_bool', { pref_id: 'chat_on_map' });

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
          <BooleanField
            label="Ambient Occlusion"
            value={Boolean(settings_page?.general?.ambientocclusion)}
            onClick={handleToggleAmbientOcclusion}
          />
          <BooleanField
            label="Widescreen"
            value={Boolean(settings_page?.general?.widescreenpref)}
            onClick={handleToggleWidescreen}
          />
          <BooleanField
            label="Auto fit viewport"
            value={Boolean(settings_page?.general?.auto_fit_viewport)}
            onClick={handleToggleAutoFitViewport}
          />
          <Field
            label="Pixel size"
            value={String(settings_page?.general?.pixel_size || '')}
            readOnly
          />
          <Box mt={1}>
            <Button onClick={handleOpenThemePicker}>Open theme picker</Button>
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Section title="OOC / UI">
          <Field
            label="OOC color"
            value={String(settings_page?.ooc?.ooccolor || '')}
            onChange={handleSetOocColor}
          />
          <Field
            label="ASAY color"
            value={String(settings_page?.ooc?.asaycolor || '')}
            onChange={handleSetAsayColor}
          />
          <Field
            label="UI style"
            value={String(settings_page?.ooc?.UI_style || '')}
            onChange={handleSetUiStyle}
          />
          <BooleanField
            label="Chat on map"
            value={Boolean(settings_page?.ooc?.chat_on_map)}
            onClick={handleToggleChatOnMap}
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const Field = (props: {
  label: string;
  value: string;
  onChange?: (value: string) => void;
  readOnly?: boolean;
}) => {
  const handleChange = (value: string) => {
    props.onChange?.(String(value));
  };

  return (
    <Stack align="center" mb={0.5}>
      <Stack.Item basis="120px">
        <b>{props.label}</b>
      </Stack.Item>
      <Stack.Item grow>
        {props.readOnly ? (
          <Box
            p={0.5}
            style={{
              border: '1px solid rgba(255, 255, 255, 0.2)',
              borderRadius: '4px',
              minHeight: '24px',
              lineHeight: '24px',
            }}
          >
            {props.value || '-'}
          </Box>
        ) : (
          <Input
            fluid
            value={props.value}
            onChange={handleChange}
          />
        )}
      </Stack.Item>
    </Stack>
  );
};

const BooleanField = (props: {
  label: string;
  value: boolean;
  onClick: () => void;
}) => (
  <Stack align="center" mb={0.5}>
    <Stack.Item basis="180px">
      <b>{props.label}</b>
    </Stack.Item>
    <Stack.Item>
      <Button selected={props.value} onClick={props.onClick}>
        {props.value ? 'On' : 'Off'}
      </Button>
    </Stack.Item>
  </Stack>
);

const ActionField = (props: {
  label: string;
  value: string;
  onClick: () => void;
}) => {
  const handleClick = props.onClick;

  return (
    <Stack align="center" mb={0.5}>
      <Stack.Item basis="120px">
        <b>{props.label}</b>
      </Stack.Item>
      <Stack.Item grow>
        <Button fluid onClick={handleClick}>
          {props.value || '-'}
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const ColorActionField = (props: {
  label: string;
  colorValue: string;
  onClick: () => void;
}) => {
  const handleClick = props.onClick;

  return (
    <Stack align="center" mb={0.5}>
      <Stack.Item basis="120px">
        <b>{props.label}</b>
      </Stack.Item>
      <Stack.Item grow>
        <Button fluid onClick={handleClick} textColor={props.colorValue || '#ffffff'}>
          Change color
        </Button>
      </Stack.Item>
    </Stack>
  );
};
