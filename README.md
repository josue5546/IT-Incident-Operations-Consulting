# IT-Incident-Operations-Consulting| Operational Efficiency & Digital Transformation

**Business & Data Analytics Portfolio Project**

**Tools:** MySQL | Python (Google Colab) | Power BI | ChatGPT (AI-Assisted)

## Project Overview

This project examines IT service management performance using 24,918 historical incident records and 141,712 event records.

The aim was to understand why some incidents take longer to resolve, identify patterns in repeated handling and support-team transfers, and recommend practical improvements to incident management.

The project combines SQL analysis, Python statistical testing, Power BI dashboards and management consulting recommendations.

The focus was not simply on identifying operational problems, but on understanding where management should investigate further and which improvements could be tested before wider implementation.

## Key Findings

- **22.1 hours** was the median incident resolution time, while the 90th percentile reached **15.9 days**, highlighting a substantial group of long-running incidents.
- **45.63%** of incidents experienced at least one reassignment.
- **5,360 incidents (22.94% of valid resolution records)** took more than seven days to resolve.
- **2,737 incidents** experienced both three or more reassignments and seven or more handling events.
- **17,914 support-group changes** were identified across 9,224 incidents.
- **3,231 routing-return occurrences** were recorded across 1,963 incidents, with repeated transfers concentrated among a small number of support-team relationships.
- **1,556 incidents (6.24%)** had missing resolution durations, highlighting the need for stronger data-quality controls.

Python statistical tests identified significant differences in resolution-time distributions across incident groups. Further analysis showed that the relationships between handling activity, routing returns and resolution times were more complex when examined together.

These findings identify areas for further investigation rather than proving that specific transfers caused delays.

## Business Recommendation

The analysis supports prioritising incidents involving repeated handling, prolonged resolution times and frequent transfers between support teams.

The proposed improvements include reviewing incident ownership, introducing earlier escalation checks, strengthening data-quality controls and identifying opportunities for targeted automation.

A **12-week controlled pilot** is recommended, beginning with a review of 30–50 incidents involving recurring routing patterns.

Management should assess whether proposed changes reduce unnecessary handoffs and improve resolution efficiency without increasing reopened incidents or compromising service quality.

No operational changes have been implemented, and any potential efficiency improvements or financial benefits remain unproven.

## Technical Approach

**MySQL:** Validated incident and event records, examined resolution performance, investigated reassignment patterns and developed operational measures to support further analysis.

**Python:** Used Google Colab to conduct exploratory analysis, statistical hypothesis testing, support-team routing analysis and regression modelling. The analysis helped assess relationships between handling activity, reassignments, routing returns and resolution times.

**Power BI:** Created a three-page dashboard covering executive operational performance, resolution and process efficiency, and routing improvement opportunities. Each dashboard connects analytical findings with proposed management actions.

**Management Consulting:** Developed a structured assessment of operational challenges, prioritised practical recommendations and proposed a 12-week implementation roadmap with performance measures and safeguards.

## AI Usage & Transparency

I used ChatGPT to support this project. AI helped me understand technical concepts, develop and troubleshoot SQL and Python code, structure the analytical approach, and prepare the consulting report and management presentation.

My role involved working through the analysis in MySQL, Python and Power BI, executing and reviewing analytical steps, checking results and developing the business interpretation.

I used ChatGPT as a learning tool and, most importantly, a productivity tool.

## Project Deliverables

Explore the completed analysis and supporting documents:

| **Deliverable** | **Description** |
|---|---|
| [SQL Analysis](./sql/) | MySQL queries covering data validation, incident resolution performance, reassignment patterns and operational analysis. |
| [Python Analysis](./python/) | Statistical hypothesis testing, routing-pattern analysis, regression modelling and analytical interpretation. |
| [Power BI Dashboard](./powerbi/) | Three-page dashboard presenting incident performance, resolution efficiency, routing patterns and management priorities. |
| [Consulting Report](./reports/) | Management consulting report covering methodology, analytical findings, practical recommendations and a proposed 12-week pilot. |
| [Management Presentation](./presentation/) | Seven-slide executive presentation communicating key findings, recommendations, implementation considerations and conclusions. |

**AI-Assisted Workflow:** ChatGPT supported coding, troubleshooting, statistical explanations and documentation, helping demonstrate how AI-assisted workflows can improve analytical productivity. All analytical outputs require validation, critical thinking and human judgement.

## Data Source

Historical, anonymised IT service management incident and event-log data.

The analysis covers 24,918 distinct incidents and 141,712 recorded events.

**Limitations:** The dataset does not provide complete information about staffing, operational costs, service-level agreements or the reasons behind every incident transfer. Missing assignment-group information and tied event timestamps also affect routing reconstruction.

The findings describe historical patterns and statistical associations, not proven causes of delays or verified improvements.

Link: https://archive.ics.uci.edu/dataset/498/incident+management+process+enriched+event+log
---

*This project demonstrates how SQL, Python, Power BI, AI-assisted workflows and management consulting methods can support evidence-based operational decisions and practical digital transformation opportunities.*
