-- ============================================================================
-- SCRIPT DE CREACIÓN DE FUNCIONES (PROPUESTA 6: COMICS ARCHIVE)
-- Descripción: Definición de Funciones Almacenadas para resolver requerimientos
-- analíticos de negocio: ranking de creadores y trayectoria de artistas.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FUNCIÓN: fn_top10_creadores_popularidad()
-- Requerimiento (Consulta E): Mostrar los 10 artistas y escritores cuyos cómics
-- tengan la mayor puntuación de popularidad. Si un creador participó como
-- escritor y como dibujante en obras con diferente puntuación, debe figurar
-- únicamente con la puntuación más alta por rol.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_top10_creadores_popularidad()
RETURNS TABLE (
    tipo_creador        TEXT,
    id_persona          INTEGER,
    nombre_completo     TEXT,
    popularidad_maxima  FLOAT
)
LANGUAGE sql
STABLE
AS $$
    WITH relaciones AS (
        -- Artistas participantes en la ilustración de páginas interiores
        SELECT ar.idPersona, 'ARTISTA'::TEXT AS tipo, c.popularidad
        FROM ParticipacionArtista pa
        JOIN Artista ar ON ar.idArtista = pa.idArtista
        JOIN Issue i    ON i.idIssue    = pa.idIssue
        JOIN Run r      ON r.idRun      = i.idRun
        JOIN Comic c    ON c.idComic    = r.idComic

        UNION ALL

        -- Ilustradores a cargo de portadas
        SELECT ar.idPersona, 'ARTISTA', c.popularidad
        FROM Cover cv
        JOIN Artista ar ON ar.idArtista = cv.idArtista
        JOIN Issue i    ON i.idIssue    = cv.idIssue
        JOIN Run r      ON r.idRun      = i.idRun
        JOIN Comic c    ON c.idComic    = r.idComic

        UNION ALL

        -- Escritores creadores asignados al cómic global
        SELECT au.idPersona, 'AUTOR', c.popularidad
        FROM Comic c
        JOIN Autor au ON au.idAutor = c.idAutor

        UNION ALL

        -- Guionistas participantes dentro de arcos específicos (Runs)
        SELECT au.idPersona, 'AUTOR', c.popularidad
        FROM RunAutor ra
        JOIN Autor au ON au.idAutor = ra.idAutor
        JOIN Run r    ON r.idRun    = ra.idRun
        JOIN Comic c  ON c.idComic  = r.idComic
    )
    SELECT rel.tipo,
           p.idPersona,
           p.nombre || ' ' || p.apellidos,
           MAX(rel.popularidad)
    FROM relaciones rel
    JOIN Persona p ON p.idPersona = rel.idPersona
    GROUP BY rel.tipo, p.idPersona, p.nombre, p.apellidos
    ORDER BY MAX(rel.popularidad) DESC, p.apellidos, p.nombre
    LIMIT 10;
$$;


-- ----------------------------------------------------------------------------
-- 2. FUNCIÓN: fn_artistas_veteranos_sin_variants(DATE)
-- Requerimiento (Consulta F): Mostrar los artistas con más de 10 años desde su
-- comienzo en el medio a la fecha de consulta, pero solamente si no han trabajado
-- en variant covers en los últimos 6 meses (esPrincipal = FALSE).
-- Por defecto toma CURRENT_DATE como fecha base de evaluación.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_artistas_veteranos_sin_variants(
    p_fecha_consulta DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    artista_id      INTEGER,
    nombre_artista  TEXT,
    alias_artista   TEXT,
    fecha_comienzo  DATE,
    anios_en_medio  INTEGER
)
LANGUAGE sql
STABLE
AS $$
    SELECT ar.idArtista,
           p.nombre || ' ' || p.apellidos,
           p.alias,
           p.fechaComienzo,
           DATE_PART('year', AGE(p_fecha_consulta, p.fechaComienzo))::INTEGER
    FROM Artista ar
    JOIN Persona p ON p.idPersona = ar.idPersona
    WHERE p.fechaComienzo IS NOT NULL
      AND p.fechaComienzo < (p_fecha_consulta - INTERVAL '10 years')
      AND NOT EXISTS (
            SELECT 1
            FROM Cover cv
            WHERE cv.idArtista = ar.idArtista
              AND cv.esPrincipal = FALSE
              AND cv.fechaCreacion >  (p_fecha_consulta - INTERVAL '6 months')
              AND cv.fechaCreacion <= p_fecha_consulta
      )
    ORDER BY p.fechaComienzo, p.apellidos, p.nombre;
$$;
