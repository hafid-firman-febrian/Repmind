import type { AiModelKey } from "../_shared/ai_models.ts";
import type {
  CatalogExercise,
  CoachPlan,
  CoachPlanExercise,
} from "../_shared/training.ts";
import { proposePlanChangeSchema } from "./tool.ts";
import type { PlanProposal, ProposalChange } from "./types.ts";

const MAX_REPORTED_ERRORS = 10;
const MAX_SUMMARY_LENGTH = 200;

export type ProposalResult =
  | { ok: true; proposal: PlanProposal; userConfirmed: boolean }
  | { ok: false; errors: string[] };

export interface ProposalContext {
  plan: CoachPlan;
  catalog: CatalogExercise[];
  aiModel: AiModelKey;
}

export function buildProposal(
  args: unknown,
  context: ProposalContext,
): ProposalResult {
  const parsed = proposePlanChangeSchema.safeParse(args);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.slice(0, MAX_REPORTED_ERRORS).map((issue) =>
        `${issue.path.join(".") || "arguments"}: ${issue.message}`
      ),
    };
  }
  const { day_number: dayNumber, changes, user_confirmed } = parsed.data;
  const day = context.plan.days.find((d) => d.dayNumber === dayNumber);
  if (day === undefined) {
    const valid = context.plan.days.map((d) => d.dayNumber).join(", ");
    return {
      ok: false,
      errors: [`Day ${dayNumber} is not in the plan; use one of: ${valid}.`],
    };
  }

  const errors = checkChanges(changes, day.exercises, context.catalog);
  if (errors.length > 0) {
    return { ok: false, errors: errors.slice(0, MAX_REPORTED_ERRORS) };
  }

  const catalogById = new Map(context.catalog.map((e) => [e.id, e]));
  const planned = new Map(day.exercises.map((e) => [e.exerciseId, e]));
  const proposalChanges: ProposalChange[] = changes.map((change) => ({
    from_exercise_id: change.from_exercise_id,
    to_exercise_id: change.to_exercise_id,
    to_exercise_name: catalogById.get(change.to_exercise_id)!.name,
    sets: change.sets,
    reps: change.reps,
    rest_seconds: change.rest_seconds,
  }));
  const summary = summarize(
    proposalChanges,
    day.title,
    (id) => planned.get(id)!.name,
  );
  return {
    ok: true,
    userConfirmed: user_confirmed === true,
    proposal: {
      based_on_plan_id: context.plan.id,
      ai_model: context.aiModel,
      day_number: dayNumber,
      summary,
      changes: proposalChanges,
    },
  };
}

function checkChanges(
  changes: {
    from_exercise_id: string;
    to_exercise_id: string;
    sets: number;
    reps: string;
    rest_seconds: number;
  }[],
  dayExercises: CoachPlanExercise[],
  catalog: CatalogExercise[],
): string[] {
  const errors: string[] = [];
  const planned = new Map(dayExercises.map((e) => [e.exerciseId, e]));
  const catalogIds = new Set(catalog.map((e) => e.id));
  const fromIds = changes.map((c) => c.from_exercise_id);
  const seenFrom = new Set<string>();
  const seenTo = new Set<string>();

  changes.forEach((change, index) => {
    const label = `changes.${index}`;
    const { from_exercise_id: from, to_exercise_id: to } = change;
    const current = planned.get(from);

    if (seenFrom.has(from)) {
      errors.push(
        `${label}: ${from} is changed more than once; use one change per exercise.`,
      );
    }
    seenFrom.add(from);

    if (current === undefined) {
      errors.push(
        `${label}: from_exercise_id ${from} is not in day; its exercises are ${
          dayExercises.map((e) => e.exerciseId).join(", ")
        }.`,
      );
    }
    if (!catalogIds.has(to)) {
      errors.push(
        `${label}: to_exercise_id ${to} is not in the catalog; use an exercise_id from the catalog.`,
      );
    }

    if (to !== from) {
      const chained = fromIds.some((other, otherIndex) =>
        otherIndex !== index && other === to
      );
      if (chained) {
        errors.push(
          `${label}: ${to} is also changed by another change; chained changes are not allowed, replace each exercise directly.`,
        );
      } else if (planned.has(to)) {
        errors.push(
          `${label}: to_exercise_id ${to} is already in day; an exercise cannot appear twice.`,
        );
      }
    }

    if (seenTo.has(to)) {
      errors.push(
        `${label}: ${to} is used by more than one change; an exercise cannot appear twice.`,
      );
    }
    seenTo.add(to);

    if (
      current !== undefined && from === to && change.sets === current.sets &&
      change.reps === current.reps &&
      change.rest_seconds === current.restSeconds
    ) {
      errors.push(
        `${label}: ${from} would stay exactly as it is, so this change does nothing; change its sets, reps or rest, or replace it.`,
      );
    }
  });
  return errors;
}

function summarize(
  changes: ProposalChange[],
  dayTitle: string,
  plannedName: (exerciseId: string) => string,
): string {
  if (changes.length === 1) {
    const [change] = changes;
    const single = change.from_exercise_id === change.to_exercise_id
      ? `Update ${change.to_exercise_name}`
      : `Swap ${
        plannedName(change.from_exercise_id)
      } for ${change.to_exercise_name}`;
    if (single.length <= MAX_SUMMARY_LENGTH) return single;
  }
  return `Coach updated ${dayTitle}`.slice(0, MAX_SUMMARY_LENGTH).trimEnd();
}

export function namesUnfiledChange(
  text: string,
  plan: CoachPlan,
  catalog: CatalogExercise[],
): boolean {
  const dayNames = plan.days.map((day) =>
    new Set(day.exercises.map((e) => e.name.toLowerCase()))
  );
  const names = new Set<string>();
  for (const exercise of catalog) names.add(exercise.name.toLowerCase());
  for (const day of dayNames) for (const name of day) names.add(name);
  const longestFirst = [...names].filter((name) => name.length > 0)
    .sort((a, b) => b.length - a.length);

  let remaining = text.toLowerCase();
  const found: string[] = [];
  for (const name of longestFirst) {
    const at = remaining.indexOf(name);
    if (at === -1) continue;
    found.push(name);
    remaining = remaining.replaceAll(name, " ".repeat(name.length));
  }
  if (found.length === 0) return false;
  return !dayNames.some((day) => found.every((name) => day.has(name)));
}
