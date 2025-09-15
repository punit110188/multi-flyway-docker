FROM docker.cernerrepos.net/healtheintent/flyway-ol8:9-java17-20250826T115028Z
COPY maven /opt/java-base
ENTRYPOINT ["/opt/java-base/migration/migrate.sh"]