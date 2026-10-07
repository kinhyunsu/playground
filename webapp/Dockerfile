# 1) 헬퍼 클래스 + 의존성(JDBC 드라이버, Gson) 빌드
FROM maven:3.9-eclipse-temurin-11 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src/main/java src/main/java
RUN mvn -q -B package -DskipTests

# 2) Tomcat 9 (javax.servlet, JSP 2.3 → 대부분의 레거시 환경과 동일)
FROM tomcat:9.0-jdk11-temurin
ENV JAVA_OPTS="-Dfile.encoding=UTF-8 -Duser.timezone=Asia/Seoul"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /build/target/lib/*.jar /usr/local/tomcat/lib/
COPY --from=build /build/target/playground-core-*.jar /usr/local/tomcat/lib/
# 실제 JSP는 docker-compose에서 webapps/ROOT로 마운트됩니다 (수정 즉시 반영).
# 마운트 없이 단독 실행할 때를 위해 이미지에도 복사해 둡니다.
COPY src/main/webapp /usr/local/tomcat/webapps/ROOT
EXPOSE 8080
CMD ["catalina.sh", "run"]
