---
layout: "article"
title: "One container, five facilities: an SSRL tomography workflow at SC26"
headline: "SSRL tomography @ SC26"
date: "2026-11-18"
author: "Justas Balcas"
summary: "At SC26, an SSRL X-ray tomography workflow used one container and the IRI API to run at five computing facilities, including an ESnet-operated AWS environment."
category: "News"
permalink: "/news/2026-ssrl-tomography-iri-sc26/"
image: "sc26-esnet-ssrl-demo.webp"
image_alt: "Visitors gather around a monitor showing the SSRL beamline workload presentation at SC26."
image_caption: "Attendees watch the SSRL beamline workload demonstration at SC26."
---

_At SC26, an X-ray tomography workflow from the Stanford Synchrotron Radiation Lightsource showed how one portable container can move among five computing facilities through a common IRI interface._

Tim J. Dunn of the Stanford Synchrotron Radiation Lightsource (SSRL) at SLAC National Accelerator Laboratory presented the beamline workload as the scientific-user half of **ESnet on AWS: A Cloud Facility Behind the IRI API**. The demonstration, developed with Justas Balcas and John MacAuley of ESnet, has two SC26 sessions at the Department of Energy booth in Chicago: November 16 at 8:00 p.m. and November 18 at 4:00 p.m. Central.

The broader American Science Cloud tomography workflow spans the Advanced Photon Source, the Advanced Light Source, and SSRL, and launches through IRI.

The campaign behind the presentation covered ALCF Polaris, NERSC Perlmutter, OLCF Defiant, SLAC S3DF, and an AWS environment operated by ESnet. Each recorded run was launched separately from the same dashboard, through the target facility's IRI API.

## From a scan to one portable container

The workload starts with X-ray microtomography data from an SSRL battery-cathode experiment. It uses `tomocupy` for GPU reconstruction, writes the volume and image pyramids in OME-Zarr, and applies the SAM3 segmentation model. A checkpoint fine-tuned for SSRL battery-cathode data under SYNAPS-I travels beside the TomoCloud container; the container itself holds the rest of the pipeline.

<figure class="news-figure">
    <a href="{{ '/images/news/sc26-ssrl-portable-container.webp' | relative_url }}">
        <img src="{{ '/images/news/sc26-ssrl-portable-container.webp' | relative_url }}"
            {% include image-dimensions.html path="/images/news/sc26-ssrl-portable-container.webp" %}
            alt="Diagram of the TomoCloud pipeline: tomocupy GPU reconstruction, OME-Zarr volume and pyramids, and SAM3 segmentation, packaged as one container, with the fine-tuned model weights supplied beside it."
            loading="lazy">
    </a>
    <figcaption>
        The portable workflow combines GPU reconstruction, OME-Zarr conversion, and SAM3 segmentation before running through each facility's IRI API.
        <span>Slide: Tim J. Dunn, SSRL/SLAC. <a href="{{ '/images/news/sc26-ssrl-portable-container.webp' | relative_url }}">View the full-size slide.</a></span>
    </figcaption>
</figure>

The container image ran under Kubernetes on AWS, Apptainer at ALCF, OLCF, and S3DF, and `podman-hpc` at NERSC. Those execution environments, along with local queues, storage, and policy, remained facility-specific. The dashboard's adapter for each facility translated the common client operations for that site's IRI API.

## Five separate launches from one dashboard

For each run, the dashboard operator selected a scan, a facility, and a model, then followed the same seven workflow stages. The campaign used the same 2048-by-2048-by-2048-voxel scan and eight GPUs at each destination, but not identical hardware or queue configurations.

