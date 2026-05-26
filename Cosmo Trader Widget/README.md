# Future Widget Scope

The files in this folder are future-scope widget prototypes. They are not part
of the v1 app because the Xcode project has no widget extension target, no app
group entitlement, and no widget capability wiring.

Do not add these files to the app target. Before enabling widgets, create a
proper Widget Extension target, add the required App Group entitlement to both
targets, verify real-device data sharing, and update release QA to include the
extension bundle.
