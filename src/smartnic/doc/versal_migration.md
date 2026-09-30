# ESnet SmartNIC on Versal — Architecture and Migration Plan

This document describes the target architecture for the ESnet SmartNIC on the AMD
Versal V80 and the plan to implement it. It covers subsystems and interfaces rather
than implementation detail.

---

## 1. Objective

Deliver the ESnet SmartNIC platform on the AMD Versal V80 (av80) card at feature
parity with the existing Alveo UltraScale+ deployment, with capacity for higher line
rates.

Versal is the successor deployment platform for the SmartNIC. The UltraScale+ cards
in use are at or approaching end of life (§2.1), so the migration is a prerequisite
for continued development as well as a performance upgrade.

Requirements:

- The P4 pipelines and application logic used on UltraScale+ build and run on Versal
  without modification.
- Host software and firmware see a consistent register and DMA interface on both
  platforms; the software stack is not forked.
- The platform meets or exceeds the 2 × 100G line rate of the UltraScale+ deployment.
  DCMAC provides capacity up to 2 × 400G; the extent to which that capacity is used
  depends on application requirements.
- Build, packaging, and deployment use a common flow across both platforms.

---

## 2. Rationale for Versal

| Factor | UltraScale+ | Versal |
|---|---|---|
| Line rate | 2 × 100G (CMAC) | 2 × 400G (DCMAC) |
| Host interface | PCIe Gen3 ×16 | PCIe Gen5 ×8 — approximately 2× the usable bandwidth in half the lanes |
| DMA engine | QDMA as soft IP in fabric | QDMA hardened in the CPM5 block |
| Platform lifecycle | U280 discontinued; U55C mature and approaching end of roadmap | Current-generation silicon |

### 2.1 Platform availability

Card availability constrains the UltraScale+ deployment independently of its
technical capability.

The U280 is discontinued. It remains supported for design updates on existing
hardware but is no longer available for purchase, so the installed base cannot be
expanded or replaced from new stock. The U55C remains available, but is a mature part
approaching the end of its roadmap and is expected to follow the same path.

The UltraScale+ deployment therefore has a lifetime bounded by hardware already in
hand. Versal provides a successor platform with a support horizon that covers
continued development of the SmartNIC codebase.

Existing UltraScale+ hardware remains supported for its service life; Versal is an
additional target, not a replacement for support.

### 2.2 Capability

DCMAC provides up to 4× per-port line rate capacity relative to UltraScale+ CMAC,
and the Gen5 host interface provides approximately 2× host bandwidth.

Hardening QDMA into CPM5 also recovers the fabric area occupied by the soft QDMA
implementation on UltraScale+. That area is available for larger P4 pipelines and
additional application logic.

---

## 3. Design principles

### 3.1 Application logic is carried across unchanged

The P4 pipeline and the packet-processing logic around it are migrated as-is rather
than reimplemented. The platform layers below them are structured to make this
possible.

### 3.2 AVED is patched, not forked

AMD supplies a reference platform for the V80, the Alveo Versal Example Design
(AVED). It provides board management, power and thermal monitoring, the sensor
controller, the AMI host management driver, and the device programming flow.

AVED is consumed as an upstream submodule and patched additively: the build applies a
defined set of modifications on top of AMD's generator scripts rather than
maintaining a forked copy. The cost of absorbing a new AVED release is then
proportional to what changed upstream.

**AMR migration.** AMD's Adaptive Management Runtime (AMR) is the successor to AVED.
The platform will require migration to AMR at some point.

The additive-patch model reduces the cost of that migration. The ESnet modifications
remain an explicit, enumerable set, so migration consists of re-targeting that set to
AMR rather than reconstructing it from a fork.

This places a constraint on the platform layer: modifications to the vendor platform
should be minimal, individually justified, and confined to the interfaces described
in §6 — principally the PCIe bifurcation and the NoC routing serving the ESnet
endpoint. Modifications that reach further into AVED increase migration cost
proportionally.

AMR migration is outside the scope of the phases in §8 and will be scheduled as
separate work once AMD's transition path is defined.

### 3.3 A single hardware/software contract across platforms

