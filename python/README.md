# Python Analysis

## Overview

This folder contains the Python analysis completed in Google Colab to investigate incident-management performance in greater detail.

Building on the initial SQL findings, the analysis uses statistical methods to examine relationships between resolution times, handling activity, incident reassignments and support-team routing patterns.

## Analysis Covered

- **Exploratory analysis:** Examining incident distributions, resolution durations and operational patterns.
- **Statistical testing:** Using non-parametric tests to assess differences in resolution times across incident groups.
- **Routing analysis:** Reconstructing support-team transfers and identifying incidents that return to previously assigned teams.
- **Regression analysis:** Exploring how handling activity, reassignments and routing returns relate to resolution times when considered together.
- **Data-quality assessment:** Identifying limitations arising from missing assignment-group information and event timestamps.

## Purpose

The Python analysis provides a deeper understanding of the operational patterns identified through SQL and Power BI.

An important part of this work is distinguishing statistical relationships from proven causes. For example, incidents involving repeated handling may take longer to resolve, but the analysis alone cannot establish whether the additional handling caused the delay.

These findings help identify where further investigation, process reviews and controlled improvement initiatives would be most valuable.
