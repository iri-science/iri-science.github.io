---
layout: "article"
title: "Trying IRI and the American Science Cloud with the 7NRP community"
headline: "IRI @ 7NRP"
date: "2026-05-06"
author: "Justas Balcas"
summary: "A hands-on workshop introduced Facility API v1 and an early AmSC orchestration prototype to the National Research Platform community."
category: "News"
permalink: "/news/2026-7nrp-demo/"
---

_A hands-on session at the Seventh National Research Platform Workshop paired a shared notebook with an early look at cross-facility orchestration._

On May 5, 2026, from 3:30 to 5:00 p.m. Pacific, ESnet’s Justas Balcas and Xi Yang led **DOE American Science Cloud Experiments with NRP** at the San Diego Supercomputer Center at UC San Diego. The tutorial was part of the [Seventh National Research Platform Workshop](https://nrp.ai/7nrp-workshop/) in La Jolla, California.

The session brought together two communities tackling a similar problem. The National Research Platform (NRP) connects distributed, community-operated computing and data resources for research and education. DOE’s Integrated Research Infrastructure (IRI) and American Science Cloud (AmSC) are working across another distributed landscape: supercomputers, experimental facilities, data services, networks, and cloud resources that continue to be run by their home institutions.

The tutorial gave participants a practical introduction to that work through the IRI Facility API, then looked ahead to the infrastructure resource orchestration being developed for AmSC.

## One client, different schedulers

The IRI Facility API sits between a scientific client and the provider’s local systems. A facility can keep the scheduler and storage tools that fit its mission, whether that means Slurm, PBS, Kueue on Kubernetes, HTCondor, or another backend. An authorized client gets a consistent set of operations for discovering resource status, managing jobs, working with local files, and inspecting allocations.

The adapter at each site does the translation. That lets the scientific workflow state what it needs while the provider keeps its own credentials, resource names, queues, and policies. Testing independent implementations against the same contract is what shows whether the abstraction works outside a reference environment.

## A hands-on look at Facility API v1

Participants were directed to a workshop JupyterHub running on NRP. The hands-on material used Facility API v1; version 2 was presented as roadmap work, not as the interface used in the exercise. The notebook walked through three basic steps:

1. Authenticate to an IRI endpoint.
2. Submit and monitor a compute job.
3. Run asynchronous local filesystem operations and inspect their results.

The shared environment removed most local setup and kept attention on the API. Temporary workshop access covered NRP and ESnet East, not every facility discussed in the presentation. The presenter’s demonstrated facility path used ESnet East, and the session materials did not claim that every participant completed every step.

The [notebook repository as it stood before the workshop](https://github.com/doe-iri/iri-facility-api-examples/tree/d2338a03e5532c272f395df1df41dcfe6ca566ea) preserves the event-time exercise materials.

## From one job to a multi-site workflow

The second half of the session moved from one provider to the AmSC Infrastructure Resource Orchestration prototype. The IRI Facility API gives clients a consistent way to interact with an individual provider. The orchestration layer works across providers and was presented through three connected functions:

- a resource catalog for finding facilities, status, capabilities, API descriptions, and data-access endpoints;
- job placement informed by availability, allocations, and workflow needs; and
- coordination of compute, data movement, and wide-area network services for multi-site workflows.

The prototype combined an intent-based interface and web portal with a Python client toolkit, multi-provider authentication, and support for IRI and orchestration APIs. In the demonstration, the team launched and inspected an in-progress workflow containing a training job, source and destination transfer jobs, filesystem resources, and a network connection. The transfer was still running when the session moved to questions.

That unfinished transfer is useful context. The services shown at 7NRP were described as Incubator-stage capabilities: experimental, best-effort prototypes without a production service-level agreement. The tutorial was a chance to put the design in front of an experienced distributed-infrastructure community, not a production launch.

## What the two communities can learn from each other

NRP and AmSC both deal with distributed computing, multi-site operations, Kubernetes-based infrastructure, and growing AI workloads. The DOE environment adds leadership-class supercomputers, experimental facilities, several identity and authorization domains, and commercial cloud providers.

Those differences make the comparison useful. NRP brings years of experience operating community infrastructure across institutions. IRI and AmSC bring a common API and orchestration work shaped by DOE’s mix of facilities. Testing the interface in both settings helps reveal where resource discovery, identity, portability, and coordination still need work.

The [presentation slides](https://media.nrp.ai/7nrp-slides/JBalcas_XYang.pdf), [session recording](https://youtu.be/zLXFeVDsiGw), and full [7NRP media archive](https://nrp.ai/7nrp-workshop/) are available online. The IRI specifications, reference implementations, and examples are developed openly in the [DOE IRI GitHub organization](https://github.com/doe-iri).
