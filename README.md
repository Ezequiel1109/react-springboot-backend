Descripción general
Proyecto backend REST API desarrollado en Spring Boot 3.5.7 con Java 21, orientado a gestión de productos con funcionalidades de autenticación JWT y testing avanzado con Testcontainers.

Stack tecnológico principal
Framework base:

Spring Boot 3.5.7 (parent)
Java 21 (JDK target)
Dependencias core de Spring:

Spring Boot Web - REST controllers y endpoints
Spring Data JPA - acceso a datos con repositorios
Spring Boot Security - autenticación y autorización
Spring Boot Validation - validación de DTOs con anotaciones
Spring Boot Actuator - métricas y health checks
Spring Boot Data REST - exposición automática de repositorios

Base de datos
MySQL (mysql-connector-j) como BD principal
JPA/Hibernate para ORM

Seguridad
JWT (JSON Web Tokens) para autenticación stateless:
jjwt-api, jjwt-impl, jjwt-jackson (versión 0.12.3)
Spring Security integrado

Documentación
SpringDoc OpenAPI 3 (v2.7.0) - generación automática de documentación Swagger/OpenAPI

Testing (robusto)
JUnit 5 Jupiter (v5.12.2) - framework de testing moderno
Spring Boot Test - testing de integración con Spring
Testcontainers (v1.19.0) - contenedores Docker para testing:
Testcontainers core
Testcontainers JUnit Jupiter integration
Testcontainers MySQL - BD real en tests de integración
Maven Surefire - ejecución de unit tests
Maven Failsafe - ejecución de integration tests (*IT.java)

Herramientas de desarrollo
Spring Boot DevTools - hot reload en desarrollo
Maven como build tool
Configuración optimizada de plugins (compiler, surefire, failsafe)

Características destacadas del setup
Separación clara entre unit tests (Surefire) e integration tests (Failsafe)
Exclusión de JUnit Vintage - solo JUnit 5 Jupiter
BOM de JUnit para alineación de versiones y evitar conflictos
Testcontainers para testing con BD real (MySQL en Docker)
Configuración robusta de logging y output en tests

Arquitectura implícita
API REST con controllers
Patrón Repository con Spring Data JPA
DTOs para transferencia de datos
Autenticación JWT sin estado
Testing de integración con contenedores reales
Documentación automática con OpenAPI/Swagger
