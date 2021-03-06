#!/usr/bin/env bash
################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

HERE="`dirname \"$0\"`"				# relative
HERE="`( cd \"${HERE}\" && pwd )`" 	# absolutized and normalized
if [ -z "${HERE}" ] ; then
	# error; for some reason, the path is not accessible
	# to the script (e.g. permissions re-evaled after suid)
	exit 1  # fail
fi

ARTIFACTS_DIR="${HERE}/artifacts"
FLINK_DIR="${HERE}/flink"

mkdir -p $ARTIFACTS_DIR || { echo "FAILURE: cannot create log directory '${ARTIFACTS_DIR}'." ; exit 1; }

LOG4J_PROPERTIES=${FLINK_DIR}/tools/log4j-travis.properties

MVN_LOGGING_OPTIONS="-Dlog.dir=${ARTIFACTS_DIR} -Dlog4j.configuration=file://$LOG4J_PROPERTIES -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"
MVN_COMPILE_OPTIONS="-nsu -B -Dflink.forkCount=2 -Dflink.forkCountTestPackage=2 -Dmaven.javadoc.skip=true -DskipTests -Dcheckstyle.skip=true -Djapicmp.skip=true -Drat.skip=true"
MVN_COMPILE="mvn ${MVN_COMPILE_OPTIONS} ${MVN_LOGGING_OPTIONS} ${PROFILE} clean install"

git clone https://github.com/apache/flink

cd "${FLINK_DIR}"

eval "${MVN_COMPILE}"
EXIT_CODE=$?

if [ $EXIT_CODE == 0 ]; then
	printf "\n\n==============================================================================\n"
	printf "Running end-to-end tests\n"
	printf "==============================================================================\n"

	FLINK_DIR=build-target flink-end-to-end-tests/run-nightly-tests.sh

	EXIT_CODE=$?
else
	printf "\n\n==============================================================================\n"
	printf "Compile failure detected, skipping end-to-end tests\n"
	printf "==============================================================================\n"
fi

# Exit code for Travis build success/failure
exit ${EXIT_CODE}
