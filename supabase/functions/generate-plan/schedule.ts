const WEEKDAYS_BY_DAY_COUNT: Record<number, number[]> = {
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 6],
  5: [1, 2, 3, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
};

const WEEKDAY_NAMES = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

export function weekdaysFor(daysPerWeek: number): number[] {
  const weekdays = WEEKDAYS_BY_DAY_COUNT[daysPerWeek];
  if (!weekdays) {
    throw new RangeError(
      `daysPerWeek must be between 2 and 6, got ${daysPerWeek}`,
    );
  }
  return [...weekdays];
}

export function weekdayName(weekday: number): string {
  return WEEKDAY_NAMES[weekday - 1];
}
