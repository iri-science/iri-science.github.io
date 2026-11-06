---
layout: "article"
title: "One project, many facilities: connecting IRI to the American Science Cloud"
headline: "IRI + AmSC"
date: "2026-10-17"
author: "Justas Balcas"
summary: "Explore how AmSC project identity and staging integrations connect scientific workflows to facility APIs while preserving local authorization decisions."
category: "News"
permalink: "/news/2026-amsc-integration/"
---

_New identity support in the IRI reference implementation and a documented staging workflow show how an AmSC project can reach independently operated DOE facilities without taking authorization decisions away from them._

Cross-facility work usually starts with a collection of site-specific details: a login at one facility, an allocation at another, different names for similar resources, and a separate set of security rules at each stop. The [American Science Cloud](https://amsc.energy.gov/) is being built to connect that landscape, not replace it with a single computing center.

That makes the American Science Cloud (AmSC) and the Integrated Research Infrastructure (IRI) natural partners. IRI gives facilities a common, machine-readable way to describe resources and operations. AmSC contributes project context, federated identity, policy, and a route to each participating provider. Recent work in the public IRI code and examples connects those two layers.

## What happens to an AmSC request

The user-facing flow starts in MyAmSC. A researcher selects a project and creates a project-bound personal access token (PAT). The API Gateway validates the PAT at the platform edge. The Resource Integration Gateway (RIG) validates it again, reads its project context, finds the participating facility route, and determines which credential path that provider expects. From there, the request reaches the provider’s IRI API and its local adapter, scheduler, or storage service.

In compact form:

`AmSC project → project-bound credential → API Gateway → RIG → facility IRI API → local resource`

The public examples exercise this path with a small multi-facility compute and filesystem test. The client discovers resources and allocations, submits and monitors a job, and retrieves its log through the IRI filesystem task API. The sequence is shared; provider credentials, resource identifiers, capability differences, and the small client branches needed for IRI v1 and v2 remain explicit.

## One gateway, several credential paths

An AmSC credential can get a request to RIG. It does not create a facility allocation or override local access rules. The current staging materials describe several ways to cross that last boundary:

<div class="news-table-scroll" role="region" aria-label="AmSC facility credential paths" tabindex="0" markdown="1">

| Path                          | How it works                                                                                                  | Example in the current materials                       |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| Intended direct AmSC identity | In the design, the provider accepts an audience-scoped AmSC identity and maps the project to a local account. | ESnet and PNNL routes in the current staging materials |
| Brokered facility login       | RIG obtains and refreshes a credential through the provider’s OAuth flow.                                     | ALCF through Globus authentication                     |
| Project credential vault      | An existing site token is stored for the AmSC project and attached when RIG calls the facility.               | NERSC and OLCF                                         |

</div>

These are configured or documented staging routes, not evidence that every path is equally ready for production. The variety is intentional. DOE facilities already have their own identity systems, allocation processes, and security policies, so federation has to work with those boundaries.

For the intended direct route, RIG forwards an audience-scoped AmSC Keycard to the provider. The IRI Python reference implementation now has optional support for validating that Keycard and mapping its project context to a local account maintained by the facility. If a project or user is not in a restricted mapping, the AmSC mapping does not resolve. A deployment may still offer a separate facility-specific authentication route. In every case, the provider decides whether that identity may use the requested resource.

## The gateway moves instructions, not scientific data

The documented Globus workflow follows the same division of responsibility. A user presents an AmSC PAT to RIG. RIG exchanges it for the project’s provisioned Globus service-account token and calls the Globus Transfer API. The data travels directly between Globus collections and data-transfer nodes; it does not flow through RIG.

This keeps the gateway focused on identity, project context, routing, and control while existing high-performance paths carry the data.

## What works now, and what comes next

The optional identity support is merged in the public IRI reference implementation, and the examples document an end-to-end client pattern configured for a staging RIG. They also make the prerequisites clear. Users still need an allocation or other entitlement at each provider, and some routes require a connected facility login or a stored token. At the time of writing, [AmSC access is restricted](https://docs.amsc.energy.gov/faq/) to Genesis RFA Phase I teams approved for Model Access Gateway access.

This is not yet a promise that one credential opens every DOE facility. Onboarding, credential exchange, capability coverage, and deployment are moving at different speeds. The milestone is more specific: AmSC can carry project context to a common IRI interface while the provider keeps control of authorization.

For workflow services and authorized agents, that creates a useful pattern. They can discover participating facilities, learn which credential route applies, and use the same IRI operation model after access is established. A new provider can implement that interface and the appropriate identity mapping instead of asking every scientific application to absorb another custom integration.

Learn more in the [AmSC documentation](https://docs.amsc.energy.gov/), explore the public [AmSC and IRI examples](https://github.com/doe-iri/iri-facility-api-examples/tree/main/amsc), and follow the open [DOE IRI repositories](https://github.com/doe-iri).
