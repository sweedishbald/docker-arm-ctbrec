FROM rpi-alpine as open-m3u8Git
WORKDIR /app
RUN git clone https://github.com/0xboobface/open-m3u8.git

FROM gradle:4.10-jdk10 as open-m3u8Build
WORKDIR /app/open-m3u8
COPY --from=open-m3u8Git --chown=gradle:gradle /app /app
RUN gradle install

FROM rpi-alpine as ctbrecGit
WORKDIR /app
RUN git clone https://github.com/0xboobface/ctbrec.git

FROM maven:3-jdk-11-slim as ctbrecBuild
ARG ctbrec
ARG versionM3u8
WORKDIR /app/master
COPY --from=ctbrecGit /app/ctbrec /app
COPY --from=open-m3u8Build /app/open-m3u8/build/libs/ /app/common/libs/
RUN mvn clean install:install-file -Dfile=/app/common/libs/open-m3u8-${versionM3u8}.jar  -DgroupId=com.iheartradio.m3u8 -DartifactId=open-m3u8 -Dversion=${versionM3u8} -Dpackaging=jar -DgeneratePom=true
RUN mvn clean
RUN mvn install

FROM openjdk:12-alpine
WORKDIR /app
ARG memory
ARG version
ENV artifact ctbrec-server-${version}-final.jar
ENV path /app/server/target/${artifact}
COPY --from=ctbrecBuild ${path} ./${artifact}
EXPOSE 8080
CMD java ${memory} -cp ${artifact} -Dctbrec.config=/server.json ctbrec.recorder.server.HttpServer
