# App creation
- mn create-app --build=maven --jdk=21 --lang=java com.flyway.docker.multi-flyway-docker

# Dependencies
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

# Plugins
- The plugins are what Maven uses during build to make Micronaut’s annotation processing and runtime possible.

| Plugin                                           | Usage                                                                                                                                                                                                                      |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `io.micronaut.maven:micronaut-maven-plugin`      | Adds Micronaut build support (AOT optimizations, running the app via `mvn mn:run`, packaging into native images if configured). Uses `aot-${packaging}.properties` as its config file.                                     |
| `org.apache.maven.plugins:maven-enforcer-plugin` | Enforces build rules (e.g., Java version, dependency convergence). Micronaut parent usually sets rules like `requireJavaVersion`.                                                                                          |
| `org.apache.maven.plugins:maven-compiler-plugin` | Configures Java compilation. Adds Micronaut’s annotation processors (`micronaut-http-validation`, `micronaut-serde-processor`) so Micronaut can generate DI code, HTTP routing, and serialization classes at compile time. |


# Convert project to parent pom
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

# Important decision to make
The two ways to run Flyway migrations in Micronaut

1. ### **Migrations run automatically at app startup** (when the Micronaut context is created).


    - add micronaut-flyway dependency 
    - ./mvnw -pl service-db-access mn:run
    - This gives you Micronaut features (DI, multiple datasources, logging, etc.), but requires the app runtime to be brought up just to apply migrations.
    - by setting enable: true in flyway config
  
2. ### **Run migrations directly with Maven** - Flyway Maven Plugin (independent of Micronaut)


    - configure the Flyway Maven plugin in service-db-access/pom.xml. 
    - ./mvnw -pl service-db-access flyway:migrate 
    - This will:
        - Connect to the DB 
        - Run any pending migrations from src/main/resources/db/migration/... 
        - Exit immediately (no Micronaut runtime needed). 
        - Good for CI/CD pipelines where you want migrations to run before app deployment.
        - ./mvnw -pl service-db-access flyway:info # show pending/applied migrations 
        - ./mvnw -pl service-db-access flyway:migrate  # apply migrations

## **How micronaut-flyway triggers migrations at startup**
1. ### **Add the dependency in pom.xml** : io.micronaut.flyway:**micronaut-flyway**
   - This brings in Micronaut beans (FlywayConfigurationProperties, FlywayMigrator, DataSourceMigrationRunner etc.).
2. ### **Micronaut starts app** (mn:run or packaged JAR)
   - The Application class starts
   - MN's **ApplicationContext** is created. 
   - During Context initialization, MN scans all beans
3. ### **DataSourceMigrationRunner** bean (provided by micronaut-flyway) gets initialized
   - It listens for DataSource creation events.
   - When Micronaut creates your DB connection pool (via micronaut-jdbc-hikari), this bean kicks in.
4. ### The DataSourceMigrationRunner calls **Flyway.migrate()** under the hood.
   - It uses configs from application.yml (datasource URL, username, password, migration locations).
   - All .sql scripts under classpath:db/migration are applied in order (V1__xxx.sql, V2__xxx.sql, etc.).
5. ### **App continues startup**
   - Once migrations complete successfully, Micronaut continues wiring the rest of the beans. 
   - @Controllers and @Repositorys are now working against the migrated schema.

## **How maven triggers flyway migrations**
1. Add the Flyway Maven plugin

       <plugin>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-maven-plugin</artifactId>
        <version>10.10.0</version>
        <configuration>
          <url>jdbc:oracle:thin:@localhost:1521/XEPDB1</url>
          <user>myuser</user>
          <password>mypassword</password>
          <locations>
            <location>classpath:db/migration/oracle</location>
          </locations>
        </configuration>
       </plugin>
2. Place migration scripts under - service-db-access/src/main/resources/db/migration/oracle/
3. Run migrations with Maven - `./mvnw -pl service-db-access flyway:migrate`
   - What happens:
      - Maven invokes the Flyway plugin in the service-db-access module. 
      - Flyway connects to your DB (url, user, password). 
      - It checks the special Flyway schema history table (flyway_schema_history). 
      - It runs any pending migration scripts in order (V1, V2, …).
      - It records applied migrations in flyway_schema_history.
