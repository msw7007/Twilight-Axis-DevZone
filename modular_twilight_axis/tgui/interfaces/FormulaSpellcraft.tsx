/** @jsxImportSource ../../../tgui/node_modules/react */
import { useMemo, useState } from '../../../tgui/node_modules/react';

import { useBackend } from '../../../tgui/packages/tgui/backend';
import { Window } from '../../../tgui/packages/tgui/layouts';

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

type Data = {
  words?: Word[];
  draft_words?: string[];
  preview?: Preview;
  known_words?: string[];
  known_word_counts?: Record<string, number>;
  progression?: Progression;
  school_names?: Record<string, string>;
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
  const known_word_counts = data.known_word_counts || {};
  const presets = asArray<Preset>(data.presets);
  const preview = data.preview;
  const school_names = data.school_names || {};
  const form_names = data.form_names || {};
  const form_unlocks = data.form_unlocks || {};

  const [tab, setTab] = useState<'schools' | 'forms' | 'presets'>('schools');
  const [role, setRole] = useState('form');
  const [school, setSchool] = useState('all');
  const [presetName, setPresetName] = useState('');

  const byId = useMemo(() => new Map(words.map((word) => [word.id, word])), [words]);
  const schoolEntries = Object.entries(school_names).filter(([id]) => id !== 'arcane');
  const formWords = words.filter((word) => word.role === 'form');

  const canLearn = (word: Word) => {
    if (word.role === 'form') {
      return (progression.form_points[word.id] || 0) >= (form_unlocks[word.id] || 1);
    }
    return !!word.school_id && (progression.school_points[word.school_id] || 0) >= word.unlock_level;
  };

  const canUseCommitted = (word: Word) => {
    if (!progression.committed || progression.dirty) return false;
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
    if (school === 'all') return true;
    return word.school_id === school;
  });

  return (
    <Window width={1040} height={680} title="Formula Spellcraft">
      <Window.Content fitted>
        <div style={rootStyle}>
          <Header progression={progression} />
          <div style={tabsStyle}>
            <TabButton active={tab === 'schools'} onClick={() => setTab('schools')} label="Schools" />
            <TabButton active={tab === 'forms'} onClick={() => setTab('forms')} label="Forms" />
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
            <div style={bodyStyle}>
              <div style={gridStyle}>
                {schoolEntries.map(([id, name]) => {
                  const points = progression.school_points[id] || 0;
                  const committedPoints = (progression.committed_school_points || {})[id] || 0;
                  const lockedFloor = progression.can_reassign ? 0 : committedPoints;
                  const usedWords = words
                    .filter((word) => word.school_id === id)
                    .reduce((total, word) => total + (known_word_counts[word.id] || 0), 0);
                  return (
                    <div key={id} style={panelStyle}>
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
                      <div style={wordListStyle}>
                        {words
                          .filter((word) => word.school_id === id && word.role !== 'form')
                          .map((word) => (
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
                      </div>
                    </div>
                  );
                })}
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
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '6px' }}>
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
                <select value={school} onChange={(event) => setSchool(event.currentTarget.value)} style={selectStyle}>
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
                  {draft_words.map((wordId, index) => (
                    <button key={`${wordId}-${index}`} type="button" onClick={() => act('remove_word', { index: index + 1 })} style={tokenStyle}>
                      {byId.get(wordId)?.name || wordId}
                    </button>
                  ))}
                  {!draft_words.length && <div style={mutedStyle}>Choose words from the left.</div>}
                </div>

                <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                  <input
                    value={presetName}
                    onChange={(event) => setPresetName(event.currentTarget.value)}
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
      <Stat label="Risk" value={props.preview?.instability || 0} />
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

const rootStyle = { display: 'flex', flexDirection: 'column', height: '100%', background: '#0f131a' };
const bodyStyle = { flex: 1, minHeight: 0, padding: '10px', overflowY: 'auto' };
const tabsStyle = { display: 'flex', gap: '8px', padding: '8px 10px', borderBottom: '1px solid #273142' };
const gridStyle = { display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '8px' };
const rowStyle = { display: 'flex', justifyContent: 'space-between', gap: '8px', alignItems: 'flex-start' };
const panelStyle = { border: '1px solid #273142', background: '#141a23', borderRadius: '4px', padding: '8px' };
const titleStyle = { color: '#f1f3f7', fontWeight: 800 };
const mutedStyle = { color: '#9fb1ce', fontSize: '11px' };
const descStyle = { color: '#c5d2e8', fontSize: '12px', marginTop: '4px' };
const tagLineStyle = { color: '#7f8ca3', fontSize: '11px', marginTop: '4px' };
const wordListStyle = { marginTop: '10px', display: 'flex', flexDirection: 'column', gap: '6px' };
const sequenceStyle = { display: 'flex', flexWrap: 'wrap', gap: '8px', alignItems: 'center', marginTop: '8px' };
const tokenStyle = { minWidth: '84px', minHeight: '44px', background: '#171d27', color: '#f1f3f7', border: '1px solid #4f6f9f', borderRadius: '4px', fontWeight: 800 };
const selectStyle = { width: '100%', marginTop: '8px', background: '#171d27', color: '#dce6f5', border: '1px solid #394455', padding: '6px' };
const inputStyle = { flex: 1, background: '#171d27', color: '#dce6f5', border: '1px solid #394455', padding: '6px' };

const buttonStyle = (color: string) => ({
  background: '#171d27',
  color: '#eaf0fb',
  border: `1px solid ${color}`,
  borderRadius: '4px',
  padding: '6px 8px',
  fontWeight: 800,
  cursor: 'pointer',
});

const wordCardStyle = (usable: boolean) => ({
  border: `1px solid ${usable ? '#34445e' : '#252c38'}`,
  background: usable ? '#141a23' : '#10141b',
  borderRadius: '4px',
  padding: '8px',
  opacity: usable ? 1 : 0.62,
});

const wordPickerStyle = {
  border: '1px solid #34445e',
  background: '#141a23',
  color: '#dce6f5',
  borderRadius: '4px',
  padding: '8px',
  textAlign: 'left' as const,
  cursor: 'pointer',
};

const asArray = <T,>(value: T[] | Record<string, T> | undefined): T[] => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return Object.values(value);
};