<figure class="news-figure">
    <video class="news-video" controls playsinline preload="metadata"
        poster="{{ '/images/news/sc26-ssrl-dashboard-poster.webp' | relative_url }}"
        width="1280" height="720"
        aria-label="Silent 34-second dashboard timelapse of separately launched SSRL workflow runs"
        aria-describedby="ssrl-dashboard-video-caption">
        <source src="{{ '/videos/news/sc26-ssrl-dashboard-timelapse.mp4' | relative_url }}" type="video/mp4">
        <p>Your browser does not support embedded video. <a href="{{ '/videos/news/sc26-ssrl-dashboard-timelapse.mp4' | relative_url }}">Download the MP4 video.</a></p>
    </video>
    <figcaption id="ssrl-dashboard-video-caption">
        Five recorded facility runs, compressed into a silent 34-second dashboard timelapse. Each run was launched separately through its facility's IRI API; queue waits were removed, and the replays were normalized to the same length. The closing frame compares one slice from all five runs and shows where their labels agree.
        <span>Dashboard recording: Tim J. Dunn, SSRL/SLAC. <a href="{{ '/videos/news/sc26-ssrl-dashboard-timelapse.mp4' | relative_url }}">Download the MP4 video (7 MB).</a></span>
    </figcaption>
</figure>

The demonstration tested whether the scientific workflow and interface could travel, not which facility was fastest. ALCF and NERSC used A100 GPUs, AWS used L4 GPUs, OLCF used H200 GPUs, and S3DF used L40S GPUs. The node counts, queues, and storage paths also differed.

## Results that agree across facilities

The presentation compared the segmented volume from all five recorded runs. In slice 1054, 92.9 percent of the pixels labeled by any run were labeled by all five. Across the complete three-dimensional volume, the intersection over union for any pair of runs ranged from 0.9875 to 0.9889, where 1.0 would be a perfect match.

<figure class="news-figure">
    <a href="{{ '/images/news/sc26-ssrl-results-agree.webp' | relative_url }}">
        <img src="{{ '/images/news/sc26-ssrl-results-agree.webp' | relative_url }}"
            {% include image-dimensions.html path="/images/news/sc26-ssrl-results-agree.webp" %}
            alt="Battery-cathode tomography slice with segmented objects outlined, followed by an agreement map showing where five facility runs labeled the same pixels."
            loading="lazy">
    </a>
    <figcaption>
        The same battery-cathode volume was segmented at five facilities. Green marks pixels labeled by every run; the other colors show the small areas where fewer runs agreed.
        <span>Slide: Tim J. Dunn, SSRL/SLAC. <a href="{{ '/images/news/sc26-ssrl-results-agree.webp' | relative_url }}">View the full-size slide.</a></span>
    </figcaption>
</figure>

The 92.9 percent figure measures agreement, not scientific accuracy. In the slice shown, the differences sit in a few crowded spots where particles touch. Repeat runs at one facility varied by a similar amount, so most of the difference is run-to-run variation in the segmentation step, not a facility effect.

## Turnaround on the scale of a sample cycle

The five campaign runs took 12 to 30 minutes from launch to completed result. That interval included queueing, input transfer where the scan was not already at the facility, computation, and bringing the results back to SSRL. It is comparable to the 20-to-30-minute sample cycle at SSRL beamline 6-2, giving scientists a route toward seeing one sample's analysis while the next sample is on the stage.

Queue selection still mattered. An earlier run of the same job waited 42 minutes in a debug queue; the run used in the comparison waited 31 seconds in an express queue. The presentation treated these results as workflow timings, not a hardware benchmark, because the five facilities used different GPUs, queues, node counts, and storage systems.

Before this workflow, usable analysis could arrive weeks to months after beamtime once manual steps were included. The SC26 result is not a measured speedup against that older process. It shows that the reconstruction and segmentation path can be packaged, submitted, and returned on a timescale that is relevant during an experiment.

## The cloud behind the same IRI API

From the user's point of view, AWS through ESnet became one more facility behind the same IRI API. The local details did not disappear: a new workflow still needs a facility job script, and every provider retains its scheduler, execution environment, access controls, and operating policies. What became portable was the way the dashboard described, launched, monitored, and retrieved the work.

The [TomoCloud container recipe](https://github.com/osmiumzero/tomocloud-container) is public. Read the earlier [SC26 IRI demonstration preview]({{ '/news/2026-sc26-demos/' | relative_url }}) for more about the ESnet AWS facility and IRI 2.0 demonstrations.