The register map, DMA queue model, and packaging format are defined once and
generated from a single source. UltraScale+ and Versal differ in implementation, not
in the interface presented to the host.

### 3.4 Platform and application are compiled separately

The shell and the core are separately compiled artifacts that are assembled at
implementation time. This is described in §5.

---

## 4. Layered architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  HOST                                                           │
│  DPDK / kernel driver      AMI management driver                │
└───────────┬───────────────────────────┬─────────────────────────┘
            │ PCIe (datapath)           │ PCIe (management)
┌───────────┼───────────────────────────┼─────────────────────────┐
│  VERSAL V80                           │                         │
│           │                           ▼                         │
│           │                  ┌──────────────────┐               │
│           │                  │  AVED PLATFORM   │               │
│           │                  │  board mgmt,     │               │
│           │                  │  sensors, power, │               │
│           │                  │  programming     │               │
│           │                  └──────────────────┘               │
│           ▼                                                     │
│  ┌────────────────────────────────────────────────┐             │
│  │  ESnet SHELL                                   │             │
│  │  QDMA streaming · DCMAC ports · register       │             │
│  │  decode · clocking · reset                     │             │
│  └────────────────────┬───────────────────────────┘             │
│                       │  shell/core interface                   │
│  ┌────────────────────┴───────────────────────────┐             │
│  │  SmartNIC CORE                                 │             │
│  │  P4 ingress/egress pipelines · application     │             │
│  │  logic · egress queueing (HBM, optional)       │             │
│  └────────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

| Layer | Owner | Platform-specific | Application-specific |
|---|---|---|---|
| AVED platform | AMD, patched by ESnet | Yes — Versal only | No |
| ESnet shell | ESnet | Yes | No |
| SmartNIC core | ESnet | No | Yes |

The core is written against a platform-independent interface and therefore targets
both UltraScale+ and Versal from one source.

---

## 5. The SmartNIC integration layer

### 5.1 Interface definition

The shell and the core meet at a single versioned interface. All interaction between
the layers crosses it:

| Group | Contents |
|---|---|
| Clocks and resets | Core clock, management clock, per-port clocks, associated resets |
| Control | One AXI-Lite port — the application's register window |
| Network | Per-port receive and transmit packet streams (2 ports, 512-bit) |
| Host DMA | Host-to-card and card-to-host packet streams, with queue identity and RSS metadata |

There are no additional connections between the layers, and the application has no
direct access to vendor IP.

### 5.2 Consequences

**Portability.** An application written to this interface is unaffected by whether
packets arrive from a CMAC on UltraScale+ or a DCMAC on Versal, or whether DMA is
served by soft QDMA or the CPM5 hard block. Platform differences terminate at the
boundary.

**Parallel development.** Platform and application development work against the
interface definition rather than against each other's source. Application work
proceeds against a stable shell; shell work proceeds against a stub core.

**Build cost.** The shell and core are compiled separately and then assembled. The
shell contains slow-changing infrastructure — the PCIe block, memory controllers, and
high-speed transceivers. The core contains the application logic, which changes
frequently.

| Change | Rebuild scope |
|---|---|
| Application logic or P4 program | Core, then re-assemble |
| Shell infrastructure | Shell, then re-assemble |
| Neither | None |

Without the split, every application change would trigger resynthesis of the PCIe and
memory subsystems.

**Independent versioning.** The compiled shell is a self-describing artifact. The
platform identifies the loaded shell by a fingerprint derived from that artifact,
which allows management software to verify compatibility before loading an
application image.

### 5.3 Application integration

An application is a directory containing its logic, its P4 programs, and a build
description naming the core it uses. The build system generates the remainder of the
component tree from that description.

---

## 6. Interfaces

### 6.1 PCIe — bifurcated endpoint

AVED presents itself to the host as a management device and expects to own the card's
PCIe endpoint; the AMI driver binds to it. The SmartNIC requires a datapath endpoint
with its own device identity, driver, and lifecycle. Both must be present
simultaneously.

The card's PCIe slot is bifurcated into two ×8 endpoints:

| Endpoint | Owner | Role |
|---|---|---|
| PCIE1 | AVED | Board management, sensors, programming; AMI driver binds here |
| PCIE0 | ESnet | Datapath — QDMA queues and the SmartNIC register map |