4. Useful maven goals
   - Show current migration status: `./mvnw -pl service-db-access flyway:info`
   - Apply migrations: `./mvnw -pl service-db-access flyway:migrate`
   - Clean schema (⚠️ drops all objects): `./mvnw -pl service-db-access flyway:clean`
     - **[ERROR]** Failed to execute goal org.flywaydb:flyway-maven-plugin:10.10.0:clean (default-cli) on project service-db-access: org.flywaydb.core.api.FlywayException: Unable to execute clean as it has been disabled with the 'flyway.cleanDisabled' property.
     - ./mvnw -pl service-db-access flyway:clean **-Dflyway.cleanDisabled=false**
   - Validate checksums of applied migrations: `./mvnw -pl service-db-access flyway:validate`
5. Why this is useful
   - Runs completely independent of Micronaut.
   - Great for CI/CD → you can have a step like:
     - ./mvnw -pl service-db-access flyway:migrate -Dflyway.url=$DB_URL -Dflyway.user=$DB_USER -Dflyway.password=$DB_PASS
   - Ensures DB schema is always in sync before deploying your app.


## So what’s the difference? 

### **Micronaut runner (micronaut-flyway)**

    - Migrations run every time your service (or migration app) starts. 
    - Tied to Micronaut lifecycle. 
    - Great for local dev (auto-migrate when app runs).

### **Maven plugin (flyway-maven-plugin)**

    - Migrations run on demand from the command line or in CI/CD. 
    - Doesn’t require Micronaut runtime. 
    - Great for automated DB migration steps in pipelines.

### **Recommended pattern in multi-module setup** 
    - Keep service-app as your actual Micronaut web service. 
    - Use service-db-access as a migration-only module. 
    - Add the Flyway Maven plugin there. 
    - Run migrations via: ./mvnw -pl service-db-access flyway:migrate 
    - No need to run a Micronaut context just for schema changes. 
    - This way, DB migrations are decoupled from your app runtime.


### Dockerize study-db-access
- base image : https://docker-integration.cernerrepos.net/ui/repos/tree/General/docker-integration/healtheintent/flyway-ol8/9-java17-20250826T115028Z
- build docker image: `./mvnw -pl service-db-access docker:build`
- check entry point - it should be migrate.sh: `docker inspect docker-integration.cernerrepos.net/healtheintent/service-db-access:latest --format='{{.Config.Entrypoint}}'`
  - [/opt/java-base/migration/migrate.sh]
- login to image : `docker run --rm -it --entrypoint sh docker-integration.cernerrepos.net/healtheintent/service-db-access:latest`
  - migrate.sh copied to this location : `cat /opt/java-base/migration/migrate.sh`
- run docker image: `docker run --rm \
  -e DB_USERNAME=study_user \
  -e DB_PASSWORD=Study1234 \
  -e DB_URL=jdbc:oracle:thin:@host.docker.internal:1521/XEPDB1 \
  docker-integration.cernerrepos.net/healtheintent/service-db-access:latest`

### Dockerize study-app
- base image: 
  - docker.cernerrepos.net/healtheintent/graal-ol8:21.0.4-graal-20250826T120926Z
  - https://docker-integration.cernerrepos.net/ui/repos/tree/General/docker-integration/healtheintent/graal-ol8/21.0.4-graal-20250826T120926Z
- build docker image: `./mvnw -pl service-app jib:dockerBuild`
- run docker image: `docker run --rm -p 8080:8080 \
  -e DATASOURCES_DEFAULT_URL=jdbc:oracle:thin:@host.docker.internal:1521/XEPDB1 \
  -e DATASOURCES_DEFAULT_USERNAME=study_user \
  -e DATASOURCES_DEFAULT_PASSWORD=Study1234 \
  docker-integration.cernerrepos.net/healtheintent/service-app:latest`

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


