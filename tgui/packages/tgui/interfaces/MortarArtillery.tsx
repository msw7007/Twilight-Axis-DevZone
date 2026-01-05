import { useMemo, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, Divider, Input, Section, Stack } from 'tgui-core/components';

type CalcResult = {
  ok?: boolean;
  notes?: string;

  range_tiles?: number;
  target_azimuth?: number;
  aim_azimuth?: number;
  powder_needed?: number;

  drift_tiles?: number;
  scatter?: number;

  // optional extras
  elevation?: number;
  powder_potency?: number;
};

type Data = {
  aim_azimuth: number;
  aim_elevation: number;
  elev_min: number;
  elev_max: number;

  powder_ounces: number;
  powder_max: number;
  safe_max: number;
  wear: number;

  powder_potency_avg: number;

  shell_name: string | null;
  has_shell?: boolean;
  broken: boolean;

  // calculator stored inputs
  calc_target_lat: number;
  calc_target_lon: number;

  calc_wind_dir: number;
  calc_wind_strength: number;
  calc_density: number;
  calc_humidity: number;

  calc_shell_mass: number;
  calc_shell_drift_mult: number;
  calc_shell_base_scatter: number;

  calc_powder_potency: number;
  calc_elevation: number;

  calc_result: CalcResult | null;
};

const clampAzimuth = (n: number) => ((n % 360) + 360) % 360;

const parseIntOrNull = (s: string) => {
  const n = parseInt(s, 10);
  return Number.isNaN(n) ? null : n;
};

const parseFloatOrNull = (s: string) => {
  const n = Number(s);
  return Number.isFinite(n) ? n : null;
};

