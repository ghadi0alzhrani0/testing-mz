# testing-mz — Mezyad private test copy

This repository is Ghadi's private working copy of [Mezyad](https://github.com/ghadi0alzhrani0/Mezyad), imported with Git history from commit `57929bf0942be798a4aa7527827b88f5b25d88fc`.

**Status:** Technical planning proposal. This repository does not contain an implemented or tested auction application.

## Documentation

| Stage | Document |
|---|---|
| Stage 1 — original idea history | [Report](Stage_1/Report.MD) |
| Stage 2 — original project charter | [Report](Stage_2/Report.MD) |
| Stage 3 — revised technical proposal | [Report with five Mermaid diagrams](Stage_3/Report.MD) |
| Stage 3 — proposed MySQL schema | [schema.sql](Stage_3/schema.sql) |
| Stage 3 — original report for comparison | [Original report](Stage_3/Original_Report.MD) |

The revised Stage 3 preserves public/private auctions, automatic highest-bid winning, live updates and anti-sniping. It proposes Python/Flask, MySQL, HTML/CSS/JavaScript and Docker Compose for student implementation.

All five current technical diagrams are Mermaid code inside Markdown: one architecture diagram, one ERD and three sequence diagrams. UI mockups remain in the existing Figma files referenced by the original documents.

Stage 1 and Stage 2 are preserved as source history. Earlier payment, escrow, transaction and delivery ideas are not additions to the current MVP. The unresolved bank sandbox operation and deployment host, plus proposed camel/plate fields for team review, are explicitly recorded in Stage 3.

Each team member works in a task branch, opens a pull request, and has another member review it before integration. Docker Compose runs the application and database; GitHub stores and reviews the code.

No runtime tests or Holberton Manual QA review have been completed for this proposal.

## Team

- Ghadi Alzhrani
- Abeer Alsayari
- Tala Alhudhaybi
- Aseel Alzhrani
