
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Section,
  Stack,
} from 'tgui-core/components';

type Entry = {
  text: string;
};

type Data = {
  pq_text: string;
  pq_color: string;
  pq_value: number;
  commends: number;
  round_points: number;
  rounds_survived: number;
  entries: Entry[];
};

export const PreferencesPQ = () => {
  const { data } = useBackend<Data>();

  return (
    <Window title="Player Quality" width={420} height={520}>
      <Window.Content scrollable>
        <Section title="Overview">
          <Box bold textColor={data.pq_color || '#ffffff'}>
            {data.pq_text}
          </Box>
          <Box>PQ Value: {data.pq_value}</Box>
        </Section>

        <Section title="Stats" mt={1}>
          <Box>Commends: {data.commends}</Box>
          <Box>Round Points: {data.round_points}</Box>
          <Box>Rounds Survived: {data.rounds_survived}</Box>
        </Section>

        <Section title="History" mt={1}>
          <Stack vertical>
            {data.entries?.length ? data.entries.map((e, i) => (
              <Stack.Item key={i}>
                <Box>{e.text}</Box>
              </Stack.Item>
            )) : (
              <Box>No records</Box>
            )}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
