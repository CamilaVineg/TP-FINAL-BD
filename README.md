# Comics Archive — TP Integrador Final de Base de Datos

Trabajo Integrador Final de la asignatura **Base de Datos** (Lic. en Sistemas de Información).

**Comics Archive** es el sistema de gestión para una empresa de archivado de cómics. Permite
administrar el catálogo completo de cómics, organizarlos de forma ordenada y registrar todas las
versiones (issues, runs y portadas) disponibles, junto con métricas de popularidad y ventas.

## Integrantes

- Rochás Tadeo
- Pérez Sofia
- Poggio Abril
- Viñeg Camila

## Objetivos del trabajo

1. Definir el **modelo lógico** y el **modelo relacional** de la base de datos.
2. Elaborar el **diccionario de datos** y los **triggers** correspondientes.
3. Generar los scripts de creación, carga, consulta y verificación de la base:
   - Script de la base de datos (DDL).
   - Script de los triggers.
   - Script de carga de datos.
   - Script de las vistas.
   - Script de las funciones.
   - Script de los usuarios.
   - Script de pruebas de triggers y funciones.

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

### Reglas de negocio

- Cada cómic cuenta con un autor, un nombre, una descripción breve, la empresa a la que pertenece y
  una fecha de inicio de serialización.
- Cada run tiene fecha de comienzo, sus escritores y sus issues asociados.
- Cada issue tiene una portada principal y, opcionalmente, una o varias *variant covers* con su
  artista, fecha de creación y nombre de variante.
- La popularidad se puntúa de **0 a 5**. Issues y runs también acumuran ejemplares vendidos.
- Los totales de **runs** se calculan a partir de los issues, y los de **cómics** a partir de los
  runs; se mantienen actualizados ante altas, bajas y modificaciones de issues.
- Cada autor y cada artista tienen nombre y apellidos, alias opcional, fecha de nacimiento y fecha
  de comienzo en el medio (primer cómic registrado del autor).

## Consultas del enunciado

| # | Descripción |
| --- | --- |
| A | Cómics con mayor cantidad de *variant covers* de un año en particular. |
| B | Runs de cómics de Marvel con puntuación mayor a 4, con sus datos y la cantidad de issues de cada run. |
| C | Cómics en los que participa un artista en particular, considerando solo *variant covers*. |
| D | Cambios de puntuación y de ejemplares vendidos en cómics y runs al insertar o borrar issues. |
| E | Los 10 artistas y autores cuyos cómics tienen la mayor puntuación posible. |
| F | Artistas con más de 10 años desde su comienzo en el medio, excluyendo quienes hayan trabajado en *variant covers* en los últimos 6 meses. |

## Tecnologías

- **PostgreSQL** — motor principal de desarrollo.
- **MySQL / MariaDB** — compatibilidad alternativa de los scripts.

## Estructura del proyecto

```
db/
  01_esquema.sql          -- DDL: tablas, PK, FK y constraints
  02_triggers.sql         -- triggers de calculo de popularidad y ventas
  03_datos_carga.sql      -- datos de prueba
  04_vistas.sql           -- vistas para las consultas A-F
  05_funciones.sql        -- funciones de calculo
  06_usuarios.sql         -- usuarios y permisos
  07_pruebas.sql          -- pruebas de triggers y funciones
docs/
  modelo_logico.md        -- modelo logico (entidades, atributos, relaciones)
  modelo_relacional.md    -- modelo relacional
  diccionario_datos.md    -- diccionario de datos
```

## Puesta en marcha

```bash
# Crear la base y cargar los scripts en orden
createdb comics_archive
psql -d comics_archive -f db/01_esquema.sql
psql -d comics_archive -f db/02_triggers.sql
psql -d comics_archive -f db/03_datos_carga.sql
psql -d comics_archive -f db/04_vistas.sql
psql -d comics_archive -f db/05_funciones.sql
psql -d comics_archive -f db/06_usuarios.sql
psql -d comics_archive -f db/07_pruebas.sql
```

## Estado

- [x] Definicion del modelo logico
- [ ] Definicion del modelo relacional
- [ ] Diccionario de datos
- [ ] Triggers
- [ ] Scripts de creacion y carga
- [ ] Consultas A-F
- [ ] Pruebas