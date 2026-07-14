/** @jsxRuntime classic */
/** @jsx React.createElement */
// @ts-ignore Modular tgui lives outside tgui/packages, so React is resolved from the main bundle.
import * as React from '../../../tgui/node_modules/react';
// @ts-ignore Modular tgui lives outside tgui/packages, so React is resolved from the main bundle.
import { useMemo, useState } from '../../../tgui/node_modules/react';

import { useBackend } from '../../../tgui/packages/tgui/backend';
import { Window } from '../../../tgui/packages/tgui/layouts';

declare global {
  namespace JSX {
    type Element = React.ReactElement;
    interface IntrinsicAttributes {
      key?: React.Key;
    }
    interface IntrinsicElements {
      [elemName: string]: any;
    }
  }
}

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
};

type DraftPart = {
  name: string;
  words: string[];
  indexes: number[];
};

type Data = {
  words?: Word[];
  draft_words?: string[];
  draft_parts?: DraftPart[];
  preview?: Preview;
  known_words?: string[];
  known_word_counts?: Record<string, number>;
  progression?: Progression;
  school_names?: Record<string, string>;
  school_access?: Record<string, boolean>;
  form_names?: Record<string, string>;
  form_unlocks?: Record<string, number>;
  presets?: Preset[];
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

  const [tab, setTab] = useState<'forms' | 'schools' | 'presets'>('forms');
  const [role, setRole] = useState('form');
  const [schoolFilter, setSchoolFilter] = useState('all');
  const [selectedSchool, setSelectedSchool] = useState('');
  const [presetName, setPresetName] = useState('');

  const byId = useMemo(() => new Map(words.map((word) => [word.id, word])), [words]);
  const schoolEntries = Object.entries(school_names).filter(([id]) => id !== 'arcane' && school_access[id] !== false);
  const activeSchool = selectedSchool && schoolEntries.some(([id]) => id === selectedSchool) ? selectedSchool : schoolEntries[0]?.[0] || '';
  const isPrebuilt = (word: Word) => word.tags?.includes('prebuilt_formula');
  const formWords = words.filter((word) => word.role === 'form' && !isPrebuilt(word));
  const schoolWords = words.filter((word) => word.school_id === activeSchool && word.role !== 'form');

  const canLearn = (word: Word) => {
    if (isPrebuilt(word)) {
      return !!word.school_id && (progression.school_points[word.school_id] || 0) >= word.unlock_level;
    }
    if (word.role === 'form') {
      return (progression.form_points[word.id] || 0) >= (form_unlocks[word.id] || 1);
    }
    return !!word.school_id && (progression.school_points[word.school_id] || 0) >= word.unlock_level;
  };

  const canUseCommitted = (word: Word) => {
    if (!progression.committed || progression.dirty) return false;
    if (isPrebuilt(word)) {
      return (known_word_counts[word.id] || 0) > 0;
    }
    if (word.role === 'form') {
      return ((progression.committed_form_points || {})[word.id] || 0) >= (form_unlocks[word.id] || 1);
    }
    if (!word.school_id) return true;
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

  return (
    <Window width={1040} height={680} title="Formula Spellcraft">
      <Window.Content fitted>
        <div style={rootStyle}>
          <Header progression={progression} />
          <div style={tabsStyle}>
            <TabButton active={tab === 'forms'} onClick={() => setTab('forms')} label="Forms" />
            <TabButton active={tab === 'schools'} onClick={() => setTab('schools')} label="Schools" />
            <TabButton active={tab === 'presets'} onClick={() => setTab('presets')} label="Precreation" />
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
                      usable={canUse(word)}
                      committed={Boolean(progression.committed)}
                      dirty={Boolean(progression.dirty)}
                      canReassign={Boolean(progression.can_reassign)}
                      schoolNames={school_names}
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
              <div style={gridStyle}>
                {formWords.map((word) => {
                  const points = progression.form_points[word.id] || 0;
                  const required = form_unlocks[word.id] || 1;
                  const committedPoints = (progression.committed_form_points || {})[word.id] || 0;
                  const lockedFloor = progression.can_reassign ? 0 : committedPoints;
                  return (
                    <div key={word.id} style={panelStyle}>
                      <div style={rowStyle}>
                        <div>
                          <div style={titleStyle}>{form_names[word.id] || word.name}</div>
                          <div style={mutedStyle}>
                            {points}/{required} invested | {points >= required ? 'Open' : 'Locked'}
                          </div>
                        </div>
                        <Stepper
                          canMinus={points > lockedFloor}
                          canPlus={progression.free_points > 0}
                          onMinus={() => act('adjust_form', { form_id: word.id, delta: -1 })}
                          onPlus={() => act('adjust_form', { form_id: word.id, delta: 1 })}
                        />
                      </div>
                      <div style={descStyle}>{word.desc}</div>
                      <div style={tagLineStyle}>{word.tags.join(', ')}</div>
                    </div>
                  );
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
                <select value={schoolFilter} onChange={(event: React.ChangeEvent<HTMLSelectElement>) => setSchoolFilter(event.currentTarget.value)} style={selectStyle}>
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
                <FormulaDetails preview={preview} />
                <div style={titleStyle}>Formula Sequence</div>
                <div style={sequenceStyle}>
                  {draft_parts.map((part, index) => (
                    <button key={`${part.name}-${index}-${part.indexes.join('-')}`} type="button" onClick={() => act('remove_part', { indexes: part.indexes })} style={tokenStyle}>
                      {part.name}
                      {part.words.length > 1 && (
                        <div style={tokenSubStyle}>
                          {part.words.map((wordId) => byId.get(wordId)?.name || wordId).join(' + ')}
                        </div>
                      )}
                    </button>
                  ))}
                  {!draft_words.length && <div style={mutedStyle}>Choose words from the left.</div>}
                </div>

                <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                  <input
                    value={presetName}
                    onChange={(event: React.ChangeEvent<HTMLInputElement>) => setPresetName(event.currentTarget.value)}
                    placeholder="Preset name"
                    style={inputStyle}
                  />
                  <button type="button" onClick={() => act('save_preset', { name: presetName })} style={buttonStyle('#426f55')}>
                    Save
                  </button>
                  <button type="button" onClick={() => act('clear_formula')} style={buttonStyle('#5f6f89')}>
                    Clear
                  </button>
                  <span style={mutedStyle}>Saved presets become spell buttons on the hotbar.</span>
                </div>

                <div style={{ marginTop: '16px', ...titleStyle }}>Presets</div>
                <div style={wordListStyle}>
                  {presets.map((preset, index) => (
                    <div key={`${preset.name}-${index}`} style={panelStyle}>
                      <div style={rowStyle}>
                        <div>
                          <div style={titleStyle}>{preset.name}</div>
                          <div style={mutedStyle}>{preset.summary}</div>
                          <div style={tagLineStyle}>
                            Mana {preset.mana_cost} | Time {preset.cast_time} | Complexity {preset.complexity}
                          </div>
                        </div>
                        <div style={{ display: 'flex', gap: '6px' }}>
                          <button type="button" onClick={() => act('load_preset', { index: index + 1 })} style={buttonStyle('#5f6f89')}>
                            Load
                          </button>
                          <button type="button" onClick={() => act('delete_preset', { index: index + 1 })} style={buttonStyle('#76505a')}>
                            X
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </Window.Content>
    </Window>
  );
};

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

const FormulaDetails = (props: { preview?: Preview }) => (
  <div style={{ ...panelStyle, marginBottom: '10px' }}>
    <div style={rowStyle}>
      <div>
        <div style={{ color: '#f1f3f7', fontSize: '18px', fontWeight: 800 }}>{props.preview?.text || 'Empty formula'}</div>
        <div style={{ color: props.preview?.can_resolve ? '#9ee6a0' : '#c58b75', fontSize: '12px' }}>
          {props.preview?.can_resolve ? 'Formula can resolve' : 'Needs at least one form'}
        </div>
      </div>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(8, 1fr)', gap: '6px', marginTop: '8px' }}>
      <Stat label="Mana" value={props.preview?.mana_cost || 0} />
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

const WordRow = (props: { word: Word; knownCount: number; available: boolean; usable: boolean; committed: boolean; dirty: boolean; canReassign: boolean; schoolNames: Record<string, string>; act: (action: string, params?: Record<string, unknown>) => void }) => (
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
    <WordCombos word={props.word} />
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
    <WordCombos word={props.word} compact />
  </button>
);

const WordCombos = (props: { word: Word; compact?: boolean }) => {
  const combos = wordCombos(props.word);
  if (!combos.length) {
    return null;
  }
  return (
    <div style={{ marginTop: '6px', display: 'flex', flexDirection: 'column', gap: '3px' } as const}>
      {!props.compact && <div style={comboTitleStyle}>Possible combos</div>}
      {combos.map((combo) => (
        <div key={combo} style={comboLineStyle}>{combo}</div>
      ))}
    </div>
  );
};

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
const rowStyle = { display: 'flex', justifyContent: 'space-between', gap: '8px', alignItems: 'flex-start' } as const;
const panelStyle = { border: '1px solid #273142', background: '#141a23', borderRadius: '4px', padding: '8px' } as const;
const titleStyle = { color: '#f1f3f7', fontWeight: 800 } as const;
const mutedStyle = { color: '#9fb1ce', fontSize: '11px' } as const;
const descStyle = { color: '#c5d2e8', fontSize: '12px', marginTop: '4px' } as const;
const tagLineStyle = { color: '#7f8ca3', fontSize: '11px', marginTop: '4px' } as const;
const wordListStyle = { marginTop: '10px', display: 'flex', flexDirection: 'column', gap: '6px' } as const;
const sequenceStyle = { display: 'flex', flexWrap: 'wrap', gap: '8px', alignItems: 'center', marginTop: '8px' } as const;
const tokenStyle = { minWidth: '84px', minHeight: '44px', background: '#171d27', color: '#f1f3f7', border: '1px solid #4f6f9f', borderRadius: '4px', fontWeight: 800 } as const;
const tokenSubStyle = { color: '#9fb1ce', fontSize: '10px', marginTop: '4px', fontWeight: 500 } as const;
const selectStyle = { width: '100%', marginTop: '8px', background: '#171d27', color: '#dce6f5', border: '1px solid #394455', padding: '6px' } as const;
const inputStyle = { flex: 1, background: '#171d27', color: '#dce6f5', border: '1px solid #394455', padding: '6px' } as const;

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

const schoolTabStyle = (active: boolean) => ({
  border: `1px solid ${active ? '#8fa6d8' : '#273142'}`,
  background: active ? '#192335' : '#141a23',
  borderRadius: '4px',
  padding: '8px',
  cursor: 'pointer',
} as const);

const comboTitleStyle = { color: '#8fa6d8', fontSize: '11px', fontWeight: 800, marginTop: '2px' } as const;
const comboLineStyle = { color: '#d6dfef', fontSize: '11px', paddingLeft: '6px', borderLeft: '2px solid #34445e' } as const;

const schoolDescription = (schoolId: string) => {
  const descriptions: Record<string, string> = {
    general_magic: 'Common magic holds mind-work and broad utility: omen reading, mental messages, mindlinks, and the Mind effect. Mind confuses hostile targets for two seconds per spoken word.',
    pyromancy: 'Pyromancy adds heat, direct fire damage, and burning. Fire is raw damage; Burning is the separate ignition word and handles fire stacks.',
    cryomancy: 'Cryomancy adds cold damage and frostbite. Frostbite builds frost stacks, damps flames, and supports freezing zones or preservation through Summon + Frost.',
    fulgurmancy: 'Fulgurmancy adds lightning damage and discharge. Lightning is direct shock; Discharge adds brief electrical disruption and smoke marks through Summon.',
    geomancy: 'Geomancy adds stone force and immobilizing earth. Stone is blunt force and brick material; Immobilize pins targets or raises a stone wall through Summon.',
    kinesis: 'Kinesis changes motion: force, repulse, gravity, pull, and cleanse. Repulse is not damage; its strength is distance and control.',
    displacement: 'Displacement moves or anchors space: shift, phase, and holdfast. It drives blink-like effects and counters movement by anchoring targets.',
    augmentation: 'Augmentation improves the caster through Aura, stats, darkvision, nondetection, and fixed high-grade support formulas.',
    curses: 'Curses weaken and disrupt: stat curses, blindness, silence, reveal, and fixed counter-guidance effects.',
    artifice_warding: 'Artifice shapes metal and blades. Iron damages armor layers and forms protections through Aura/Cloak; Blade plants spinning blade fields.',
    biomancy: 'Biomancy shapes living matter. Creation produces short-lived predatory plant matter and combines with elements for higher summons.',
    necromancy: 'Necromancy is restricted test magic. Bone hits harder than pure arcane force and supports necromantic fixed formulas.',
    chronomancy: 'Chronomancy is restricted Origin magic. Time creates temporal stress; Restoration is expensive healing/rewind work; Reversion is a fixed anchor formula.',
  };
  return descriptions[schoolId] || 'A formula school. Invest points to unlock words, then save knowledge to make them usable.';
};

const wordCombos = (word: Word) => {
  const tags = word.tags || [];
  const combos: string[] = [];
  const add = (line: string) => combos.push(line);
  if (word.id === 'fire') {
    add('Summon + Fire: temporary campfire.');
    add('Summon + Creation + Fire: fire primordial.');
    add('Orb + Fire: basic fireball.');
  }
  if (word.id === 'frost') {
    add('Summon + Frost: temporary chill on a food container.');
    add('Summon + Creation + Frost: water primordial.');
    add('Nova + Frost + Frostbite + Widen + Existence: frozen mist style zone.');
  }
  if (word.id === 'lightning') {
    add('Summon + Lightning: formula light.');
    add('Summon + Creation + Lightning: air primordial.');
    add('Moment + Lightning + Discharge + Widen + Recall: sundering lightning style strike.');
  }
  if (word.id === 'stone') {
    add('Summon + Stone: formula brick, one per Stone word.');
    add('Creation + Stone: Ratmouse, large rats in affected tiles.');
    add('Meteor + Stone + Widen: cataclysm-like impact.');
  }
  if (word.id === 'creation') {
    add('Summon + Creation: temporary man-eater plant.');
    add('Creation + Stone: Ratmouse.');
    add('Summon + Creation + Fire/Frost/Lightning: matching primordial.');
  }
  if (word.id === 'iron') {
    add('Aura + Iron: protective iron ring.');
    add('Cloak + Iron: dragon-hide protection.');
    add('Orb + Iron + Pierce: arcyne lance style armor-piercing hit.');
  }
  if (word.id === 'blade') {
    add('Summon + Blade: spinning blade field.');
    add('Cloak + Blade + Existence: blade dance style aura.');
    add('Wave + Blade: falling crescent style slash line.');
  }
  if (word.id === 'mind') {
    add('Moment + Mind: mind message style target contact.');
    add('Aura + Mind + Existence: mindlink style connection.');
    add('On hostile hit: confusion for two seconds per Mind word.');
  }
  if (word.id === 'time') {
    add('Time alone: temporal stress.');
    add('Time + Restoration: expensive temporal repair.');
    add('Reversion: fixed formula, not mixed into custom formulas.');
  }
  if (tags.includes('ignite')) add('Summon + Burning: brief burning tile.');
  if (tags.includes('frost_stack')) add('Summon + Frostbite: icy mark.');
  if (tags.includes('electrocute')) add('Summon + Discharge: smoke/discharge mark.');
  if (tags.includes('anchor_target')) add('Summon + Holdfast/Immobilize: wall or anchored target.');
  if (tags.includes('cleanse')) add('Wave/Nova + Cleanse: broad cleaning pulse.');
  if (tags.includes('push')) add('Nova + Repulse: outward shove around caster.');
  if (tags.includes('pull')) add('Touch/Moment + Pull: draw target toward impact.');
  if (tags.includes('curse_blindness')) add('Moment + Blindness: first target on tile is blinded.');
  if (tags.includes('silence')) add('Moment + Silence: suppresses speech.');
  return combos;
};

const asArray = <T,>(value: T[] | Record<string, T> | undefined): T[] => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return Object.values(value);
};
