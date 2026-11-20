---
layout: "article"
title: "From blueprint to working integrations: the evidence behind IRI"
headline: "From blueprint to practice"
date: "2026-11-20 09:00:00 -0600"
author: "IRI Team"
summary: "Five years after its first blueprint, IRI is expanding v2 across identity, allocations, streaming, persistent services, and agent-ready workflows."
category: "News"
permalink: "/news/2026-iri-blueprint-to-practice/"
image: "/images/documents/2023-iri-aba.png"
image_alt: "Dark-blue cover graphic reading ‘Integrated Research Infrastructure Architecture Blueprint Activity’ beside an amber scientific visualization."
image_caption: "Cover art for the 2023 Integrated Research Infrastructure Architecture Blueprint Activity final report, U.S. Department of Energy Office of Science."
image_fit: "contain"
image_background: "dark"
---

_Five years after its first blueprint, IRI has moved from a shared description of cross-facility science to common interfaces, reusable implementations, and documented workflows while leaving DOE facilities independently operated. The next phase expands what those facilities can describe and coordinate through IRI v2._

At SC26, an [X-ray tomography workflow from the Stanford Synchrotron Radiation Lightsource](https://iri.science/news/2026-ssrl-tomography-iri-sc26/) was launched separately at five computing facilities from one dashboard. The same portable container ran at ALCF, NERSC, OLCF, SLAC, and an AWS environment operated by ESnet. Each provider kept its own scheduler, execution environment, storage, and policies. The common part was how the dashboard discovered, submitted, monitored, and retrieved the work through each facility's IRI API.

That demonstration is a useful place to start because it makes the Integrated Research Infrastructure concrete. IRI is not a new supercomputer, scheduler, network, or data center. It is a shared integration approach that lets independently operated research infrastructure participate in a scientific workflow while each provider retains operational authority.

## The problem was never a shortage of powerful facilities

DOE already operates world-leading scientific instruments, supercomputers, storage systems, and a high-performance research network. The harder problem is combining them without building a new one-off integration for every experiment and every destination.

The [2021 IRI blueprint](https://doi.org/10.2172/1863562) framed that problem across experimental, observational, and computational science. A team might need to move instrument data to a distant computing facility during an experiment, combine results from several sites, or keep a campaign running across resources for years. Each facility still has its own identity system, allocations, queues, data paths, security rules, and operating priorities.

Those differences remain. IRI creates common ground around them: shared workflow patterns, interfaces, trust mechanisms, data practices, and ways for facilities to coordinate.

## Three patterns for many kinds of workflow

The 2022 Architecture Blueprint Activity brought together more than 150 experts from all 28 Office of Science user facilities across 13 national laboratories. Its [2023 final report](https://doi.org/10.2172/1984466) identified three recurring, non-exclusive science patterns:

- **Time-sensitive workflows** need reliable results within an experiment or decision window. A running instrument may need remote analysis quickly enough to guide the next measurement.
- **Data integration-intensive workflows** combine information from several experiments, simulations, instruments, or sites to create a larger scientific context.
- **Long-term campaigns** need sustained access to multiple resources over months or years to accomplish a defined objective.

The patterns overlap. A light-source campaign can be time-sensitive during beamtime, integrate data from several facilities, and continue through a long sequence of experiments and analyses.

The same blueprint identified six practice areas needed to make those workflows routine: user experience; resource cooperation; cybersecurity and federated access; workflows, interfaces, and automation; the scientific data lifecycle; and portable, scalable solutions. Moving bytes or defining an API alone cannot solve cross-facility science. A technically valid workflow still fails if a researcher cannot obtain access, locate data, understand a queue, or recover from a partial failure.

## Requirements reviews showed that the patterns recur

ESnet tested the framework against 74 high-priority science cases collected through requirements reviews with five Office of Science programs between 2019 and 2023. The [IRI workflow-pattern meta-analysis](https://www.es.net/news-and-publications/publications-and-presentations/iri-workflow-patterns-meta-analysis/) found that most cases aligned with more than one pattern, and many aligned with all three.

Fusion, climate, light-source, and nuclear-physics workflows remain scientifically distinct. Their underlying infrastructure needs recur often enough, however, to justify reusable designs. Identity federation, resource discovery, data movement, monitoring, portable execution, and experiment-time feedback should not have to be reinvented from scratch for each scientific team.

## Pathfinders turned categories into engineering work

As IRI became a coordinated Office of Science program, pathfinder projects began testing the framework against working science:

- Fusion teams connected DIII-D experiments with remote analysis and computing while developing faster workflows intended to inform experiment-time decisions.
- Light-source teams tested workflows linking beamlines with leadership computing facilities for reconstruction and analysis.
- Climate teams explored how distributed data and computing services could support large, sustained analysis campaigns.

These projects exposed the practical seams behind the framework. A portable workflow still needs a destination-specific job description. A common identity must map to a local account and allocation. Storage that is visible from one compute system may be absent from another. A queue appropriate for ordinary batch work may not meet an experiment-time deadline.

These seams are the implementation work IRI was created to coordinate.

## A shared language with local control

The IRI Facility API is one result of that work. It gives clients a common sequence for discovering resources, checking status, submitting and monitoring work, interacting with storage, and inspecting projects or allocations. An adapter at each provider translates those operations to the local scheduler, cloud platform, storage service, or other backend.

The [draft IRI Facility API 2.0](https://iri.science/news/2026-iri-2-0/) extends that model with typed resources, shared semantic profiles, explicit relationships, and discoverable operations. A workflow engine—or an authorized software agent—can learn what a facility offers before acting instead of hard-coding every URL and resource layout.

Providers can expose different capabilities in either version. The running service description remains the authority for what a deployment supports, and an advertised operation does not grant authorization or guarantee capacity.

## From individual demonstrations to repeatable integrations

By 2026, several public exercises had begun to test the interface across independently operated environments:

- At the [Genesis Mission Hackathon](https://iri.science/news/2026-alcf-genesis-hackathon/), one exercise suite targeted ALCF, NERSC, OLCF, and an ESnet-operated AWS environment. Validation depth differed by provider, but the same client flow exposed where the shared model worked and where adapters still needed facility-specific handling.
- Documented [staging work connecting IRI to the American Science Cloud](https://iri.science/news/2026-amsc-integration/) showed how project and identity context can reach participating facility endpoints while authorization remains local.
- The [National Research Platform began implementing the IRI API](https://iri.science/news/2026-welcome-nrp/) for its distributed Kubernetes infrastructure, adding experience from a different operational model.

Together, these exercises show working integrations at different levels of maturity. API versions, authentication paths, resource coverage, and operations still vary, so the program uses pathfinders, testbeds, shared contracts, and implementation feedback rather than requiring every facility to change at once.

## What comes next for IRI v2

The FY27 roadmap shifts the emphasis from proving another point-to-point integration to widening the shared contract that many integrations can use. Its dates are planning targets, not a promise that every provider will expose the same capability at the same time. Facilities will continue to decide which optional services they operate and who is authorized to use them.

### Finish the v2 foundation and validate it across sites

The near-term work is to ratify and publish the v2 contract, then exercise it across more independent implementations. Some foundations are already present in the current v2 specification and reference code. A `whoami` operation lets authenticated clients learn the facility identity they are using, while idempotency keys make it safer to retry job submissions without creating duplicate work.

The allocation model is also being widened beyond conventional compute and storage quantities. Draft RFC work defines U.S.-dollar and inference-token allocation units, including how facilities can report accounting periods, renewal, usage freshness, and model-specific token limits. These are proposed semantics and provisional registry entries today, not a claim that every facility already meters cloud spending or inference in the same way.

Cross-site validation is as important as adding fields. The contract becomes useful only when the same client behavior works against separately operated providers and reveals where identity mapping, allocations, resource descriptions, or local policy still need explicit handling.

### Broaden the facilities and workflows v2 can describe

The next adoption target is v2 coverage across the ASCR facilities, accompanied by network-topology and normalized queue interfaces. Queue information can help a workflow understand where work may run and what constraints apply without pretending that every scheduler is identical. Network descriptions can give the workflow comparable context about the paths joining instruments, storage, and computing resources.

Streaming is not starting from a blank page. A [Draft/Proposed streaming-transport RFC](https://github.com/doe-iri/iri-facility-api-docs/blob/rfc/streaming-data-transport/rfc/rfc-streaming-data-transport.md) already models EJFAT as an optional IRI v2 resource. It defines project-scoped reservations, allocation and accounting rules, reservation credentials, live status, and discoverable operations. The working branch also carries provisional resource profiles and link relations, and the design builds on an AmSC broker prototype for EJFAT reservation operations.

That is implementation groundwork and active standardization, not a production capability available uniformly across facilities. The proposed `/streaming` section has not yet landed in the main v2 OpenAPI contract. If adopted, it would let authorized workflows discover and reserve streaming transport through the same facility context used for projects and allocations, rather than relying on a separately distributed control-plane credential.

Jupyter and other interactive environments are part of the same expansion. They connect the common facility description to the way scientists actually explore data and steer work, while local deployments retain responsibility for sessions, security, capacity, and support.

### Extend v2 to long-lived services and authorized agents

Later roadmap work adds normalized container-image workflows and persistent services such as long-running applications, databases, and interactive environments. Approved capability-discovery work already lets facilities describe container support; separate proposed work is exploring image acquisition and reuse plus governed access to persistent service infrastructure, without turning IRI into a central container platform.

The same machine-readable resource descriptions and operation links can make v2 useful to software agents. Skills and MCP-enabled clients could discover supported operations instead of guessing facility-specific URLs. “Agent-ready” does not mean unrestricted automation: identity, project membership, allocations, facility policy, and the advertised operation set still bound every action.

The common thread is not adding one more centralized service. It is expanding what independently operated facilities can describe, expose, and coordinate through IRI v2 so workflows—and eventually authorized agents—can assemble more of a cross-facility campaign without hard-coding every provider.

## What progress looks like for IRI

A practical measure of IRI's progress is whether scientific teams can assemble the facilities a campaign needs without turning every application into a collection of site-specific integrations. The local systems will remain different. The improvement is that those differences can be described, discovered, and handled through reusable patterns.

The evidence so far is narrower than a finished DOE-wide infrastructure, but stronger than a paper architecture: common interfaces have independent implementations; scientific workflows have crossed facility boundaries; and the resulting gaps are feeding back into the specifications and program priorities.

Read the [IRI architecture and background documents](https://iri.science/documents.html), explore the [current implementations](https://iri.science/implementations/), or see the [five-facility SSRL tomography workflow](https://iri.science/news/2026-ssrl-tomography-iri-sc26/) in detail.
