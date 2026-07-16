import { type ChangeEvent, useEffect, useMemo, useState } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Word = {
  id: string;
  name: string;
  desc: string;
  school_id?: string;
  role: string;
  mana_cost: number;
  cast_time: number;
  complexity: number;
  instability: number;
  interrupt_chance?: number;
  unlock_level: number;
  learn_cost: number;
  tags: string[];
  phrases: string[];
};

type Preview = {
  text: string;
  can_resolve: boolean;
  mana_cost: number;
  cast_time: number;
  complexity: number;
  instability: number;
  interrupt_chance?: number;
  power: number;
  radius: number;
  range: number;
  duration: number;
  delay: number;
  projectile_count: number;
  tags: Record<string, number>;
};

type Progression = {
  total_points: number;
  spent_points: number;
  free_points: number;
  school_points: Record<string, number>;
  form_points: Record<string, number>;
  committed_school_points?: Record<string, number>;
  committed_form_points?: Record<string, number>;
  school_access?: Record<string, boolean>;
  committed?: boolean;
  can_reassign?: boolean;
  dirty?: boolean;
};

type Preset = {
  name: string;
  words: string[];
  summary: string;
  mana_cost: number;
  cast_time: number;
  complexity: number;
  arcane_required?: number;
  reading_required?: number;
  requirements?: string[];
  export_json?: string;
};

type DraftPart = {
  name: string;
  words: string[];
  indexes: number[];
};

type Validation = {
  valid?: boolean;
  missing?: string[];
  requirements?: string[];
  arcane_required?: number;
  reading_required?: number;
  max_mana?: number;
};

type Data = {
  words?: Word[];
  draft_words?: string[];
  draft_parts?: DraftPart[];
  draft_name?: string;
  preview?: Preview;
  known_words?: string[];
  known_word_counts?: Record<string, number>;
  progression?: Progression;
  school_names?: Record<string, string>;
  school_access?: Record<string, boolean>;
  form_names?: Record<string, string>;
  form_unlocks?: Record<string, number>;
  presets?: Preset[];
  draft_export_json?: string;
  draft_validation?: Validation;
  loaded_preset_index?: number;
  loaded_preset_name?: string;
  loaded_preset_changed?: boolean;
  formula_slot_limit?: number;
  max_mana?: number;
};

const roleNames: Record<string, string> = {
  form: 'Forms',
  element: 'Elements',
  modifier: 'Modifiers',
};

const roleOrder = ['form', 'element', 'modifier'];

