---
layout: "article"
title: "See IRI in action at SC26"
headline: "IRI @ SC26"
date: "2026-11-06"
author: "Justas Balcas"
summary: "See IRI at SC26: demonstrations of resource discovery with IRI 2.0 and scientific workflows spanning DOE facilities and ESnet’s AWS environment."
category: "News"
permalink: "/news/2026-sc26-demos/"
---

_Two demonstrations at the DOE booth will show IRI from different angles: one focused on discovering research infrastructure, the other on running the same scientific workflow across DOE systems and an AWS-backed cloud facility._

The Integrated Research Infrastructure (IRI) team is bringing two live demonstrations to [SC26](https://sc26.supercomputing.org/) in Chicago. The first offers a look at the developing IRI 2.0 model and the common language it gives people, applications, and AI agents. The second uses the IRI Facility API to run a scientific workflow across Advanced Scientific Computing Research (ASCR) facilities and an ESnet-operated environment on AWS.

Both demonstrations will be given twice at the Department of Energy booth (#4829) in McCormick Place. All times are Central Standard Time.

<div class="news-table-scroll" role="region" aria-label="SC26 IRI demonstration schedule" tabindex="0" markdown="1">

| Demonstration                                                  |  Monday, November 16 | Wednesday, November 18 | Presenters                                                                                                                      |
| -------------------------------------------------------------- | -------------------: | ---------------------: | ------------------------------------------------------------------------------------------------------------------------------- |
| **IRI 2.0: A Common Language for DOE Research Infrastructure** | 7:00 p.m., Station 1 |   1:00 p.m., Station 2 | John MacAuley and Justas Balcas, ESnet/Lawrence Berkeley National Laboratory                                                    |
| **ESnet on AWS: A Cloud Facility Behind the IRI API**          | 8:00 p.m., Station 2 |   4:00 p.m., Station 1 | Justas Balcas and John MacAuley, ESnet/Lawrence Berkeley National Laboratory; Tim J. Dunn, SLAC National Accelerator Laboratory |

</div>

## Helping clients understand what a facility offers

DOE’s research infrastructure includes leadership-class supercomputers, storage platforms, data-transfer services, cloud resources, and the access paths that tie them together. Before a workflow can use any of those systems, it has to understand what they are, how they relate, and which operations the facility advertises for them.

**IRI 2.0: A Common Language for DOE Research Infrastructure** will show how IRI represents that information in a consistent, machine-readable form. A resource description identifies the kind of infrastructure it represents. Type-specific attributes carry details relevant to that resource. Typed links describe relationships and advertise applicable operations, while OpenAPI tells software how to invoke them.

The same description can be useful in several ways. A researcher or facility operator can inspect it to see what a site offers. A workflow engine or authorized AI agent can discover a resource, follow an operation the facility has advertised, consult the API contract, and make a request without guessing how that facility organizes its URLs.

## Running the same workflow on AWS and DOE systems

The second demonstration puts that common interface behind a very different kind of facility.

**ESnet on AWS: A Cloud Facility Behind the IRI API** will expose AWS-backed compute with batch scheduling, container execution, and GPU support, along with storage endpoints and a Globus data-transfer node. The adapter is written for AWS; the client-facing IRI contract is not. The same adapter pattern could bring Google Cloud or Microsoft Azure resources into the workflow without changing the interface used by the client.

The scientific workload comes from the Stanford Synchrotron Radiation Lightsource (SSRL), a DOE Office of Science Basic Energy Sciences user facility at SLAC. From an SSRL cross-facility workflow dashboard, the team will submit a containerized X-ray tomography and segmentation workflow to the AWS environment using the same IRI calls used for NERSC and ALCF.

The broader demonstration moves the client among NERSC, ALCF, OLCF, and ESnet on AWS by changing the facility endpoint rather than rewriting the scientific workflow. Each provider still uses its own scheduler, storage systems, security boundaries, and operating policies. IRI supplies the portable descriptions and operations around them.

## Join us at the DOE booth

SC26 runs November 15–20 at McCormick Place in Chicago. Stop by DOE booth #4829 during either demonstration slot to see discovery and execution working together, meet the presenters, and talk with the team about connecting a facility or workflow.

See the complete [DOE booth demonstration schedule](https://scdoe.info/demonstrations/) and the [SC26 conference program](https://sc26.supercomputing.org/).
