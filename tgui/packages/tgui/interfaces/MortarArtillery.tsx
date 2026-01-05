import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, Divider, Input, Section, Stack } from 'tgui-core/components';

type Data = {
  aim_azimuth: number;
  powder_measures: number;
  powder_max: number;
  wear: number;
  safe_max: number;
  shell_name: string | null;
  broken: boolean;
};

export const MortarArtillery = () => {
  const { act, data } = useBackend<Data>();

  const [azimuthInput, setAzimuthInput] = useState(String(data.aim_azimuth ?? 0));
  const [powderInput, setPowderInput] = useState('1');

  const powderRoom = Math.max(0, (data.powder_max ?? 0) - (data.powder_measures ?? 0));

  const parsedAzimuth = (() => {
    const n = parseInt(azimuthInput, 10);
    if (Number.isNaN(n)) return null;
    // normalize 0..359
    return ((n % 360) + 360) % 360;
  })();

  const parsedPowder = (() => {
    const n = parseInt(powderInput, 10);
    if (Number.isNaN(n)) return null;
    return Math.max(0, n);
  })();

  const commitAzimuth = () => {
    if (parsedAzimuth === null) return;
    act('set_azimuth', { value: parsedAzimuth });
  };

  const offloadPowder = () => {
    if (parsedPowder === null) return;
    act('offload_powder', { amount: parsedPowder });
  };

  return (
    <Window title="Mortar Control" width={460} height={360}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Status">
              <Stack vertical>
                <Stack.Item>
                  <Box>
                    <b>Shell:</b> {data.shell_name || 'None'}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box>
                    <b>Powder:</b> {data.powder_measures}/{data.powder_max}{' '}
                    <Box as="span" color="label">
                      (safe max: {data.safe_max})
                    </Box>
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box>
                    <b>Azimuth:</b> {data.aim_azimuth}°
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box>
                    <b>Wear:</b> {data.wear}%
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box>
                    <b>State:</b> {data.broken ? 'Broken' : 'Operational'}
                  </Box>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Divider />

          <Stack.Item>
            <Section title="Controls">
              <Stack vertical>
                <Stack.Item>
                  <Box mb={0.5} color="label">
                    Azimuth (0–359)
                  </Box>
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
                        value={azimuthInput}
                        onChange={setAzimuthInput}
                        onEnter={() => commitAzimuth()}
                        placeholder="e.g. 270"
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        disabled={data.broken || parsedAzimuth === null}
                        onClick={() => commitAzimuth()}
                      >
                        Set
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Box mb={0.5} color="label">
                    Offload powder from nearest keg
                  </Box>
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
                        value={powderInput}
                        onChange={setPowderInput}
                        onEnter={() => offloadPowder()}
                        placeholder="Measures (e.g. 3)"
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        disabled={data.broken || powderRoom <= 0 || parsedPowder === null}
                        onClick={() => offloadPowder()}
                      >
                        Offload
                      </Button>
                    </Stack.Item>
                  </Stack>

                  <Box mt={0.5} color="label" italic>
                    Capacity left: {powderRoom}
                  </Box>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Button
                    color="red"
                    disabled={data.broken}
                    onClick={() => act('fire')}
                    fluid
                  >
                    Fire
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
