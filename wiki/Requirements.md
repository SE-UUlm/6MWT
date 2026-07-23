# Requirements

This page documents the functional and non-functional requirements of the 6MWT application.

## Functional Requirements

### FR1 – Walk Test Execution

The application shall support the complete execution of a Six-Minute-Walk Test.

The test shall
- be started manually
- run for exactly six minutes
- stop automatically after six minutes
- allow the user to pause the test at any time
- allow the user to abort the test at any time


### FR2 – GPS Tracking

The application shall continuously receive GPS position updates during an active walk test. For this project, GPS is the primary sensor used for distance estimation.


### FR3 – Distance Estimation

The application shall estimate the walked distance from the recorded GPS positions.


### FR4 – Live Test Information

During an active walk test the application shall display
- remaining test time
- an indication when GPS signal is temporarily lost (see [FR9](#fr9--temporary-signal-loss-handling))


### FR5 – Sensor Data Recording

The application shall record every received sensor sample during a walk test.

Each sample shall contain
- timestamp
- sensor type
- sensor source
- measured values
- session identifier

The recorded data shall be stored locally for later analysis.


### FR6 – Session Management

Each walk test shall receive a unique session identifier. All recorded sensor data shall be associated with the corresponding session.


### FR7 – GPS Plausibility Checks

The application shall validate incoming GPS measurements before they contribute to the calculated walking distance.

Validation criteria shall include
- implausible position jumps
- unrealistic walking speeds
- poor GPS accuracy (below a defined threshold)
- duplicate measurements

Measurements that fail validation shall be flagged and excluded from the distance calculation, but still be recorded raw (see [FR5](#fr5--sensor-data-recording)) for later analysis.


### FR8 – Robust Distance Estimation

The distance estimation shall remain functional when individual GPS measurements are flagged as implausible by [FR7](#fr7--gps-plausibility-checks).

The application shall apply a defined strategy (e.g. interpolation, smoothing, or exclusion) to compensate for excluded or missing measurements, so that short-term GPS inaccuracies do not significantly distort the calculated distance.


### FR9 – Temporary Signal Loss Handling

Temporary GPS signal loss shall not terminate an active walk test. The application shall continue recording as soon as valid GPS measurements become available again, and shall inform the user while no signal is available.


### FR10 – Sensor Interface

The application shall define a common sensor interface that all sensor sources (including GPS) implement, so that additional sensor sources can be integrated without changes to the walk test logic.

Possible future sensors include
- step counter
- heart rate monitor
- smartwatch sensors
- Health Connect / Apple Health


### FR11 – Background Execution

An active walk test shall continue running while the application is in the background or the device is locked, including continued GPS tracking and sensor data recording.


### FR12 – Fitness Assessment

After completion of the walk test, the application shall provide a basic fitness assessment based on the measured walking distance (e.g. classification against reference values).


### FR13 – Data Export

The application shall allow the user to export recorded session data (e.g. as CSV or JSON) for external analysis.


### FR14 – Error Handling

The application shall handle unexpected errors (e.g. application crash, unexpected termination) during an active walk test gracefully.

If the application is restarted after an unexpected termination during an active session, it shall inform the user about the interrupted session and shall not silently lose already recorded data (see [FR5](#fr5--sensor-data-recording)).


### FR15 – Session Management (Deletion)

The application shall allow the user to view a list of previously recorded sessions and to delete individual sessions and their associated data.


### FR16 – Onboarding / Instructions

The application shall provide an onboarding sequence that explains, before the first use of the test, what the Six-Minute-Walk Test is, what data is required, how the test is carried out, and how results are presented.


### FR17 – Start Screen

The application shall provide a start screen giving an overview of the test and allowing the user to start a new test.


### FR18 – Patient Data Input

Before a walk test is started, the application shall allow the user to enter patient information required for the fitness assessment ([FR12](#fr12--fitness-assessment)), consisting of
- name
- age
- gender
- height
- weight


### FR19 – Test Preparation Screen

Before a walk test is started, the application shall provide a screen with preparation instructions for correctly carrying out the test (e.g. video instructions).


### FR20 – Timer / Active Test Screen

During an active walk test, the application shall provide a screen displaying the information defined in [FR4](#fr4--live-test-information), and allowing the user to pause or abort the test (see [FR1](#fr1--walk-test-execution)). Aborting the test shall require the user to confirm the action before the test is cancelled.


### FR21 – Test Results Screen

After completion of a walk test, the application shall provide a screen displaying the test results, including the walked distance and the fitness assessment defined in [FR12](#fr12--fitness-assessment).


## Non-Functional Requirements

### NFR1 – Modularity & Separation of Concerns

The application shall follow a modular architecture that separates sensor sources, business logic, persistence, and presentation. Presentation, application logic, and data persistence shall remain independent to improve maintainability and testability.



### NFR2 – Extensibility

Adding new sensor sources (via the interface defined in [FR10](#fr10--sensor-interface)) or new distance estimation algorithms (see [FR3](#fr3--distance-estimation)) shall require only minimal changes to the existing code base.



### NFR3 – Testability

Core application logic shall remain independent of Flutter widgets wherever possible, to facilitate automated testing.



### NFR4 – Performance

Recording high-frequency sensor data shall not block the user interface or noticeably delay the display of live test information ([FR4](#fr4--live-test-information)).



### NFR5 – Reliability

Failure of optional sensor sources shall not prevent the execution of a walking test. Recorded data shall not be lost in the event of an application crash during an active session.



### NFR6 – Data Persistence

Raw sensor data shall be stored locally in a format suitable for later evaluation, algorithm development, and debugging.



### NFR7 – Usability

The application shall explain the procedure of the walk test to the user before it is started (via an instruction/explanation screen), so that a first-time user can start and conduct the test without external instructions.



### NFR8 – Maintainability / Logging

The application shall log key events (e.g. test start/stop, sensor errors, GPS status changes) with severity levels (e.g. debug, info, error) to simplify debugging, performance analysis, and future development.



### NFR9 – Privacy & Data Protection

Location data recorded during a walk test shall remain stored locally on the device by default and shall not be transmitted to external services without explicit user consent.



### NFR10 – Energy Efficiency

Continuous GPS tracking and background execution ([FR11](#fr11--background-execution)) shall be implemented so as to avoid excessive battery drain during a six-minute session.



### NFR11 – Platform Compatibility

The application shall support a defined minimum set of Android and iOS versions.

