#!/bin/bash

# This file is an audit tool for the migration.
# It may be deleted befor the PR is merged.
# Usage:
#   MIGRATE_SH=./airbyte-cdk/java/airbyte-cdk/_temp_migration_script.sh
#   $MIGRATE_SH <OLD_PACKAGE_ROOT> <SUBPACKAGE_PATH>
#
# Core capabilities:
#   $MIGRATE_SH airbyte-db/db-lib db
#   $MIGRATE_SH airbyte-integrations/bases/base-java
#   $MIGRATE_SH airbyte-integrations/bases/base-java-s3
#   $MIGRATE_SH airbyte-integrations/bases/base-typing-deduping
#   $MIGRATE_SH airbyte-integrations/bases/debezium
#
# Abstract DB connectors:
#   $MIGRATE_SH airbyte-integrations/connectors/source-jdbc
#   $MIGRATE_SH airbyte-integrations/connectors/source-relational-db
#   $MIGRATE_SH airbyte-integrations/bases/bases-destination-jdbc
#
# Test capabilities:
#   $MIGRATE_SH airbyte-integrations/bases/base-typing-deduping-test
#   $MIGRATE_SH airbyte-integrations/bases/s3-destination-base-integration-test
#   $MIGRATE_SH airbyte-integrations/bases/standard-destination-test
#   $MIGRATE_SH airbyte-integrations/bases/standard-source-test
#   $MIGRATE_SH airbyte-test-utils
#
# Post-run cleanup stesps:
# - Find and delete references to the moved packages.
# - Add the new airbyte-java-connector plugin to connectors' build.gradle files.
# - Search-and-replace:
#   - Within /airbyte-cdk/java/airbyte-cdk:
#     - Find:         `package io.airbyte`
#     - Replace with: `package io.airbyte.cdk`
#   - Within /airbyte-cdk/java/airbyte-cdk (because the above is not idempotent):
#     - Find:         `package io.airbyte.cdk.cdk`
#     - Replace with: `package io.airbyte.cdk`
#   - Find all the packages that were moved, and name them in a way that is specific to the CDK inclusions:
#     - Find (regex): `io.airbyte...` # Everything that now shows up with a search for `package io.airbyte.cdk`
#                      io.airbyte.db
#                      io.airbyte.integrations.base
#                      io.airbyte.integrations.debezium
#                      io.airbyte.integrations.destination.NamingConventionTransformer
#                      io.airbyte.integrations.destination.StandardNameTransformer
#                      io.airbyte.integrations.destination.jdbc
#                      io.airbyte.integrations.destination.normalization
#                      io.airbyte.integrations.destination.record_buffer
#                      io.airbyte.integrations.destination.s3
#                      io.airbyte.integrations.destination.buffered_stream_consumer
#                      io.airbyte.integrations.destination.dest_state_lifecycle_manager
#                      io.airbyte.integrations.destination.staging
#                      io.airbyte.integrations.destination_async
#                      io.airbyte.integrations.standardtest
#                      io.airbyte.integrations.source.jdbc
#                      io.airbyte.integrations.source.relationaldb
#                      io.airbyte.integrations.util
#                      io.airbyte.integrations.BaseConnector
#                      io.airbyte.test.utils
#   - Within rest of repo:
#     - Find (regex) based on the above list:
#         io\.airbyte\.(db|integrations\.base|integrations\.debezium|integrations\.destination\.NamingConventionTransformer|integrations\.destination\.StandardNameTransformer|integrations\.destination\.jdbc|integrations\.destination\.normalization|integrations\.destination\.record_buffer|integrations\.destination\.s3|integrations\.destination\.buffered_stream_consumer|integrations\.destination\.dest_state_lifecycle_manager|integrations\.destination\.staging|integrations\.destination_async|integrations\.standardtest|integrations\.source\.jdbc|integrations\.source\.relationaldb|integrations\.util|integrations\.BaseConnector|test\.utils)
#     - Replace with: `io.airbyte.cdk.$1`
#     - Exclude files: _temp_migration_script.sh,*.html,build,bin
# - Replace references to the moved packages with the new package names.

# Other notes:
# - This script is idempotent. It should become a no-op if run to completion.
# - The "typing_deduping" and "typing_deduping_test" subpackages are special cases. They migrated from different directories while being declared as the same package name: "io.airbyte.integrations.destination.typing_deduping".

# Change these two lines for each new subpackage to move
OLD_PACKAGE_ROOT="$1"

# These lines should not need to be changed
OLD_SRC_PATH="$OLD_PACKAGE_ROOT/src/main/java/io/airbyte"
OLD_TEST_PATH="$OLD_PACKAGE_ROOT/src/test/java/io/airbyte"

CDK_ROOT="airbyte-cdk/java/airbyte-cdk"
DEST_MAIN="$CDK_ROOT/src/main/java/io/airbyte/cdk"
DEST_TEST="$CDK_ROOT/src/test/java/io/airbyte/cdk"

echo -e "Moving files (ignoring existing)... \n - From: $OLD_SRC_PATH\n - To:   $DEST_MAIN"
# find "$OLD_SRC_PATH/" -type f | head
mkdir -p "$DEST_MAIN/"
rsync -av --ignore-existing --remove-source-files "$OLD_SRC_PATH" "$DEST_MAIN"

echo -e "Moving files (ignoring existing)... \n - From: $OLD_TEST_PATH\n - To:   $DEST_TEST"
# find "$OLD_TEST_PATH/" -type f | head
mkdir -p "$DEST_TEST/"
rsync -av --ignore-existing --remove-source-files "$OLD_TEST_PATH/" "$DEST_TEST/"

# Remove empty directories in the OLD_PACKAGE_ROOT
find "$OLD_PACKAGE_ROOT/" -type d -empty -delete

# List remnant files in the OLD_PACKAGE_ROOT
echo "Files remaining in $OLD_PACKAGE_ROOT:"
find "$OLD_PACKAGE_ROOT" -type f

# Move remaining files in the OLD_PACKAGE_ROOT to the CDK 'archive' directory
ARCHIVE_ROOT="airbyte-cdk/java/airbyte-cdk/archive"
echo -e "Moving renaming files... \n - From: $OLD_PACKAGE_ROOT\n - To:   $ARCHIVE_ROOT"

# Ensure the parent directory exists
mkdir -p "$ARCHIVE_ROOT/"

# Move the entire remnants of `base-java` to the archived directory
mv "$OLD_PACKAGE_ROOT/" "$ARCHIVE_ROOT/"