**Alternatives considered.** Sharing a single endpoint requires inserting ESnet
functions into AVED's address map and device identity, which amounts to a fork of
AVED and couples the ESnet release cadence to AMD's. Replacing AVED entirely requires
taking ownership of board management, thermal safety, and the host management driver.
Bifurcation costs eight lanes and keeps each side with a separate PCI device ID,
driver, and upgrade path.

The lane cost is offset by the generation change: Gen5 ×8 provides approximately
twice the usable bandwidth of the Gen3 ×16 link used on UltraScale+.

### 6.2 QDMA — host data movement

QDMA moves packets between the card and host memory. On Versal it is hardened inside
the CPM5 block rather than instantiated as soft IP.

| Property | Target |
|---|---|
| Mode | Streaming (packet-oriented), not memory-mapped |
| Queues | 4096, supporting per-queue steering and multi-core host scaling |
| Physical functions | 2, with SR-IOV virtual functions for tenant isolation |
| Interrupts | MSI-X |
| Datapath width | 512-bit |

The host-facing queue model matches the UltraScale+ deployment, so DPDK applications
and the kernel driver behave identically on both platforms. Packets carry queue
identity and RSS metadata, so receive-side steering decisions made in the P4 pipeline
are honoured by the host.

Differences between the soft and hard QDMA implementations — queue identifier width,
completion format, and clocking — are absorbed by an adapter in the shell and are not
visible to the core or to the host.

### 6.3 DCMAC — network ports

DCMAC is the Versal hard Ethernet controller.

| | UltraScale+ | Versal |
|---|---|---|
| Controller | CMAC (hard) | DCMAC (hard) |
| Ports | 2 | 2 |
| Rate per port | 100G | 400G |
| Aggregate | 200G | 800G |

Two instances are provisioned, matching the two-port model the platform already
exposes. The shell presents each port to the core as a packet stream with its own
clock domain; the core does not interact with the MAC directly. The pipeline and host
DMA path can be sized to match application requirements, up to the 400G per-port
capacity of the DCMAC.

### 6.4 HBM — egress buffering

Egress queueing is an optional capability of the SmartNIC core, used by applications
that need to absorb bursts on the egress path. Where enabled, it uses high-bandwidth
memory to provide deep packet buffering, per-queue scheduling, and decoupling of
pipeline output rate from line rate.

The subsystem is configurable as present or absent. Applications that do not require
burst absorption build without it and do not incur its resource cost. Applications
that do require it select it in their build configuration.

The Versal work is to connect the subsystem to the V80 memory subsystem and
characterise its behaviour at the higher line rate, so that the capability is
available to applications that need it. Applications built without egress queueing
are unaffected by this work.

### 6.5 Register and control plane

Every register in the design — platform, shell, and application — is described in
YAML and generated from that description into RTL decoders, software headers, and
documentation.

The address map is hierarchical:

| Region | Contents |
|---|---|
| Shell configuration | Shell-level control and status |
| Hardware | Platform-specific blocks — MACs, transceivers, device identity |
| Core | Application register window: P4 tables, counters, application logic |

Generating both hardware and software sides from one description prevents the driver,
test suite, and hardware from diverging, and keeps the map structurally identical
across UltraScale+ and Versal.

Register access reaches the design over the ESnet PCIe endpoint (§6.1), so the
control plane is independent of AVED's management path.

---

## 7. Build and delivery

### 7.1 Artifacts

A build invoked from an application directory produces:

| Artifact | Purpose |
|---|---|
| Device image (PDI) | The programmable image loaded onto the card |
| Firmware bundle | Device image combined with on-card management firmware |
| Register package | Generated headers and documentation |
| P4 table driver | Generated control-plane code for the P4 pipelines |
| Hardware API package | Versioned bundle consumed by the firmware and software builds |

The hardware API package is the handoff point between the hardware and software
builds. It is versioned, produced by CI, and carries the platform fingerprint that
allows software to verify what it is running against.

### 7.2 Build flow

