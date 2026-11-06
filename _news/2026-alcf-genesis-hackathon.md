---
layout: "article"
title: "Putting IRI through its paces at the Genesis Mission Hackathon"
headline: "Genesis Mission Hackathon"
date: "2026-10-17"
author: "Justas Balcas"
summary: "Shared exercises put resource discovery, job submission, monitoring, and file access through their paces across independently operated facilities."
category: "News"
permalink: "/news/2026-alcf-genesis-hackathon/"
---

_At Argonne’s October hackathon, the IRI team built one exercise set that could target ALCF, NERSC, OLCF, and an ESnet environment on AWS._

The [Genesis Mission: Hands-on Hackathon](https://events.cels.anl.gov/event/942/overview) brought scientific teams and infrastructure specialists to Argonne National Laboratory on October 14–16, 2026. More than 450 people took part in the event, working across 185 research projects with support from over 120 technical staff, according to DOE’s [post-event recap](https://www.energy.gov/undersecretaryforscience/genesis-mission/articles/genesis-mission-hackathon-brings-research).

The IRI team arrived with a narrower test in mind. Could a researcher follow one workflow across independently run facilities without hiding the differences between them?

To find out, the team prepared a public set of IRI Facility API exercises for four providers: the Argonne Leadership Computing Facility (ALCF), NERSC, the Oak Ridge Leadership Computing Facility (OLCF), and an ESnet-operated environment on AWS.

## One exercise set, four backends

The exercises followed the path a researcher would actually take:

1. Discover resources and check their current status.
2. Submit a compute job and follow it from the queue to completion.
3. Retrieve the job output with asynchronous filesystem operations.
4. List or cancel jobs and inspect the user’s projects and allocations.
5. Submit a GPU-aware job when the selected resource supports it.

The Python commands stayed the same. A `--facility` option selected the target. Behind that option were very different systems: ALCF resources such as Polaris and Aurora, NERSC’s Perlmutter, OLCF resources including Frontier, and container-oriented compute and storage on AWS.

IRI did not make those systems identical. Credentials, allocations, queues, reservations, filesystem paths, supported operations, and even the mix of IRI v1 and v2 endpoints remained visible. What it standardized was the path through them: discover, submit, monitor, and retrieve.

## Testing against live systems

This was more than a specification exercise. The ALCF and NERSC paths were validated together before the hackathon. A later NERSC retest covered all ten numbered exercises, including a completed job, readable output, and job cancellation. During the event, ESnet validation covered resource and account discovery, storage locations, filesystem operations, and a CPU job using the hackathon’s AmSC project context.

Maintainers also merged several practical improvements during the three-day event window. They simplified the ALCF login path used at the hackathon, added the OLCF event reservation, fixed GPU visibility in the ESnet backend, added a portable GPU submission exercise, and made storage access paths and operations easier for software to discover.

That work exposed the small but consequential seams that appear only when a shared model meets real infrastructure. A client still needs to know where output lands, how a reservation is represented, what a GPU request means to a particular scheduler, and which storage steps must happen before a job can run. During the event window, the team addressed those issues while the exercises were still fresh.

## What the hackathon left behind

The result is not a claim that every attendee completed every exercise, or that all four providers exposed the same capabilities. The durable result is an open exercise suite, backed by documented live testing at multiple providers, that teams can run again and extend as implementations change.

The ESnet path widened that test beyond traditional supercomputers. It used an American Science Cloud project credential to reach AWS-backed compute and storage through IRI. The client followed the same sequence as the leadership-computing examples, while the adapter translated each request for a different backend.

That is the practical goal of IRI: let researchers assemble the resources a scientific campaign needs while each facility keeps control of its security, policy, and operations. The Genesis hackathon turned that goal into a repeatable set of tests and left the community with working examples for the next round of development.

Explore the public [Genesis Mission hackathon exercises](https://github.com/doe-iri/iri-facility-api-examples/tree/main/genesis_hackathon), learn about [ALCF’s role in the Genesis Mission](https://www.alcf.anl.gov/genesis-mission), or read the current [ALCF IRI API guide](https://docs.alcf.anl.gov/services/iri-api/).
