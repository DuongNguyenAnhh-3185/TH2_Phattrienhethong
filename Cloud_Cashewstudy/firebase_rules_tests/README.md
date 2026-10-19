# Firebase Rules Tests

These tests run against local Firestore and Storage emulators. They use a demo
project ID and do not access or modify the deployed Firebase project.

Requirements: Node.js 20 or newer and JDK 21 or newer.

From this directory, run:

```powershell
npm install
npm test
```

If `java` on `PATH` is older than 21, set `JAVA_HOME` and prepend its `bin`
directory to `PATH` before running `npm test`.