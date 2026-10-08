import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  auditSource,
  DEFAULT_ROOT,
  inspectTabBodies,
  listSourceFiles,
} from "./audit-frontend-conventions.mjs";

const repositoryRoot = resolve(
  dirname(fileURLToPath(import.meta.url)),
  "../../../..",
);
const skillRoot = resolve(
  repositoryRoot,
  ".agents/skills/angular-frontend-standards",
);

function fixture(path) {
  return readFileSync(resolve(repositoryRoot, path), "utf8");
}

function markdownFiles(directory) {
  return readdirSync(directory).flatMap((name) => {
    const path = resolve(directory, name);
    return statSync(path).isDirectory()
      ? markdownFiles(path)
      : path.endsWith(".md")
        ? [path]
        : [];
  });
}

test("classifies inline and component-only tab bodies", () => {
  const source = `
    <mat-tab-group>
      <mat-tab label="Inline"><div>Business content</div></mat-tab>
      <mat-tab label="Component"><ng-template matTabContent><app-orders-tab /></ng-template></mat-tab>
    </mat-tab-group>`;

  assert.deepEqual(
    inspectTabBodies(source).map((tab) => tab.component),
    [false, true],
  );
  assert.equal(
    auditSource("src/app/features/example/example.html", source).filter(
      (finding) => finding.rule === "TAB_COMPONENT_BOUNDARY",
    ).length,
    1,
  );
});

test("supports the legacy NG-ZORRO tab pattern only as an optional audit target", () => {
  const source = `<nz-tab nzTitle="Component"><ng-template nz-tab><app-orders-tab /></ng-template></nz-tab>`;
  assert.deepEqual(
    inspectTabBodies(source).map((tab) => tab.component),
    [true],
  );
});

test("flags a possible hand-drawn table for review", () => {
  const source = `
    @for (quote of quotes(); track quote.id) {
      <a class="flex justify-between"><span>{{ quote.number }}</span><span>{{ quote.total }}</span></a>
    }`;

  assert.ok(
    auditSource("src/app/features/example/quotes-tab.html", source).some(
      (finding) => finding.rule === "POSSIBLE_HAND_DRAWN_TABLE",
    ),
  );
});

test("validates the skill frontmatter and every routed reference", () => {
  const skill = readFileSync(resolve(skillRoot, "SKILL.md"), "utf8");
  const frontmatter = skill.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(frontmatter, "SKILL.md must contain YAML frontmatter");
  assert.match(frontmatter[1], /^name: angular-frontend-standards$/m);
  assert.match(frontmatter[1], /^description: \S.+$/m);

  const references = [...skill.matchAll(/\]\(references\/([^)]+\.md)\)/g)].map(
    (match) => match[1],
  );
  assert.equal(
    references.length,
    9,
    "router must link the repository profile, seven topics, and shared form feedback reference",
  );
  for (const reference of references) {
    assert.ok(
      existsSync(resolve(skillRoot, "references", reference)),
      `${reference} must exist`,
    );
  }
});

test("uses the ASRS Angular application as the convention-audit default", () => {
  const appPath = resolve(repositoryRoot, DEFAULT_ROOT);
  assert.ok(existsSync(appPath));
  assert.ok(listSourceFiles(appPath).length > 0);
});

test("workflow skills no longer suppress required lint or test gates", () => {
  const workflows = [
    ".agents/skills/create-angular-feature/SKILL.md",
    ".agents/skills/refactor-angular-code/SKILL.md",
    ".agents/skills/review-angular-code/SKILL.md",
  ];
  for (const workflow of workflows) {
    const source = fixture(workflow);
    assert.doesNotMatch(source, /Do not run tests, lint/i);
    assert.match(source, /angular-frontend-standards/);
  }
});

test("all local markdown references in the frontend skill resolve", () => {
  for (const file of markdownFiles(skillRoot)) {
    const source = readFileSync(file, "utf8");
    for (const match of source.matchAll(/\]\(([^)#]+\.md)(?:#[^)]+)?\)/g)) {
      assert.ok(
        existsSync(resolve(dirname(file), match[1])),
        `${relative(repositoryRoot, file)} links to missing ${match[1]}`,
      );
    }
  }
});
