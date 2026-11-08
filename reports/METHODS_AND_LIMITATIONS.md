# Methods, evidence and limitations

## Analysis units and definitions

- **Incidents:** 24,918 distinct incident identifiers.
- **Events:** 141,712 historical event rows; approximately 5.69 per incident.
- **Valid resolution durations:** 23,362 incidents; 1,556 lack valid recorded resolution duration.
- **Resolution times:** Median 22.1 hours; 90th percentile 15.9 days. Percentages for time thresholds are calculated over valid durations unless stated otherwise.
- **Support-group change:** A change between adjacent observations with known assignment groups in the reconstructed incident event sequence.
- **Routing return:** An observed A → B → A support-group pattern after consecutive same-group observations are collapsed.

## Reconstructed routing evidence

The Python analysis compared **101,409 adjacent known-group event pairs**, finding **17,914** group changes across **9,224** incidents. It detected **3,231** return occurrences across **1,963** incidents. The event history includes **14,213** rows without known assignment groups, and **4,216** observed group changes involving tied event timestamps. These limitations may affect the inferred sequence.

## Selected statistical checks

- The distribution of resolution times differs substantially across reassignment groups (**Kruskal–Wallis H = 6,493.55; epsilon-squared = 0.2779**).
- Differences across handling-event groups show **epsilon-squared = 0.4820**.
- In an unadjusted comparison of valid-duration incidents, cases with an observed routing return had median **10,805 minutes** (n=1,863) versus **882 minutes** without a return (n=20,362); Mann–Whitney p < 0.001.
- Within the 7–10 event cohort, median durations were **7,326 versus 7,133 minutes** (with versus without a return). Within 11+ events, they were **18,463 versus 14,658 minutes**. These comparisons remain observational.
- A sensitivity regression on **22,225** records reported **R² = 0.4882** and signs that differ from the raw return comparison. It must not be interpreted as a causal estimate or as a forecast of savings.

For fuller context, see the management consulting report, especially its evidence, statistical interpretation and recommendations sections.

## Data gaps

1. Transfer and escalation reasons, ownership rules, ticket context, waiting states and staffing constraints.
2. Confirmed service-level targets, budget, platform capabilities and implementation approvals.
3. Resolution timestamp completeness, unknown-group events, event ordering and traceability.

## Proposed interventions, not realised outcomes

The report proposes a targeted case audit, escalation-review triggers, improved handoff guidance, lifecycle-data validation and a limited routing-assistance pilot with human approval. **No client interviews, live implementation, pilot result, causal savings estimate or realised cost reduction are claimed.**

## Reproducibility and files not published

This repository contains reviewed consulting and presentation outputs, not the full reproducibility package. Raw incident records, SQL scripts, the original Colab notebook and the `.pbix` source are not included in the archive. Source records may require their own permissions or licensing review before redistribution.