export const FormulaSpellcraft = () => {
  const { act, data } = useBackend<Data>();
  const progression = data.progression || {
      total_points: 0,
      spent_points: 0,
      free_points: 0,
      school_points: {},
      form_points: {},
      committed_school_points: {},
      committed_form_points: {},
    };
  progression.school_points = progression.school_points || {};
  progression.form_points = progression.form_points || {};
  progression.committed_school_points = progression.committed_school_points || {};
  progression.committed_form_points = progression.committed_form_points || {};
  progression.school_access = progression.school_access || {};
  const words = asArray<Word>(data.words);
  const draft_words = asArray<string>(data.draft_words);
  const draft_parts = asArray<DraftPart>(data.draft_parts);
  const known_word_counts = data.known_word_counts || {};
  const presets = asArray<Preset>(data.presets);
  const preview = data.preview;
  const school_names = data.school_names || {};
  const school_access = data.school_access || progression.school_access || {};
  const form_names = data.form_names || {};
  const form_unlocks = data.form_unlocks || {};

  const [tab, setTab] = useState<'forms' | 'schools' | 'presets' | 'library'>('forms');
  const [role, setRole] = useState('form');
  const [schoolFilter, setSchoolFilter] = useState('all');
  const [selectedSchool, setSelectedSchool] = useState('');
  const [presetName, setPresetName] = useState('');
  const [importJson, setImportJson] = useState('');

  useEffect(() => {
    setPresetName(data.draft_name || '');
  }, [data.draft_name]);

  const byId = useMemo(() => new Map(words.map((word) => [word.id, word])), [words]);
  const schoolEntries = Object.entries(school_names).filter(([id]) => id !== 'arcane' && school_access[id] !== false);
  const activeSchool = selectedSchool && schoolEntries.some(([id]) => id === selectedSchool) ? selectedSchool : schoolEntries[0]?.[0] || '';
  const isPrebuilt = (word: Word) => word.tags?.includes('prebuilt_formula');
  const isFreeModifier = (word: Word) => word.role === 'modifier';
  const formWords = words.filter((word) => word.role === 'form' && !word.school_id && !isPrebuilt(word));
  const schoolWords = words.filter((word) => word.school_id === activeSchool && word.role !== 'form');
  const formCost = (formId: string) => form_unlocks[formId] || byId.get(formId)?.learn_cost || 1;
  const formRank = (formId: string, points = progression.form_points[formId] || 0) => Math.floor(points / Math.max(1, formCost(formId)));
  const canRaiseForm = (formId: string) => {
    return progression.free_points >= formCost(formId);
  };
  const canLowerForm = (formId: string, lockedFloor: number) => {
    const points = progression.form_points[formId] || 0;
    return points > lockedFloor;
  };

  const canLearn = (word: Word) => {
    if (isFreeModifier(word)) {
      return true;
    }
    if (isPrebuilt(word)) {
      return !!word.school_id && (progression.school_points[word.school_id] || 0) >= word.unlock_level;
    }
    if (!word.school_id && word.role === 'form') {
      return (progression.form_points[word.id] || 0) >= (form_unlocks[word.id] || 1);
    }
    return !!word.school_id && (progression.school_points[word.school_id] || 0) >= word.unlock_level;
  };

  const canUseCommitted = (word: Word) => {
    if (isFreeModifier(word)) {
      return true;
    }
    if (!progression.committed || progression.dirty) return false;
    if (isPrebuilt(word)) {
      return (known_word_counts[word.id] || 0) > 0;
    }
    if (!word.school_id && word.role === 'form') {
      return ((progression.committed_form_points || {})[word.id] || 0) >= (form_unlocks[word.id] || 1);
    }
    return (known_word_counts[word.id] || 0) > 0;
  };

  const canUse = (word: Word) => {
    return canUseCommitted(word);
  };

  const visibleWords = words.filter((word) => {
    if (!canUse(word)) return false;
    const visibleRole = word.role === 'post_effect' || word.role === 'link' || word.role === 'stabilizer' ? 'modifier' : word.role;
    if (visibleRole !== role) return false;
    if (schoolFilter === 'all') return true;
    return word.school_id === schoolFilter;
  });
  const formulaSlotLimit = data.formula_slot_limit || 1;
  const draftValid = Boolean(data.draft_validation?.valid);
  const effectivePresetName = presetName || data.draft_name || 'Formula';
  const namedPresetIndex = presets.findIndex((preset) => preset.name.toLowerCase() === effectivePresetName.toLowerCase());
  const canSaveFormula = draftValid && (namedPresetIndex >= 0 || presets.length < formulaSlotLimit);
  const saveLabel = namedPresetIndex >= 0 ? 'Overwrite' : 'Save New';

  return (
    <Window width={1040} height={680} title="Formula Spellcraft">
      <Window.Content fitted>
        <div style={rootStyle}>
          <Header progression={progression} />
          <div style={tabsStyle}>
            <TabButton active={tab === 'forms'} onClick={() => setTab('forms')} label="Forms" />
            <TabButton active={tab === 'schools'} onClick={() => setTab('schools')} label="Schools" />
            <TabButton active={tab === 'presets'} onClick={() => setTab('presets')} label="Formulas" />
            <TabButton active={tab === 'library'} onClick={() => setTab('library')} label="Library" />
            <button
              type="button"
              disabled={!progression.dirty}
              onClick={() => act('commit_allocations')}
              style={buttonStyle(progression.dirty ? '#39a85a' : '#303744')}
            >
              Save Knowledge
            </button>
          </div>

          {tab === 'schools' && (
            <div style={{ ...bodyStyle, display: 'flex', gap: '10px', minHeight: 0 }}>
              <div style={{ width: '25%', minWidth: '220px', overflowY: 'auto', paddingRight: '2px' }}>
                <div style={mutedStyle}>Choose a school, invest points, then learn its words after saving knowledge.</div>
                <div style={wordListStyle}>
                  {schoolEntries.map(([id, name]) => {
                    const points = progression.school_points[id] || 0;
                    const committedPoints = (progression.committed_school_points || {})[id] || 0;
                    const lockedFloor = progression.can_reassign ? 0 : committedPoints;
                    const usedWords = words
                      .filter((word) => word.school_id === id)
                      .reduce((total, word) => total + (known_word_counts[word.id] || 0), 0);
                    return (
                      <div key={id} role="button" onClick={() => setSelectedSchool(id)} style={schoolTabStyle(activeSchool === id)}>
                        <div style={rowStyle}>
                          <div>
                            <div style={titleStyle}>{name}</div>
                            <div style={mutedStyle}>{points} invested</div>
                          </div>
                          <Stepper
                            canMinus={points > lockedFloor && points > usedWords}
                            canPlus={progression.free_points > 0}
                            onMinus={() => act('adjust_school', { school_id: id, delta: -1 })}
                            onPlus={() => act('adjust_school', { school_id: id, delta: 1 })}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div style={{ width: '75%', overflowY: 'auto', borderLeft: '1px solid #273142', paddingLeft: '10px' }}>
                <div style={{ ...panelStyle, marginBottom: '10px' }}>
                  <div style={{ color: '#f1f3f7', fontSize: '18px', fontWeight: 800 }}>{school_names[activeSchool] || 'School'}</div>
                  <div style={descStyle}>{schoolDescription(activeSchool)}</div>
                </div>
                <div style={gridStyle}>
                  {schoolWords.map((word) => (
                    <WordRow
                      key={word.id}
                      word={word}
                      knownCount={known_word_counts[word.id] || 0}
                      available={canLearn(word)}
                      committed={Boolean(progression.committed)}
                      dirty={Boolean(progression.dirty)}
                      canReassign={Boolean(progression.can_reassign)}
                      act={act}
                    />
                  ))}
                  {!schoolWords.length && <div style={mutedStyle}>No words in this school.</div>}
                </div>
              </div>
            </div>
          )}

          {tab === 'forms' && (
            <div style={bodyStyle}>
              <div style={formGridStyle}>
                {formWords
                  .slice()
                  .sort((left, right) => (formOrder[left.id] || 99) - (formOrder[right.id] || 99))
                  .map((word) => {
                    const points = progression.form_points[word.id] || 0;
                    const required = form_unlocks[word.id] || word.learn_cost || 1;
                    const committedPoints = (progression.committed_form_points || {})[word.id] || 0;
                    const lockedFloor = progression.can_reassign ? 0 : committedPoints;
                    return (
                      <FormCard
                        key={word.id}
                        word={word}
                        name={form_names[word.id] || word.name}
                        points={points}
                        required={required}
                        rank={formRank(word.id)}
                        canMinus={canLowerForm(word.id, lockedFloor)}
                        canPlus={canRaiseForm(word.id)}
                        act={act}
                      />
                    );
                  })}
              </div>
              <div style={comboSectionStyle}>
                <div style={sectionTitleStyle}>Combinations</div>
                {formCombos.map((combo) => {
                  const open = combo.forms.every((formId) => formRank(formId) > 0);
                  return <ComboCard key={combo.id} combo={combo} open={open} formNames={form_names} />;
                })}
              </div>
            </div>
          )}

          {tab === 'presets' && (
            <div style={{ ...bodyStyle, display: 'flex', minHeight: 0 }}>
              <div style={{ width: '360px', borderRight: '1px solid #273142', paddingRight: '10px', overflowY: 'auto' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  {roleOrder.map((roleId) => (
                    <button
                      key={roleId}
                      type="button"
                      onClick={() => setRole(roleId)}
                      style={buttonStyle(role === roleId ? '#8fa6d8' : '#394455')}
                    >
                      {roleNames[roleId]}
                    </button>
                  ))}
                </div>
                <select value={schoolFilter} onChange={(event: ChangeEvent<HTMLSelectElement>) => setSchoolFilter(event.currentTarget.value)} style={selectStyle}>
                  <option value="all">All schools</option>
                  {schoolEntries.map(([id, name]) => (
                    <option key={id} value={id}>
                      {name} ({progression.school_points[id] || 0})
                    </option>
                  ))}
                </select>
                <div style={wordListStyle}>
                  {visibleWords.map((word) => (
                    <WordPicker
                      key={word.id}
                      word={word}
                      knownCount={known_word_counts[word.id] || 0}
                      schoolNames={school_names}
                      act={act}
                    />
                  ))}
                  {!visibleWords.length && <div style={mutedStyle}>No known words in this category.</div>}
                </div>
              </div>

              <div style={{ flex: 1, paddingLeft: '10px', overflowY: 'auto' }}>
                <FormulaDetails preview={preview} slotsUsed={presets.length} slotsTotal={formulaSlotLimit} maxMana={data.max_mana || data.draft_validation?.max_mana || 0} />
                <div style={{ ...panelStyle, marginBottom: '10px' }}>
                  <div style={rowStyle}>
                    <div>
                      <div style={titleStyle}>Current Formulas</div>
                    </div>
                    <button
                      type="button"
                      disabled={!draftValid}
                      onClick={() => act('create_formula_scroll', { name: effectivePresetName })}
                      style={buttonStyle(draftValid ? '#8fa6d8' : '#303744')}
                    >
                      Scribe Current
                    </button>
                  </div>
                  <Requirements validation={data.draft_validation} />
                </div>
                <div style={titleStyle}>Formula Sequence</div>
                <div style={sequenceStyle}>
                  {draft_parts.map((part, index) => (
                    <div key={`${part.name}-${index}-${part.indexes.join('-')}`} style={partGroupStyle}>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                        {part.words.map((wordId, wordIndex) => (
                          <button
                            key={`${wordId}-${part.indexes[wordIndex]}`}
                            type="button"
                            onClick={() => act('remove_word', { index: part.indexes[wordIndex] })}
                            style={wordTokenStyle}
                          >
                            {byId.get(wordId)?.name || wordId}
                          </button>
                        ))}
                      </div>
                    </div>
                  ))}
                  {!draft_words.length && <div style={mutedStyle}>Choose words from the left.</div>}
                </div>

                <div style={{ display: 'flex', gap: '8px', marginTop: '12px', alignItems: 'center' }}>
                  <input
                    value={presetName}
                    onChange={(event: ChangeEvent<HTMLInputElement>) => setPresetName(event.currentTarget.value)}
                    placeholder="Preset name"
                    style={inputStyle}
                  />
                  <button
                    type="button"
                    disabled={!canSaveFormula}
                    onClick={() => act('save_preset', { name: effectivePresetName })}
                    style={buttonStyle(canSaveFormula ? '#426f55' : '#303744')}
                  >
                    {saveLabel}
                  </button>
                  <button type="button" onClick={() => act('clear_formula')} style={buttonStyle('#5f6f89')}>
                    Clear
                  </button>
                </div>

                <div style={{ ...wordListStyle, marginTop: '12px' }}>
                  {presets.map((preset, index) => (
                    <div key={`${preset.name}-${index}`} style={panelStyle}>
                      <div style={rowStyle}>
                        <div>
                          <div style={titleStyle}>{preset.name}</div>
                          <div style={mutedStyle}>{preset.summary}</div>
                          <div style={tagLineStyle}>
                            Mana {preset.mana_cost} | Time {preset.cast_time} | Arcane {preset.arcane_required || 0}
                          </div>
                        </div>
                        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                          <button type="button" onClick={() => act('load_preset', { index: index + 1 })} style={buttonStyle('#5f6f89')}>
                            Load
                          </button>
                          <button
                            type="button"
                            disabled={!draftValid}
                            onClick={() => act('update_preset', { index: index + 1 })}
                            style={buttonStyle(draftValid ? '#756142' : '#303744')}
                          >
                            Update
                          </button>
                          <button type="button" onClick={() => act('delete_preset', { index: index + 1 })} style={buttonStyle('#76505a')}>
                            Unlearn
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                  {!presets.length && <div style={mutedStyle}>No current formulas.</div>}
                </div>
              </div>
            </div>
          )}

          {tab === 'library' && (
            <div style={{ ...bodyStyle, display: 'grid', gridTemplateColumns: '360px minmax(0, 1fr)', gap: '10px', minHeight: 0 }}>
              <div style={{ overflowY: 'auto' }}>
                <FormulaDetails preview={preview} slotsUsed={presets.length} slotsTotal={formulaSlotLimit} maxMana={data.max_mana || data.draft_validation?.max_mana || 0} />
                <div style={panelStyle}>
                  <div style={titleStyle}>Current Draft JSON</div>
                  <textarea readOnly value={data.draft_export_json || ''} style={textareaStyle} />
                  <Requirements validation={data.draft_validation} />
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginTop: '8px' }}>
                    <button type="button" onClick={() => act('create_formula_scroll', { name: presetName || 'Formula Scroll' })} style={buttonStyle('#8fa6d8')}>
                      Create Scroll
                    </button>
                    <button type="button" onClick={() => act('read_formula_scroll')} style={buttonStyle('#5f6f89')}>
                      Read Held Scroll
                    </button>
                  </div>
                </div>

                <div style={{ ...panelStyle, marginTop: '10px' }}>
                  <div style={titleStyle}>Import JSON</div>
                  <textarea value={importJson} onChange={(event: ChangeEvent<HTMLTextAreaElement>) => setImportJson(event.currentTarget.value)} style={textareaStyle} />
                  <button type="button" onClick={() => act('import_formula', { json: importJson })} style={buttonStyle('#426f55')}>
                    Import
                  </button>
                </div>
              </div>

              <div style={{ overflowY: 'auto' }}>
                <div style={titleStyle}>Saved Formula Library</div>
                <div style={mutedStyle}>No availability filter. Entries can be loaded even if the current build cannot cast them yet.</div>
                <div style={wordListStyle}>
                  {presets.map((preset, index) => (
                    <div key={`${preset.name}-${index}`} style={panelStyle}>
                      <div style={rowStyle}>
                        <div>
                          <div style={titleStyle}>{preset.name}</div>
                          <div style={mutedStyle}>{preset.summary}</div>
                          <div style={tagLineStyle}>
                            Mana {preset.mana_cost} | Time {preset.cast_time} | Complexity {preset.complexity} | Arcane {preset.arcane_required || 0} | Reading {preset.reading_required || 0}
                          </div>
                          {!!preset.requirements?.length && <div style={descStyle}>Requires: {preset.requirements.join(', ')}</div>}
                        </div>
                        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                          <button type="button" onClick={() => act('load_preset', { index: index + 1 })} style={buttonStyle('#5f6f89')}>
                            Load
                          </button>
                          <button type="button" onClick={() => act('rename_preset', { index: index + 1 })} style={buttonStyle('#5f6f89')}>
                            Rename
                          </button>
                          <button type="button" onClick={() => act('delete_preset', { index: index + 1 })} style={buttonStyle('#76505a')}>
                            Delete
                          </button>
                        </div>
                      </div>
                      <textarea readOnly value={preset.export_json || ''} style={textareaStyle} />
                    </div>
                  ))}
                  {!presets.length && <div style={mutedStyle}>No saved formulas.</div>}
                </div>
              </div>
            </div>
          )}
        </div>
      </Window.Content>
    </Window>
  );
};

const formOrder: Record<string, number> = {
  orb: 1,
  touch: 2,
  instant: 3,
  spiral: 4,
  summon: 5,
  beam: 6,
  wave: 7,
  nova: 8,
  guidance: 9,
  aura: 10,
};

const formRepeatEffects: Record<string, string> = {
  orb: 'Each repeat adds another full-strength orb to the same part.',
  touch: 'Hits harder than baseline because it is melee range; repeated Touch shortens spoken time.',
  instant: 'Each repeat increases maximum target distance by one tile; the point impact uses slightly reduced payload force.',
  spiral: 'Each repeat adds another evenly spaced arm. Each contact uses half of the payload force.',
  summon: 'Repeats add more created payloads or strengthen supported summoned effects; direct impact uses reduced payload force.',
  beam: 'Each repeat adds one tile of range and reduces per-tile damage fade by 1%; beam impact starts below baseline.',
  wave: 'Repeats increase moving line reach. Each wave contact uses reduced payload force to preserve DPS over travel.',
  nova: 'Repeats increase circular pulse radius. Each hit uses reduced payload force because the shape is broad.',
  guidance: 'Repeats increase maximum line distance and improve guided placement; line hits are slightly below baseline.',
  aura: 'Repeats extend the duration of the self-centered working; Aura itself is defensive and does not add direct impact.',
};

const formCombos = [
  {
    id: 'combo_seeker',
    name: 'Seeker',
    forms: ['orb', 'wave'],
    does: 'Turns an orb delivery into a seeking moving projectile behavior.',
    repeat: 'Uses the lower rank of Orb and Wave. Extra ranks add more seeking projectiles and keep the wave-carried orb behavior.',
    recipe: 'Assembled by placing Orb and Wave in the same formula part.',
  },
  {
    id: 'combo_breath',
    name: 'Breath',
    forms: ['touch', 'nova'],
    does: 'Projects a short aggressive area from the caster instead of a simple adjacent touch.',
    repeat: 'Uses the lower rank of Touch and Nova. Extra ranks widen the breathing pattern and add more pulses.',
    recipe: 'Assembled by placing Touch and Nova in the same formula part.',
  },
  {
    id: 'combo_fall',
    name: 'Fall',
    forms: ['instant', 'beam'],
    does: 'Turns a point designation and a direct line into a delayed falling strike.',
    repeat: 'Uses the lower rank of Moment and Beam. Extra ranks add more falling strikes with staged delays.',
    recipe: 'Assembled by placing Moment and Beam in the same formula part.',
  },
  {
    id: 'combo_cloak',
    name: 'Cloak',
    forms: ['spiral', 'aura'],
    does: 'Carries an aggressive rotating effect around the caster.',
    repeat: 'Uses the lower rank of Spiral and Aura. Extra ranks add more rotating arms and extend the carried effect.',
    recipe: 'Assembled by placing Spiral and Aura in the same formula part.',
  },
  {
    id: 'combo_rune',
    name: 'Rune',
    forms: ['summon', 'guidance'],
    does: 'Creates a guided placed trigger instead of a simple summoned payload.',
    repeat: 'Uses the lower rank of Summon and Guidance. Extra ranks create more guided rune placements.',
    recipe: 'Assembled by placing Summon and Guidance in the same formula part.',
  },
];

const FormCard = (props: {
  word: Word;
  name: string;
  points: number;
  required: number;
  rank: number;
  canMinus: boolean;
  canPlus: boolean;
  act: (action: string, params?: Record<string, unknown>) => void;
}) => (
  <div style={formCardStyle(props.rank > 0)}>
    <div style={rowStyle}>
      <div>
        <div style={titleStyle}>{props.name}</div>
        <div style={mutedStyle}>{props.points}/{props.required} invested | {props.rank > 0 ? 'Open' : 'Locked'}</div>
      </div>
      <Stepper
        canMinus={props.canMinus}
        canPlus={props.canPlus}
        onMinus={() => props.act('adjust_form', { form_id: props.word.id, delta: -1 })}
        onPlus={() => props.act('adjust_form', { form_id: props.word.id, delta: 1 })}
      />
    </div>
    <InfoLine label="Effect" text={props.word.desc} />
    <InfoLine label="Amplify" text={formRepeatEffects[props.word.id] || 'Repeats improve this form according to its delivery role.'} />
  </div>
);

const ComboCard = (props: { combo: (typeof formCombos)[number]; open: boolean; formNames: Record<string, string> }) => (
  <div style={comboCardStyle(props.open)}>
    <div style={rowStyle}>
      <div>
        <div style={titleStyle}>{props.combo.name}</div>
        <div style={mutedStyle}>{props.combo.forms.map((formId) => props.formNames[formId] || formId).join(' + ')} | {props.open ? 'Open' : 'Locked'}</div>
      </div>
    </div>
    <div style={comboDescriptionGridStyle}>
      <InfoLine label="Effect" text={props.combo.does} />
      <InfoLine label="Amplify" text={props.combo.repeat} />
      <InfoLine label="Combination" text={props.combo.recipe} />
    </div>
  </div>
);

const InfoLine = (props: { label: string; text: string }) => (
  <div style={infoLineStyle}>
    <span style={infoLabelStyle}>{props.label}: </span>
    <span style={descInlineStyle}>{props.text}</span>
  </div>
);

const Requirements = (props: { validation?: Validation }) => (
  <div style={{ marginTop: '8px' }}>
    <div style={{ color: props.validation?.valid ? '#9ee6a0' : '#c58b75', fontSize: '12px', fontWeight: 800 }}>
      {props.validation?.valid ? 'Status: ready' : 'Status: incomplete'}
    </div>
    {!!props.validation?.requirements?.length && <div style={descStyle}>Requires: {props.validation.requirements.join(', ')}</div>}
    {!!props.validation?.missing?.length && <div style={descStyle}>Missing: {props.validation.missing.join(', ')}</div>}
  </div>
);

const Header = (props: { progression: Progression }) => (
  <div style={{ padding: '10px 12px', borderBottom: '1px solid #273142' }}>
    <div style={rowStyle}>
      <div>
        <div style={{ color: '#f1f3f7', fontSize: '18px', fontWeight: 800 }}>Formula Spellcraft</div>
        <div style={{ color: props.progression.dirty ? '#9ee6a0' : '#9fb1ce', fontSize: '12px' }}>
          {props.progression.dirty ? 'Knowledge has unsaved changes.' : 'Knowledge is saved.'}
        </div>
      </div>
      <div style={{ display: 'flex', gap: '6px' }}>
        <Stat label="Free" value={props.progression.free_points} />
        <Stat label="Spent" value={props.progression.spent_points} />
        <Stat label="Total" value={props.progression.total_points} />
      </div>
    </div>
  </div>
);

const FormulaDetails = (props: { preview?: Preview; slotsUsed?: number; slotsTotal?: number; maxMana?: number }) => (
  <div style={{ ...panelStyle, marginBottom: '10px' }}>
    <div style={rowStyle}>
      <div>
        <div style={{ color: '#f1f3f7', fontSize: '18px', fontWeight: 800 }}>{props.preview?.text || 'Empty formula'}</div>
        <div style={{ color: props.preview?.can_resolve ? '#9ee6a0' : '#c58b75', fontSize: '12px' }}>
          {props.preview?.can_resolve ? 'Formula can resolve' : 'Needs at least one form'}
        </div>
      </div>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(10, 1fr)', gap: '6px', marginTop: '8px' }}>
      <Stat label="Mana" value={props.preview?.mana_cost || 0} />
      <Stat label="Max mana" value={props.maxMana || 0} />
      <Stat label="Slots" value={`${props.slotsUsed || 0}/${props.slotsTotal || 0}`} />
      <Stat label="Time" value={props.preview?.cast_time || 0} />
      <Stat label="Complex" value={props.preview?.complexity || 0} />
      <Stat label="Risk" value={props.preview?.interrupt_chance || props.preview?.instability || 0} />
      <Stat label="Power" value={props.preview?.power || 0} />
      <Stat label="Radius" value={props.preview?.radius || 0} />
      <Stat label="Range" value={props.preview?.range || 0} />
      <Stat label="Shots" value={props.preview?.projectile_count || 0} />
    </div>
  </div>
);

const WordRow = (props: { word: Word; knownCount: number; available: boolean; committed: boolean; dirty: boolean; canReassign: boolean; act: (action: string, params?: Record<string, unknown>) => void }) => (
  <div style={wordCardStyle(props.available)}>
    <div style={rowStyle}>
      <div>
        <div style={titleStyle}>{props.word.name}</div>
        <div style={mutedStyle}>
          Need {props.word.unlock_level} | Rank {props.knownCount}
        </div>
      </div>
      <div style={{ display: 'flex', gap: '6px' }}>
        <button
          type="button"
          disabled={!props.canReassign || props.knownCount <= 0}
          onClick={() => props.act('forget_word', { word_id: props.word.id })}
          style={buttonStyle(props.canReassign && props.knownCount > 0 ? '#756142' : '#303744')}
        >
          -
        </button>
        <button
          type="button"
          disabled={!props.committed || props.dirty || !props.available}
          onClick={() => props.act('learn_word', { word_id: props.word.id })}
          style={buttonStyle(props.committed && !props.dirty && props.available ? '#426f55' : '#303744')}
        >
          +
        </button>
      </div>
    </div>
    <div style={descStyle}>{props.word.desc}</div>
    <div style={tagLineStyle}>{props.word.phrases?.[0] || ''}</div>
  </div>
);

const WordPicker = (props: { word: Word; knownCount: number; schoolNames: Record<string, string>; act: (action: string, params?: Record<string, unknown>) => void }) => (
  <button type="button" onClick={() => props.act('add_word', { word_id: props.word.id })} style={wordPickerStyle}>
    <div style={rowStyle}>
      <div>
        <div style={titleStyle}>{props.word.name}</div>
        <div style={mutedStyle}>
          {props.schoolNames[props.word.school_id || ''] || roleNames[props.word.role] || 'Modifiers'}
          {props.word.school_id ? ` | Rank ${props.knownCount}` : ''}
        </div>
      </div>
    </div>
    <div style={descStyle}>{props.word.desc}</div>
  </button>
);

const Stepper = (props: { canMinus: boolean; canPlus: boolean; onMinus: () => void; onPlus: () => void }) => (
  <div style={{ display: 'flex', gap: '6px' }}>
    <button type="button" disabled={!props.canMinus} onClick={props.onMinus} style={buttonStyle(props.canMinus ? '#5f6f89' : '#303744')}>-</button>
    <button type="button" disabled={!props.canPlus} onClick={props.onPlus} style={buttonStyle(props.canPlus ? '#8fa6d8' : '#303744')}>+</button>
  </div>
);

const TabButton = (props: { active: boolean; label: string; onClick: () => void }) => (
  <button type="button" onClick={props.onClick} style={buttonStyle(props.active ? '#8fa6d8' : '#394455')}>
    {props.label}
  </button>
);

const Stat = (props: { label: string; value: number }) => (
  <div style={{ border: '1px solid #273142', background: '#141a23', padding: '6px', minWidth: '54px' }}>
    <div style={{ color: '#8ea0bd', fontSize: '10px' }}>{props.label}</div>
    <div style={{ color: '#f1f3f7', fontWeight: 800 }}>{props.value}</div>
  </div>
);

const rootStyle = { display: 'flex', flexDirection: 'column', height: '100%', background: '#0f131a' } as const;
const bodyStyle = { flex: 1, minHeight: 0, padding: '10px', overflowY: 'auto' } as const;
const tabsStyle = { display: 'flex', gap: '8px', padding: '8px 10px', borderBottom: '1px solid #273142' } as const;
const gridStyle = { display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '8px' } as const;
const formGridStyle = { display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '8px' } as const;
const comboSectionStyle = { marginTop: '14px', display: 'flex', flexDirection: 'column', gap: '8px' } as const;
const sectionTitleStyle = { color: '#f1f3f7', fontWeight: 900, fontSize: '14px', letterSpacing: 0 } as const;
const rowStyle = { display: 'flex', justifyContent: 'space-between', gap: '8px', alignItems: 'flex-start' } as const;
const panelStyle = { border: '1px solid #273142', background: '#141a23', borderRadius: '4px', padding: '8px' } as const;
const titleStyle = { color: '#f1f3f7', fontWeight: 800 } as const;
const mutedStyle = { color: '#9fb1ce', fontSize: '11px' } as const;
const descStyle = { color: '#c5d2e8', fontSize: '12px', marginTop: '4px' } as const;
const infoLineStyle = { marginTop: '6px', fontSize: '12px', lineHeight: 1.35 } as const;
const infoLabelStyle = { color: '#8fa6d8', fontSize: '11px', fontWeight: 900 } as const;
const descInlineStyle = { color: '#c5d2e8', fontSize: '12px' } as const;
const comboDescriptionGridStyle = { display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '10px', marginTop: '8px' } as const;
const tagLineStyle = { color: '#7f8ca3', fontSize: '11px', marginTop: '4px' } as const;
const wordListStyle = { marginTop: '10px', display: 'flex', flexDirection: 'column', gap: '6px' } as const;
const sequenceStyle = { display: 'flex', flexWrap: 'wrap', gap: '8px', alignItems: 'center', marginTop: '8px' } as const;
const partGroupStyle = { minWidth: '110px', background: '#111722', color: '#f1f3f7', border: '1px solid #4f6f9f', borderRadius: '4px', padding: '6px' } as const;
const wordTokenStyle = { minWidth: '64px', minHeight: '30px', background: '#171d27', color: '#f1f3f7', border: '1px solid #34445e', borderRadius: '4px', fontWeight: 800, cursor: 'pointer' } as const;
const selectStyle = { width: '100%', marginTop: '8px', background: '#171d27', color: '#dce6f5', border: '1px solid #394455', padding: '6px' } as const;
const inputStyle = { flex: 1, background: '#171d27', color: '#dce6f5', border: '1px solid #394455', padding: '6px' } as const;
const textareaStyle = { width: '100%', minHeight: '92px', marginTop: '8px', background: '#0f131a', color: '#dce6f5', border: '1px solid #394455', padding: '6px', resize: 'vertical' as const, fontFamily: 'monospace', fontSize: '11px' } as const;

const buttonStyle = (color: string) => ({
  background: '#171d27',
  color: '#eaf0fb',
  border: `1px solid ${color}`,
  borderRadius: '4px',
  padding: '6px 8px',
  fontWeight: 800,
  cursor: 'pointer',
} as const);

const wordCardStyle = (usable: boolean) => ({
  border: `1px solid ${usable ? '#34445e' : '#252c38'}`,
  background: usable ? '#141a23' : '#10141b',
  borderRadius: '4px',
  padding: '8px',
  opacity: usable ? 1 : 0.62,
} as const);

const wordPickerStyle = {
  border: '1px solid #34445e',
  background: '#141a23',
  color: '#dce6f5',
  borderRadius: '4px',
  padding: '8px',
  textAlign: 'left' as const,
  cursor: 'pointer',
} as const;

const formCardStyle = (open: boolean) => ({
  border: `1px solid ${open ? '#8fa6d8' : '#273142'}`,
  background: open ? '#162033' : '#141a23',
  borderRadius: '4px',
  padding: '8px',
  opacity: open ? 1 : 0.72,
} as const);

const comboCardStyle = (open: boolean) => ({
  border: `1px solid ${open ? '#9ee6a0' : '#273142'}`,
  background: open ? '#14231a' : '#141a23',
  borderRadius: '4px',
  padding: '8px',
  opacity: open ? 1 : 0.72,
} as const);

const schoolTabStyle = (active: boolean) => ({
  border: `1px solid ${active ? '#8fa6d8' : '#273142'}`,
  background: active ? '#192335' : '#141a23',
  borderRadius: '4px',
  padding: '8px',
  cursor: 'pointer',
} as const);

const schoolDescription = (schoolId: string) => {
  const descriptions: Record<string, string> = {
    general_magic: 'Neuromancy holds mind-work and broad utility: omen reading, mental messages, mindlinks, and the Mind effect. Mind confuses hostile targets for two seconds per spoken word.',
    pyromancy: 'Pyromancy adds heat, direct fire damage, and burning. Fire is raw damage; Burning is the separate ignition word and handles fire stacks.',
    cryomancy: 'Cryomancy adds cold damage and frostbite. Frostbite builds frost stacks, damps flames, and supports freezing zones through Summon + Frost + Frostbite or preservation through Summon + Frost.',
    fulgurmancy: 'Fulgurmancy adds lightning damage and discharge. Lightning is direct shock; Discharge adds brief electrical disruption and smoke marks through Summon.',
    geomancy: 'Geomancy adds stone force and dirt. Stone is blunt force and brick material; Dirt slows struck targets for 3 seconds plus 3 per extra word, shapes temporary muddy ground through Summon, and hardens into an earthen wall when Summon is paired with Existence.',
    kinesis: 'Kinesis changes motion: force, repulse, gravity, pull, and cleanse. Repulse is not damage; its strength is distance and control.',
    displacement: 'Displacement moves or anchors space: shift, phase, holdfast, and fixed teleport runes. A teleport rune is permanent, remembered by creation or examination, and moves the clicking mage plus nearby bodies to the remembered rune.',
    augmentation: 'Augmentation improves the caster through Aura, stats, darkvision, nondetection, and fixed high-grade support formulas.',
    curses: 'Curses weaken and disrupt: stat curses, blindness, silence, reveal, and fixed counter-guidance effects.',
    artifice_warding: 'Artifice shapes metal and blades. Iron damages armor layers and forms protections through Aura/Cloak; Blade plants spinning blade fields.',
    biomancy: 'Biomancy shapes living matter. Creation produces short-lived man-eater plant matter and combines with elements for higher summons.',
    necromancy: 'Necromancy is restricted test magic. Bone hits harder than pure arcane force and supports necromantic fixed formulas.',
    chronomancy: 'Chronomancy is restricted Origin magic.',
  };
  return descriptions[schoolId] || 'A formula school. Invest points to unlock words, then save knowledge to make them usable.';
};

function asArray<T>(value: T[] | Record<string, T> | undefined): T[] {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return Object.values(value);
}