```
   Shell compile          Core compile
   (slow, stable)         (fast, per-application)
         │                      │
         └──────────┬───────────┘
                    ▼
               Assembly and
              implementation
                    │
                    ▼
            Device image + firmware
                    │
                    ▼
            Hardware API package
```

Assembly is incremental: a change re-runs only the implementation stages affected by
it.

### 7.3 Continuous integration

Each application is built in CI on every change, producing the full artifact set.
Successful hardware builds trigger the downstream firmware pipeline, so a hardware
change propagates to a testable firmware image without manual intervention.

Adding an application to CI requires declaring three jobs — build, package, firmware —
following the established pattern.

---

## 8. Implementation phases

Each phase produces a testable result. Phases 2 and 3 are independent of each other
once Phase 1 is complete. Phases 5 and 6 are off the critical path; see Sequencing
below.

### Phase 1 — Platform foundation

Bring up the card with AVED, establish the bifurcated PCIe endpoint, and verify the
control plane end to end: host software enumerates the device, reads and writes
registers, and programs the card.

*Result:* a card that boots, is manageable, and is addressable from the host.
*Unblocks:* all subsequent phases.

### Phase 2 — Host datapath

Connect the CPM5 QDMA block through the shell to the core in both directions with the
full queue model. Verify against the existing host software.

*Result:* packets moving between host memory and the fabric at Gen5 rates.
*Unblocks:* application bring-up and loopback testing without network hardware.

### Phase 3 — Network datapath

Integrate DCMAC and the associated transceivers, bring the physical ports up, and
connect them to the core's port interfaces.

*Result:* a functioning network interface.
*Unblocks:* end-to-end traffic testing and performance measurement.

### Phase 4 — Application bring-up

Bring the SmartNIC core and its P4 pipelines up on the Versal platform. Because the
core targets the platform-independent interface (§5), this is integration and
validation rather than porting.

*Result:* the ESnet application running on Versal.

### Phase 5 — HBM bring-up

Bring up the V80 HBM subsystem and make it available to the core: configure the
memory controllers, establish the access path from the fabric, and characterise
bandwidth and latency.

*Result:* HBM accessible from the core, with measured performance figures.
*Unblocks:* Phase 6 and any other application use of high-bandwidth memory.

### Phase 6 — Egress queueing (optional capability)

Connect the egress queueing subsystem to HBM and characterise buffering and
scheduling behaviour at the operational line rate.

*Result:* egress queueing available to applications that select it. Applications that
do not use it are unaffected, so this phase does not gate their deployment.

### Phase 7 — Parity and performance validation

Compare against the UltraScale+ deployment for feature parity, throughput, latency,
and stability under sustained load. Resolve behavioural differences.

*Result:* sign-off that Versal is a supported deployment target.

### Sequencing

```
Phase 1  Platform foundation
   ├──► Phase 2  Host datapath ────┐
   └──► Phase 3  Network datapath ─┤
                                   └──► Phase 4  Application bring-up
                                             │
                                             ├──► Phase 7  Validation
                                             │
                                             └──► Phase 5  HBM bring-up
                                                      │
                                                      └──► Phase 6  Egress queueing
                                                                    (optional)
```

Phases 5 and 6 are off the critical path for applications that do not use egress
queueing or HBM. Where an application does use them, its validation falls within
Phase 7.

---

## 9. Completion criteria

Versal is a supported deployment target when all of the following hold:

1. **Functional parity** — every feature available on the UltraScale+ deployment is
   available on Versal, verified by the common test suite.
2. **Application portability** — the SmartNIC core builds and runs on both platforms
   from one source, with no platform-specific application code.
3. **Software unification** — one host software stack supports both platforms; the
   register map and DMA queue model are consistent across them.
4. **Performance** — at least 2 × 100G line rate sustained (matching UltraScale+),
   with host bandwidth characterised and documented. Where egress queueing is enabled,
   its buffering and scheduling behaviour is characterised at the operational rate.
5. **Automated delivery** — CI produces the complete artifact set for every
   application on every change and triggers the firmware pipeline.
6. **Operational readiness** — board management, monitoring, and field programming
   are functional and documented.

---

## 10. Related documents

| Document | Scope |
|---|---|
| `src/shell/doc/shell.md` | The shell/core abstraction and interface contract |
