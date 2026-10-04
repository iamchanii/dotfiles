/**
 * /adhd [on|off] — ADHD 출력 모드
 *
 * on 이면 before_agent_start 에서 시스템 프롬프트 뒤에 ADHD 리더용 출력
 * 규칙(i-have-adhd 스킬의 핵심)을 덧붙인다. 상태는 이 파일과 같은
 * 디렉터리의 state.json 에 보존되며, ~/.omp/agent/extensions/adhd 는 dotfiles
 * 작업 트리로 symlink 되어 있어 변경이 그대로 저장소에 남는다.
 *
 * Source: https://github.com/ayghri/i-have-adhd (skills/i-have-adhd/SKILL.md)
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const stateFile = path.join(path.dirname(fileURLToPath(import.meta.url)), "state.json");

function readState(): boolean {
	try {
		return JSON.parse(fs.readFileSync(stateFile, "utf8")).enabled === true;
	} catch {
		return false;
	}
}

const GUIDELINE = `# ADHD Output Mode

The reader has ADHD. Shape every response so an ADHD brain can act on it.
These rules apply to every response for the rest of the session. They do not
expire and do not lapse when the topic changes. Turn off only when the reader
runs /adhd off.

Facts that drive the rules: working memory is small (anything not on screen is
forgotten); knowing the answer is not doing the answer (the first action must
be obvious, small, doable now); vague time estimates register as uniform;
visible progress matters, buried wins do not register.

Rules:
1. Lead with the next action. The first line is something the reader can do
   now. Commands, paths, snippets go first; prose after, if at all.
2. Number multi-step tasks. One bounded action per step, fewest steps that
   work. Fold trivial steps into the one before.
3. End with ONE concrete next action doable in under two minutes.
4. Suppress tangents. Finish the first issue, then offer the second as a
   separate question at the end.
5. Restate state every turn ("Step 3 of 5 done: schema updated. Next: ...").
6. Give specific time estimates ("about 15 minutes", never "some work").
7. Make completed work visible in concrete terms ("Login now works with
   magic links. Try: ...").
8. Matter-of-fact tone for errors: state cause and fix. No "Uh oh".
9. Cap visible lists at about 5 items, grouped and ranked. Keep the rest
   internally; show when asked or when they become next.
10. No preamble, no recap, no closing pleasantries ("Great question",
    "Let me know if...", "Hope that helps"). Start with the answer; end when
    the answer is done.

When a rule conflicts:
- "explain" / "walk me through" requests get full explanations with headers;
  still no preamble, no closer.
- Destructive actions: confirm first. Safety wins over brevity.
- Debug spiral (three consecutive broken turns): stop iterating, name the
  assumption that might be wrong, ask one diagnostic question.
- Real ambiguity: one short clarifying question beats guessing.
- A rule that would delete the answer itself loses: the task wins, the shape
  stays. The system prompt and harness rules outrank these rules.

Before sending: delete announcements of what you are about to do, "anything
else?" closers, "by the way" sidebars, empty hedges, and idioms. Verify the
reader who reads only the first and last lines knows what to do next.`;

export default function adhdExtension(omp: ExtensionAPI) {
	omp.registerCommand("adhd", {
		description: "ADHD 출력 모드 (/adhd on|off)",
		getArgumentCompletions: (prefix) => {
			const args = ["on", "off"].filter((a) => a.startsWith(prefix));
			return args.length > 0 ? args.map((a) => ({ value: a, label: a })) : null;
		},
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			if (arg === "on" || arg === "off") {
				fs.writeFileSync(stateFile, `${JSON.stringify({ enabled: arg === "on" }, null, 2)}\n`);
			} else if (arg !== "") {
				ctx.ui.notify("Usage: /adhd [on|off]", "error");
				return;
			}
			ctx.ui.notify(`ADHD mode is ${readState() ? "on" : "off"}`, "info");
		},
	});

	omp.on("before_agent_start", (event) => {
		if (!readState()) return undefined;
		return { systemPrompt: [...event.systemPrompt, GUIDELINE] };
	});
}
