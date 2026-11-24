# Enhancement log

This folder tracks enhancement work in **batches**. Each batch is one file, `enh-NN.md`, with its
tasks, their progress and how they were verified. Its last section suggests bug fixes and features
for the next batch.

It is a working record for agents and maintainers. It is **not published** on the documentation
site (`mkdocs.yml` excludes `enhanced/`).

## Index

| batch | title | status | started | last update |
|---|---|---|---|---|
| [enh-01](enh-01.md) | Nikki pages, Vantage row buttons, QModem cell lock | review | 2026-11-24 | 2026-11-24 |

## How a batch works

1. **Start** a batch by copying [`_template.md`](_template.md) to the next number (`enh-02.md`),
   and add it to the index above.
2. **Pick tasks.** Take open suggestions from the end of the previous batch, or new requests.
   A task carried over keeps a link to where it came from (`from: ENH-01-S3`), and the old
   suggestion is marked `moved → ENH-02-T1`.
3. **Work** the tasks. Keep each task's *Status*, *Files* and *Verification* current as you go.
4. **Close** the batch when no task is `doing`: set the batch status, and write the
   *Suggestions* section with what you noticed but did not do.

## IDs

Every task and suggestion has an ID that never changes or gets reused:

- tasks: `ENH-<batch>-T<n>`, e.g. `ENH-01-T3`
- suggestions: `ENH-<batch>-S<n>`, e.g. `ENH-01-S2`

Refer to work by its ID in commits, pull requests and other batches.

## Statuses

| status | meaning |
|---|---|
| `todo` | agreed, not started |
| `doing` | in progress |
| `review` | code done and checked off-device; waiting for a test on the router or a review |
| `done` | verified, including on the router where that matters |
| `blocked` | cannot go on; the task says why and what it waits for |
| `dropped` | will not be done; the task says why |

For a suggestion: `open`, `moved → <task ID>`, or `rejected` (with the reason).

A batch's status is the least finished status among its tasks (one task in `review` keeps the
batch in `review`).

## Rules

- Write what was **verified** and what was **not**. "Tested in a headless DOM with mocked
  replies" and "tested on the router" are different claims; say which.
- Name files by their repository path (`patches/feeds/qmodem/0012-...patch`).
- Use absolute dates (`2026-11-24`).
- Keep the user-facing explanation in the public docs (`docs/modem.md` and so on). A batch file
  links to those pages instead of repeating them.
- Suggestions say **why** (the evidence: a file and line, a log, a test) and roughly **how big**
  the work is (`S`, `M`, `L`).
