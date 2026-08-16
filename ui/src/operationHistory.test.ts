import { describe, expect, it } from 'vitest';
import {
  OPERATION_HISTORY_LIMIT,
  appendOperation,
  createOperationRecord,
  type OperationRecord,
} from './operationHistory';

function record(sequence: number, detail = `detail ${sequence}`): OperationRecord {
  return createOperationRecord(sequence, {
    kind: 'keymap-read',
    target: 'slot 0',
    context: 'simulation',
    outcome: 'success',
    detail,
  });
}

describe('operation history', () => {
  it('prepends new records without mutating the previous history', () => {
    const previous = [record(1)];

    const next = appendOperation(previous, record(2));

    expect(next.map((item) => item.sequence)).toEqual([2, 1]);
    expect(previous.map((item) => item.sequence)).toEqual([1]);
  });

  it('keeps only the most recent twenty records', () => {
    const previous = Array.from({ length: OPERATION_HISTORY_LIMIT }, (_, index) => record(index + 1));

    const next = appendOperation(previous, record(OPERATION_HISTORY_LIMIT + 1));

    expect(next).toHaveLength(OPERATION_HISTORY_LIMIT);
    expect(next[0].sequence).toBe(OPERATION_HISTORY_LIMIT + 1);
    expect(next.at(-1)?.sequence).toBe(OPERATION_HISTORY_LIMIT - 1);
  });

  it('retains pending and failure outcomes as distinct records', () => {
    const pending = createOperationRecord(1, {
      kind: 'profile-save',
      target: 'slot 0',
      context: 'physical',
      outcome: 'pending',
      detail: '無線が静かになるまで保留中',
    });
    const failure = createOperationRecord(2, {
      kind: 'bond-delete',
      target: 'slot 0',
      context: 'physical',
      outcome: 'failure',
      detail: '接続を確認して再試行してください',
    });

    expect(pending.outcome).toBe('pending');
    expect(failure.outcome).toBe('failure');
    expect(appendOperation([pending], failure)).toEqual([failure, pending]);
  });
});
