const WEEKDAYS_BY_DAY_COUNT: Record<number, number[]> = {
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 6],
  5: [1, 2, 3, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
};

export function weekdaysFor(daysPerWeek: number): number[] {
  const weekdays = WEEKDAYS_BY_DAY_COUNT[daysPerWeek];
  if (!weekdays) {
    throw new RangeError(
      `daysPerWeek must be between 2 and 6, got ${daysPerWeek}`,
    );
  }
  return [...weekdays];
}

export { weekdayName } from "../_shared/training.ts";
