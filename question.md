---
layout: page
title: Q&A
permalink: /q&a/
nav_order: 2
---

# Q&A

**Q:** I am a Stanford student interested in extending SustainBench as part of a course project (e.g., for CS221/229/230/231N). What are some possible directions?

**A:** Thank you for your interest in SustainBench! We are still looking for students to work on extensions of the project related to UN SDGs.

Here are some "idea sketches" to help you draft your proposal, ranked from easiest to hardest (in our opinion):
1. Pick any of the SustainBench tasks, try to beat our baseline, help make our leaderboard longer.
2. Develop new models that can handle multi-modal inputs for the DHS-based multi-modal multi-task tasks.
3. Add more "change over time data" and then train more models on this added data, to better quantify the "value" of more data. Specifically, we only have a limited number of labels for "poverty change over time" at the moment, but there are more LSMS survey data that can be processed to increase the nnumber of labels.
4. Introduce an "active learning" baseline for at least one of the tasks.
5. Replicating the Wikipedia project (https://arxiv.org/abs/1905.01627) for inclusion in SustainBench. This is a lot of work, probably more than a single course project! However, you could certainly write up your partial progress for a final report.

If you have additional ideas, you're welcome to reach out to us!
