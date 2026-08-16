/**
 * The small, in-memory audit trail shown by the management UI.
 *
 * This is intentionally an application concern: it does not mirror HID
 * frames, persistence records, or pairing material. The bridge operation
 * itself remains the source of truth; these records only explain the latest
 * user-visible result.
 */

export const OPERATION_HISTORY_LIMIT = 20;

export type OperationContext = 'physical' | 'simulation';
export type OperationOutcome = 'success' | 'pending' | 'failure';

export type OperationKind =
  | 'bridge-connect'
  | 'bridge-disconnect'
  | 'diagnostics-refresh'
  | 'profile-save'
  | 'keymap-read'
  | 'keymap-save'
  | 'source-keymap-read'
  | 'source-keymap-save'
  | 'pairing-window'
  | 'pairing-method'
  | 'bond-rename'
  | 'bond-delete'
  | 'simulation-demo';

export interface OperationInput {
  kind: OperationKind;
  target: string;
  context: OperationContext;
  outcome: OperationOutcome;
  detail: string;
}

export interface OperationRecord extends OperationInput {
  sequence: number;
}

export function createOperationRecord(sequence: number, input: OperationInput): OperationRecord {
  return { sequence, ...input };
}

export function appendOperation(
  history: readonly OperationRecord[],
  record: OperationRecord,
): OperationRecord[] {
  return [record, ...history].slice(0, OPERATION_HISTORY_LIMIT);
}