const StatusPanel = (props: {
  data: Data;
  onOffloadShell: () => void;
  onOffloadPowder: () => void;
  onRemoveBarrel: () => void;
}) => {
  const { data, onOffloadShell, onOffloadPowder, onRemoveBarrel } = props;

  const hasPowder = (data.powder_ounces ?? 0) > 0;
  const hasShell = !!data.shell_name;

  return (
    <Section title="Status" fill>
      <Stack vertical>
        <Stack.Item>
          <Box>
            <b>State:</b> {data.broken ? 'Broken' : 'Operational'}
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box>
            <b>Shell:</b> {data.shell_name || 'None'}
          </Box>
          <Box mt={0.5}>
            <Button
              icon="eject"
              disabled={data.broken || !hasShell}
              onClick={onOffloadShell}
              tooltip="Unload the currently loaded shell onto the ground"
            >
              Unload shell
            </Button>
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box>
            <b>Powder:</b> {data.powder_ounces}/{data.powder_max} oz{' '}
            <Box as="span" color="label">
              (safe max: {data.safe_max})
            </Box>
          </Box>
          <Box mt={0.25}>
            <b>Powder quality (avg):</b>{' '}
            {Number.isFinite(data.powder_potency_avg) ? data.powder_potency_avg.toFixed(2) : '1.00'}
          </Box>
          <Box mt={0.5}>
            <Button
              icon="trash"
              color="transparent"
              disabled={data.broken || !hasPowder}
              onClick={onOffloadPowder}
              tooltip="Dump all loaded powder onto the ground under you"
            >
              Offload powder
            </Button>
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box>
            <b>Wear:</b> {data.wear}%
          </Box>
        </Stack.Item>

        <Divider />

        <Stack.Item>
          <Button
            icon="wrench"
            color="average"
            disabled={data.broken || hasPowder || hasShell}
            onClick={onRemoveBarrel}
            tooltip={hasPowder || hasShell ? 'Unload shell and powder first.' : 'Remove the barrel to replace it.'}
            fluid
          >
            Remove barrel
          </Button>
        </Stack.Item>

        <Stack.Item>
          <Box color="label" italic>
            Barrel removal is blocked while shell/powder is loaded.
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const CalcResultView = (props: { result: CalcResult | null }) => {
  const { result } = props;
  if (!result) {
    return (
      <Box color="label" italic>
        No solution yet.
      </Box>
    );
  }

  if (!result.ok) {
    return (
      <Box color="bad">
        {result.notes ? result.notes : 'Calculation failed.'}
      </Box>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Box>
          <b>Suggested aim:</b> {result.aim_azimuth}°
        </Box>
        <Box>
          <b>Suggested powder:</b> {result.powder_needed} oz
        </Box>
      </Stack.Item>

      <Stack.Item>
        <Box color="label">
          Range: {result.range_tiles} tiles • Drift: {result.drift_tiles} • Scatter: {result.scatter}
        </Box>
        {(result.elevation !== undefined || result.powder_potency !== undefined) && (
          <Box color="label">
            Elevation: {result.elevation ?? '-'}° • Powder quality used: {result.powder_potency !== undefined ? result.powder_potency.toFixed(2) : '-'}
          </Box>
        )}
      </Stack.Item>
    </Stack>
  );
};

const CalculatorPanel = (props: { disabled: boolean; act: any; data: Data }) => {
  const { disabled, act, data } = props;

  // Compact: no self coords. Mortar coords are taken from turf in backend.
  const [targetLat, setTargetLat] = useState(String(data.calc_target_lat ?? 0));
  const [targetLon, setTargetLon] = useState(String(data.calc_target_lon ?? 0));

  const [mass, setMass] = useState(String(data.calc_shell_mass ?? 10.0));

  const [windDir, setWindDir] = useState(String(data.calc_wind_dir ?? 0));
  const [windStr, setWindStr] = useState(String(data.calc_wind_strength ?? 0));
  const [density, setDensity] = useState(String(data.calc_density ?? 1.0));
  const [humidity, setHumidity] = useState(String(data.calc_humidity ?? 0.0));

  const [powderPot, setPowderPot] = useState(String(data.calc_powder_potency ?? (data.powder_potency_avg ?? 1.0)));
  const [elevation, setElevation] = useState(String(data.calc_elevation ?? data.aim_elevation ?? 45));

  const parsed = useMemo(() => {
    const tlat = parseFloatOrNull(targetLat);
    const tlon = parseFloatOrNull(targetLon);

    const m = parseFloatOrNull(mass);

    const wdir0 = parseIntOrNull(windDir);
    const wstr0 = parseIntOrNull(windStr);
    const dens0 = parseFloatOrNull(density);
    const hum0 = parseFloatOrNull(humidity);

    const pot0 = parseFloatOrNull(powderPot);
    const elev0 = parseIntOrNull(elevation);

    return {
      tlat: tlat,
      tlon: tlon,

      mass: m,

      wdir: wdir0 === null ? null : clampAzimuth(wdir0),
      wstr: wstr0,
      dens: dens0,
      hum: hum0,

      pot: pot0,
      elev: elev0,
    };
  }, [targetLat, targetLon, mass, windDir, windStr, density, humidity, powderPot, elevation]);

  const canCalc =
    parsed.tlat !== null &&
    parsed.tlon !== null &&
    parsed.mass !== null &&
    parsed.wdir !== null &&
    parsed.wstr !== null &&
    parsed.dens !== null &&
    parsed.hum !== null &&
    parsed.pot !== null &&
    parsed.elev !== null;

  const doCalc = () => {
    if (!canCalc) return;

    act('calc_solution', {
      target_lat: parsed.tlat,
      target_lon: parsed.tlon,

      wind_dir: parsed.wdir,
      wind_strength: parsed.wstr,
      air_density: parsed.dens,
      humidity: parsed.hum,

      shell_mass: parsed.mass,

      powder_potency: parsed.pot,
      elevation: parsed.elev,
    });
  };

  return (
    <Section title="Calculator" fill>
      <Stack vertical>
        <Stack.Item>
          <Box color="label" italic>
            Enter your instrument readings. The calculator only suggests values — you set them manually.
          </Box>
        </Stack.Item>

        <Divider />

        <Stack.Item>
          <Box color="label" mb={0.25}>Target coordinates</Box>
          <Stack>
            <Stack.Item grow>
              <Input fluid value={targetLat} onChange={setTargetLat} placeholder="φ target" />
            </Stack.Item>
            <Stack.Item grow>
              <Input fluid value={targetLon} onChange={setTargetLon} placeholder="λ target" />
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Box color="label" mb={0.25}>Shell & powder</Box>
          <Stack>
            <Stack.Item grow>
              <Input fluid value={mass} onChange={setMass} placeholder="Shell mass (e.g. 15.0)" />
            </Stack.Item>
            <Stack.Item grow>
              <Input
                fluid
                value={powderPot}
                onChange={setPowderPot}
                placeholder="Powder quality (e.g. 1.00)"
              />
            </Stack.Item>
            <Stack.Item basis="25%">
              <Input
                fluid
                value={elevation}
                onChange={setElevation}
                placeholder="Elevation°"
              />
            </Stack.Item>
          </Stack>
          <Box mt={0.25} color="label" italic>
            Hint: mortar powder avg is {Number.isFinite(data.powder_potency_avg) ? data.powder_potency_avg.toFixed(2) : '1.00'}.
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Box color="label" mb={0.25}>Weather</Box>
          <Stack>
            <Stack.Item basis="33%">
              <Input fluid value={windDir} onChange={setWindDir} placeholder="Wind dir°" />
            </Stack.Item>
            <Stack.Item basis="33%">
              <Input fluid value={windStr} onChange={setWindStr} placeholder="Wind str" />
            </Stack.Item>
            <Stack.Item basis="34%">
              <Input fluid value={density} onChange={setDensity} placeholder="Density (e.g. 1.05)" />
            </Stack.Item>
          </Stack>
          <Box mt={0.5} />
          <Input fluid value={humidity} onChange={setHumidity} placeholder="Humidity (0..1)" />
        </Stack.Item>

        <Stack.Item>
          <Button
            icon="calculator"
            disabled={disabled || !canCalc}
            onClick={doCalc}
            tooltip={!canCalc ? 'Fill in all inputs first.' : 'Compute azimuth and powder.'}
          >
            Calculate
          </Button>
        </Stack.Item>

        <Divider />

        <Stack.Item>
          <CalcResultView result={data.calc_result ?? null} />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

export const MortarArtillery = () => {
  const { act, data } = useBackend<Data>();

  const [azimuthInput, setAzimuthInput] = useState(String(data.aim_azimuth ?? 0));
  const [elevInput, setElevInput] = useState(String(data.aim_elevation ?? 45));

  const parsedAzimuth = useMemo(() => {
    const n = parseIntOrNull(azimuthInput);
    if (n === null) return null;
    return clampAzimuth(n);
  }, [azimuthInput]);

  const parsedElev = useMemo(() => {
    const n = parseIntOrNull(elevInput);
    if (n === null) return null;
    const lo = data.elev_min ?? 20;
    const hi = data.elev_max ?? 80;
    return Math.max(lo, Math.min(hi, n));
  }, [elevInput, data.elev_min, data.elev_max]);

  const setAzimuth = () => {
    if (parsedAzimuth === null) return;
    act('set_azimuth', { value: parsedAzimuth });
  };

  const setElevation = () => {
    if (parsedElev === null) return;
    act('set_elevation', { value: parsedElev });
  };

  const fire = () => act('fire');
  const offloadPowder = () => act('offload_powder');
  const offloadShell = () => act('offload_shell');
  const removeBarrel = () => act('remove_barrel');

  return (
    <Window title="Mortar Artillery" width={860} height={520}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Stack fill>
              <Stack.Item basis="40%">
                <StatusPanel
                  data={data}
                  onOffloadShell={offloadShell}
                  onOffloadPowder={offloadPowder}
                  onRemoveBarrel={removeBarrel}
                />
              </Stack.Item>

              <Stack.Item basis="60%">
                <CalculatorPanel disabled={data.broken} act={act} data={data} />
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Divider />

          <Stack.Item>
            <Section title="Fire Control">
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
                        onEnter={setAzimuth}
                        placeholder="e.g. 270"
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button disabled={data.broken || parsedAzimuth === null} onClick={setAzimuth}>
                        Set
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>

                <Stack.Item mt={0.5}>
                  <Box mb={0.5} color="label">
                    Elevation ({data.elev_min}–{data.elev_max})
                  </Box>
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
                        value={elevInput}
                        onChange={setElevInput}
                        onEnter={setElevation}
                        placeholder="e.g. 45"
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button disabled={data.broken || parsedElev === null} onClick={setElevation}>
                        Set
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Button color="red" icon="bullseye" disabled={data.broken} onClick={fire} fluid>
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
