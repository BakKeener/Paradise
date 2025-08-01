import { Box, Button, LabeledList, ProgressBar, Section, Slider, Stack } from 'tgui-core/components';
import { formatPower } from 'tgui-core/format';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// Common power multiplier
const POWER_MUL = 1e3;

type SmesData = {
  capacityPercent: number;
  capacity: number;
  charge: number;
  inputAttempt: number;
  inputting: number;
  inputLevel: number;
  inputLevelMax: number;
  inputAvailable: number;
  outputPowernet: number;
  outputAttempt: number;
  outputting: number;
  outputLevel: number;
  outputLevelMax: number;
  outputUsed: number;
};

export const Smes = (props) => {
  const { act, data } = useBackend<SmesData>();
  const {
    capacityPercent,
    capacity,
    charge,
    inputAttempt,
    inputting,
    inputLevel,
    inputLevelMax,
    inputAvailable,
    outputPowernet,
    outputAttempt,
    outputting,
    outputLevel,
    outputLevelMax,
    outputUsed,
  } = data;
  const inputState = (capacityPercent >= 100 && 'good') || (inputting && 'average') || 'bad';
  const outputState = (outputting && 'good') || (charge > 0 && 'average') || 'bad';
  return (
    <Window width={340} height={360}>
      <Window.Content>
        <Stack fill vertical>
          <Section title="Stored Energy">
            <ProgressBar
              value={capacityPercent * 0.01}
              ranges={{
                good: [0.5, Infinity],
                average: [0.15, 0.5],
                bad: [-Infinity, 0.15],
              }}
            />
          </Section>
          <Section title="Input">
            <LabeledList>
              <LabeledList.Item
                label="Charge Mode"
                buttons={
                  <Button
                    icon={inputAttempt ? 'sync-alt' : 'times'}
                    selected={inputAttempt}
                    onClick={() => act('tryinput')}
                  >
                    {inputAttempt ? 'Auto' : 'Off'}
                  </Button>
                }
              >
                <Box color={inputState}>
                  {(capacityPercent >= 100 && 'Fully Charged') || (inputting && 'Charging') || 'Not Charging'}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Target Input">
                <Stack width="100%">
                  <Stack.Item>
                    <Button
                      icon="fast-backward"
                      disabled={inputLevel === 0}
                      onClick={() =>
                        act('input', {
                          target: 'min',
                        })
                      }
                    />
                    <Button
                      icon="backward"
                      disabled={inputLevel === 0}
                      onClick={() =>
                        act('input', {
                          adjust: -10000,
                        })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Slider
                      value={inputLevel / POWER_MUL}
                      fillValue={inputAvailable / POWER_MUL}
                      minValue={0}
                      maxValue={inputLevelMax / POWER_MUL}
                      step={5}
                      stepPixelSize={4}
                      format={(value) => formatPower(value * POWER_MUL, 1)}
                      onChange={(e, value) =>
                        act('input', {
                          target: value * POWER_MUL,
                        })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="forward"
                      disabled={inputLevel === inputLevelMax}
                      onClick={() =>
                        act('input', {
                          adjust: 10000,
                        })
                      }
                    />
                    <Button
                      icon="fast-forward"
                      disabled={inputLevel === inputLevelMax}
                      onClick={() =>
                        act('input', {
                          target: 'max',
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
              <LabeledList.Item label="Available">{formatPower(inputAvailable)}</LabeledList.Item>
            </LabeledList>
          </Section>
          <Section fill title="Output">
            <LabeledList>
              <LabeledList.Item
                label="Output Mode"
                buttons={
                  <Button
                    icon={outputAttempt ? 'power-off' : 'times'}
                    selected={outputAttempt}
                    onClick={() => act('tryoutput')}
                  >
                    {outputAttempt ? 'On' : 'Off'}
                  </Button>
                }
              >
                <Box color={outputState}>
                  {outputPowernet
                    ? outputting
                      ? 'Sending'
                      : charge > 0
                        ? 'Not Sending'
                        : 'No Charge'
                    : 'Not Connected'}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Target Output">
                <Stack width="100%">
                  <Stack.Item>
                    <Button
                      icon="fast-backward"
                      disabled={outputLevel === 0}
                      onClick={() =>
                        act('output', {
                          target: 'min',
                        })
                      }
                    />
                    <Button
                      icon="backward"
                      disabled={outputLevel === 0}
                      onClick={() =>
                        act('output', {
                          adjust: -10000,
                        })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Slider
                      value={outputLevel / POWER_MUL}
                      minValue={0}
                      maxValue={outputLevelMax / POWER_MUL}
                      step={5}
                      stepPixelSize={4}
                      format={(value) => formatPower(value * POWER_MUL, 1)}
                      onChange={(e, value) =>
                        act('output', {
                          target: value * POWER_MUL,
                        })
                      }
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="forward"
                      disabled={outputLevel === outputLevelMax}
                      onClick={() =>
                        act('output', {
                          adjust: 10000,
                        })
                      }
                    />
                    <Button
                      icon="fast-forward"
                      disabled={outputLevel === outputLevelMax}
                      onClick={() =>
                        act('output', {
                          target: 'max',
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
              <LabeledList.Item label="Outputting">{formatPower(outputUsed)}</LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
