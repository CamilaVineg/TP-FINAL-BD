# Comics Archive — TP Integrador Final de Base de Datos

Trabajo Integrador Final de la asignatura **Base de Datos** (Lic. en Sistemas de Información).

**Comics Archive** es el sistema de gestión para una empresa de archivado de cómics. Permite
administrar el catálogo completo de cómics, organizarlos de forma ordenada y registrar todas las
versiones (issues, runs y portadas) disponibles, junto con métricas de popularidad y ventas.

## Integrantes

- Rochás Tadeo
- Pérez Sofía
- Poggio Abril
- Viñeg Camila

## Objetivos del trabajo

1. Definir el **modelo lógico** y el **modelo relacional** de la base de datos (normalizado hasta 3FN).
2. Elaborar el **diccionario de datos** y los **triggers** correspondientes.
3. Generar y verificar los scripts de creación, carga, consulta, seguridad y pruebas de la base:
   - Script de creación de la base de datos y dominios (DDL).
   - Script de creación de triggers.
   - Script de carga de datos.
   - Script de creación de funciones.
   - Script de vistas y consultas.
   - Script de creación de roles y usuarios.
   - Script de pruebas de triggers.
   - Script de pruebas de funciones.

## Modelo de datos

### Entidades principales

| Clase | Descripción |
| --- | --- |
| **Persona** | Superclase que centraliza los datos personales e históricos de todos los creadores. |
| **Autor** | Escritores y guionistas de la narrativa (creadores originales o de arcos específicos). |
| **Artista** | Profesionales del apartado visual: dibujantes, entintadores y coloristas. |
| **Empresa** | Catálogo de casas editoriales dueñas de las licencias y responsables de la publicación. |
| **Comic** | Título o franquicia a nivel macro; consolida popularidad y ventas a partir de sus runs. |
| **Run** | Arco argumental, volumen o etapa cronológica consecutiva dentro de un cómic. |
| **Issue** | Fascículo / entrega individual publicada dentro de un run. Registra las métricas directas de ventas y popularidad. |
| **Cover** | Portada de un fascículo; distingue la edición principal de las *variant covers*. |
| **RunAutor** | Resuelve la relación N:N entre runs y autores, con el rol narrativo y el periodo de participación. |
| **ParticipacionArtista** | Asignación de trabajo de los ilustradores dentro de un issue (lápiz, color, páginas a cargo). |

### Reglas de negocio y Triggers

- **Fecha de comienzo de creadores (`Persona.fechaComienzo`):** se inicializa en `NULL` al dar de alta una persona (`trg_set_fecha_comienzo_null`) y se actualiza automáticamente al cargar o modificar un cómic (`trg_actualizar_fecha_comienzo_autor`), validando que `Comic.fechaInicio > Persona.fechaNacimiento` y asignando `MIN(Comic.fechaInicio)`.
- **Métricas de popularidad y ventas (`Comic` y `Run`):** se inicializan en `0.0` y `0` mediante triggers `BEFORE INSERT` (`trg_inicializar_metricas_comic` y `trg_inicializar_metricas_run`), se recalculan automáticamente en cascada desde `Issue` hacia `Run` y `Comic` (`trg_actualizar_ventas_run` y `trg_actualizar_metricas_comic`), y están protegidas contra modificaciones manuales directas mediante excepción (`trg_proteger_metricas_run` y `trg_proteger_metricas_comic`).
- **Portada principal única (`Cover`):** cada issue admite múltiples *variant covers*, pero como máximo una portada principal (`trg_unica_portada_principal`).
- **Consistencia temporal en `RunAutor`:** la fecha de inicio de participación de un autor no puede ser previa al comienzo del run (`trg_validar_fecha_runautor`).
- **Validación de páginas en `ParticipacionArtista`:** las páginas asignadas deben ser estrictamente mayores a cero (`trg_validar_paginas`).

## Consultas del enunciado

| # | Descripción |
| --- | --- |
| A | Cómics con mayor cantidad de *variant covers* de un año en particular. |
| B | Runs de cómics de Marvel con puntuación mayor a 4, con sus datos y la cantidad de issues de cada run. |
| C | Cómics en los que participa un artista en particular, considerando solo *variant covers*. |
| D | Cambios de puntuación y de ejemplares vendidos en cómics y runs al insertar o borrar issues. |
| E | Los 10 artistas y autores cuyos cómics tienen la mayor puntuación posible (`fn_top10_creadores_popularidad`). |
| F | Artistas con más de 10 años desde su comienzo en el medio, excluyendo quienes hayan trabajado en *variant covers* en los últimos 6 meses (`fn_artistas_veteranos_sin_variants`). |

## Tecnologías

- **PostgreSQL** — motor principal de desarrollo (PL/pgSQL).

## Estructura del proyecto

```
Diagrama de clases BD.drawio.png
Diccionarios de Datos.html
Modelo Relacional.md
Normalizacion.md
Scripts/
  Script creación de bd.sql           -- DDL: dominios, tablas, PK, FK y constraints
  Script creación de triggers.sql     -- 11 triggers de inicialización, cascada, protección y validación
  Script carga de datos.sql           -- Carga inicial consistente de las 10 tablas
  Script creación de funciones.sql    -- Funciones analíticas (Consultas E y F)
  Script de vistas y consultas.sql    -- 5 vistas y resolución de Consultas A-F
  Script de creación de usuarios.sql  -- Roles (rol_admin, rol_carga, rol_consulta) y usuarios
  Script pruebas de triggers.sql      -- Casos de prueba de los 11 triggers
  Script pruebas de funciones.sql     -- Casos de prueba de funciones analíticas
```

## Puesta en marcha

```bash
createdb comics_archive
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script creación de bd.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script creación de triggers.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script carga de datos.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script creación de funciones.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script de vistas y consultas.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script de creación de usuarios.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script pruebas de triggers.sql"
psql -d comics_archive -v ON_ERROR_STOP=1 -f "Scripts/Script pruebas de funciones.sql"
```

## Estado

- [x] Definición del modelo lógico
- [x] Definición del modelo relacional y normalización (3FN)
- [x] Diccionario de datos
- [x] Triggers y funciones
- [x] Scripts de creación, carga y usuarios
- [x] Consultas A-F y vistas
- [x] Pruebas de triggers y funciones