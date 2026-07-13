/** @jsxImportSource ../../../tgui/node_modules/react */
import { useBackend } from '../../../tgui/packages/tgui/backend';
import { Window } from '../../../tgui/packages/tgui/layouts';

type Word = {
  id: string;
  name: string;
  desc: string;
  role: string;
  mana_cost: number;
  cast_time: number;
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
  projectile_count: number;
  tags: Record<string, number>;
};

type Data = {
  words?: Word[];
  available_words?: Word[];
  preview?: Preview;
};

export const FormulaCast = () => {
  const { act, data } = useBackend<Data>();
  const words = asArray<Word>(data.words);
  const availableWords = asArray<Word>(data.available_words);
  const preview = data.preview;

  return (
    <Window width={620} height={520} title="Formula Craft">
      <Window.Content>
        <div style={rootStyle}>
          <div style={headerStyle}>
            <div>
              <div style={titleStyle}>{preview?.text || 'Empty formula'}</div>
              <div style={{ color: preview?.can_resolve ? '#9ee6a0' : '#d6977f', fontSize: '12px' }}>
                {preview?.can_resolve ? 'Ready to pronounce' : 'Needs at least one form'}
              </div>
            </div>
            <button type="button" disabled={!words.length} onClick={() => act('clear_formula')} style={buttonStyle(words.length ? '#5f6f89' : '#303744')}>
              Clear
            </button>
          </div>

          <div style={statGridStyle}>
            <Stat label="Mana" value={preview?.mana_cost || 0} />
            <Stat label="Time" value={preview?.cast_time || 0} />
            <Stat label="Complex" value={preview?.complexity || 0} />
            <Stat label="Risk" value={preview?.instability || 0} />
            <Stat label="Power" value={preview?.power || 0} />
            <Stat label="Radius" value={preview?.radius || 0} />
            <Stat label="Range" value={preview?.range || 0} />
            <Stat label="Shots" value={preview?.projectile_count || 0} />
          </div>

          <div style={bodyStyle}>
            <div style={availableStyle}>
              <div style={sectionTitleStyle}>Known Words</div>
              {availableWords.map((word) => (
                <button key={word.id} type="button" onClick={() => act('add_word', { word_id: word.id })} style={wordButtonStyle}>
                  <div style={wordTitleStyle}>{word.name}</div>
                  <div style={mutedStyle}>{word.role} | Mana {word.mana_cost} | Time {word.cast_time}</div>
                  <div style={descStyle}>{word.desc}</div>
                </button>
              ))}
              {!availableWords.length && <div style={mutedStyle}>No known words.</div>}
            </div>

            <div style={sequenceStyle}>
              <div style={sectionTitleStyle}>Formula Sequence</div>
              {words.map((word, index) => (
                <button key={`${word.id}-${index}`} type="button" onClick={() => act('remove_word', { index: index + 1 })} style={wordStyle}>
                  <div style={rowStyle}>
                    <div>
                      <div style={wordTitleStyle}>{index + 1}. {word.name}</div>
                      <div style={mutedStyle}>{word.role} | Mana {word.mana_cost} | Time {word.cast_time}</div>
                    </div>
                  </div>
                  <div style={descStyle}>{word.desc}</div>
                  <div style={phraseStyle}>{word.phrases?.[0] || 'Arcanum.'}</div>
                </button>
              ))}
              {!words.length && <div style={mutedStyle}>Click known words on the left.</div>}
            </div>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};

const Stat = (props: { label: string; value: number }) => (
  <div style={statStyle}>
    <div style={{ color: '#8ea0bd', fontSize: '10px' }}>{props.label}</div>
    <div style={{ color: '#f1f3f7', fontWeight: 800 }}>{props.value}</div>
  </div>
);

const rootStyle = { display: 'flex', flexDirection: 'column', height: '100%', background: '#0f131a', color: '#dce6f5' };
const headerStyle = { display: 'flex', justifyContent: 'space-between', gap: '10px', alignItems: 'flex-start', padding: '12px', borderBottom: '1px solid #273142' };
const titleStyle = { color: '#f1f3f7', fontSize: '18px', fontWeight: 800 };
const wordTitleStyle = { color: '#f1f3f7', fontWeight: 800 };
const sectionTitleStyle = { color: '#f1f3f7', fontWeight: 800, marginBottom: '8px' };
const mutedStyle = { color: '#9fb1ce', fontSize: '11px' };
const descStyle = { color: '#c5d2e8', fontSize: '12px', marginTop: '5px' };
const phraseStyle = { color: '#d8c27a', fontSize: '13px', marginTop: '6px', fontWeight: 800 };
const rowStyle = { display: 'flex', justifyContent: 'space-between', gap: '8px', alignItems: 'flex-start' };
const statGridStyle = { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '6px', padding: '10px 12px', borderBottom: '1px solid #273142' };
const bodyStyle = { flex: 1, minHeight: 0, display: 'flex' };
const availableStyle = { width: '280px', borderRight: '1px solid #273142', padding: '10px 12px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '8px' };
const sequenceStyle = { flex: 1, minHeight: 0, overflowY: 'auto', padding: '10px 12px', display: 'flex', flexDirection: 'column', gap: '8px' };
const statStyle = { border: '1px solid #273142', background: '#141a23', padding: '6px', minWidth: '54px' };
const wordStyle = { border: '1px solid #273142', background: '#141a23', color: '#dce6f5', borderRadius: '4px', padding: '8px', textAlign: 'left' as const, cursor: 'pointer' };
const wordButtonStyle = { border: '1px solid #34445e', background: '#141a23', color: '#dce6f5', borderRadius: '4px', padding: '8px', textAlign: 'left' as const, cursor: 'pointer' };

const buttonStyle = (color: string) => ({
  background: '#171d27',
  color: '#eaf0fb',
  border: `1px solid ${color}`,
  borderRadius: '4px',
  padding: '7px 16px',
  fontWeight: 800,
  cursor: 'pointer',
});

const asArray = <T,>(value: T[] | Record<string, T> | undefined): T[] => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return Object.values(value);
};
