## App creation
- mn create-app --build=maven --jdk=21 --lang=java com.flyway.docker.multi-flyway-docker

## Dependencies
- The dependencies are what you need at runtime (server, JSON, logging) and test time (JUnit, Micronaut Test, HTTP client).

| Dependency                                   | Scope   | Usage                                                                                                                                      |
| -------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `io.micronaut:micronaut-http-server-netty`   | compile | Embedded Netty HTTP server for running the app as a web service (handles incoming HTTP requests).                                          |
| `io.micronaut.serde:micronaut-serde-jackson` | compile | JSON serialization/deserialization using Micronaut’s compile-time serializer (Jackson-compatible). Required to send/receive JSON payloads. |
| `ch.qos.logback:logback-classic`             | runtime | Logging backend (SLF4J implementation). Writes logs to console/file.                                                                       |
| `io.micronaut:micronaut-http-client`         | test    | HTTP client for testing controllers/endpoints (often used with `@MicronautTest`).                                                          |
| `io.micronaut.test:micronaut-test-junit5`    | test    | JUnit 5 integration for Micronaut. Provides `@MicronautTest` to start an embedded application context/server in tests.                     |
| `org.junit.jupiter:junit-jupiter-api`        | test    | JUnit 5 annotations (`@Test`, `@BeforeEach`) and assertions. Compile-time API.                                                             |
| `org.junit.jupiter:junit-jupiter-engine`     | test    | JUnit 5 runtime engine that executes the tests.                                                                                            |

## Plugins
- The plugins are what Maven uses during build to make Micronaut’s annotation processing and runtime possible.

| Plugin                                           | Usage                                                                                                                                                                                                                      |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `io.micronaut.maven:micronaut-maven-plugin`      | Adds Micronaut build support (AOT optimizations, running the app via `mvn mn:run`, packaging into native images if configured). Uses `aot-${packaging}.properties` as its config file.                                     |
| `org.apache.maven.plugins:maven-enforcer-plugin` | Enforces build rules (e.g., Java version, dependency convergence). Micronaut parent usually sets rules like `requireJavaVersion`.                                                                                          |
| `org.apache.maven.plugins:maven-compiler-plugin` | Configures Java compilation. Adds Micronaut’s annotation processors (`micronaut-http-validation`, `micronaut-serde-processor`) so Micronaut can generate DI code, HTTP routing, and serialization classes at compile time. |


## Convert project to parent pom
1. change packaging to pom for root
   - root: pom
   - service-app: jar
   - service-db-access: jar
2. Add <modules> section:
   - service-app
   - db-access
3. moved src/, pom.xml, aot-jar.properties, micronaut-cli.yml into service-app folder
4. Updated both module pom - added parent (root pom)
   - declare Micronaut BOM once in the root → all child modules use consistent versions. 
   - Child modules only reference the root POM. 
   - If Micronaut version changes (e.g. 4.9.4), you only update it in root, not in every module.
5. Moved following runtime, compile time and test dependencies to service-app pom.xml
   - micronaut-http-server-netty
   - micronaut-serde-jackson
   - logback-classic
   - micronaut-http-client (test scope)
   - micronaut-test-junit5 (test scope)
   - junit-jupiter-api (test scope)
   - junit-jupiter-engine (test scope)
6. Moved Micronaut plugin for mn:run, AOT, native builds to service-app pom.xml
   - io.micronaut.maven:micronaut-maven-plugin
7. Kept other 2 plugins in the root pom
   - Root: enforcer + compiler (shared across all). 
   - service-app: micronaut-maven-plugin (run/app build). 
   - service-db-access: optional Micronaut plugin, usually just Flyway.
    
## Micronaut 4.9.3 Documentation

- [User Guide](https://docs.micronaut.io/4.9.3/guide/index.html)
- [API Reference](https://docs.micronaut.io/4.9.3/api/index.html)
- [Configuration Reference](https://docs.micronaut.io/4.9.3/guide/configurationreference.html)
- [Micronaut Guides](https://guides.micronaut.io/index.html)
---

- [Micronaut Maven Plugin documentation](https://micronaut-projects.github.io/micronaut-maven-plugin/latest/)
## Feature serialization-jackson documentation

- [Micronaut Serialization Jackson Core documentation](https://micronaut-projects.github.io/micronaut-serialization/latest/guide/)


## Feature micronaut-aot documentation

- [Micronaut AOT documentation](https://micronaut-projects.github.io/micronaut-aot/latest/guide/)


## Feature maven-enforcer-plugin documentation

- [https://maven.apache.org/enforcer/maven-enforcer-plugin/](https://maven.apache.org/enforcer/maven-enforcer-plugin/)


