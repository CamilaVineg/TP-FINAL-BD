-- ============================================================================
-- SCRIPT DE VISTAS Y CONSULTAS REQUERIDAS (PROPUESTA 6: COMICS ARCHIVE)
-- Proyecto: TP FINAL BD
-- Descripción: Creación de Vistas y resolución de las 6 Consultas requeridas.
-- ============================================================================

-- ============================================================================
-- SECCIÓN 1: CREACIÓN DE VISTAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Vista 1: Catálogo General de Cómics con Detalle de Editorial y Creador
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_catalogo_comics_detallado AS
SELECT 
    c.idComic,
    c.nombre AS comic_nombre,
    c.descripcion,
    c.fechaInicio,
    c.popularidad,
    c.ejemplaresVendidos,
    e.nombre AS editorial,
    p.nombre || ' ' || p.apellidos AS autor_creador,
    p.alias AS autor_alias
FROM Comic c
JOIN Empresa e ON c.idEmpresa = e.idEmpresa
JOIN Autor a ON c.idAutor = a.idAutor
JOIN Persona p ON a.idPersona = p.idPersona;

-- ----------------------------------------------------------------------------
-- Vista 2: Runs con Conteo de Issues y Datos del Cómic/Editorial
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_runs_con_conteo_issues AS
SELECT 
    r.idRun,
    c.idComic,
    c.nombre AS comic_nombre,
    e.nombre AS editorial,
    r.fechaComienzo,
    r.popularidad AS run_popularidad,
    r.ejemplaresVendidos AS run_ventas,
    COUNT(i.idIssue) AS cantidad_issues
FROM Run r
JOIN Comic c ON r.idComic = c.idComic
JOIN Empresa e ON c.idEmpresa = e.idEmpresa
LEFT JOIN Issue i ON r.idRun = i.idRun
GROUP BY r.idRun, c.idComic, c.nombre, e.nombre, r.fechaComienzo, r.popularidad, r.ejemplaresVendidos;

-- ----------------------------------------------------------------------------
-- Vista 3: Resumen de Variant Covers
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_resumen_variant_covers AS
SELECT 
    c.idComic,
    c.nombre AS comic_nombre,
    i.idIssue,
    i.numero AS numero_issue,
    cov.idCover,
    cov.nombre AS nombre_variante,
    cov.fechaCreacion,
    EXTRACT(YEAR FROM cov.fechaCreacion)::INTEGER AS anio_creacion,
    art.idArtista,
    p.nombre || ' ' || p.apellidos AS artista_nombre,
    p.alias AS artista_alias
FROM Cover cov
JOIN Issue i ON cov.idIssue = i.idIssue
JOIN Run r ON i.idRun = r.idRun
JOIN Comic c ON r.idComic = c.idComic
JOIN Artista art ON cov.idArtista = art.idArtista
JOIN Persona p ON art.idPersona = p.idPersona
WHERE cov.esPrincipal = FALSE;

-- ----------------------------------------------------------------------------
-- Vista 4: Participación de Artistas en Covers y Cómics
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_participacion_exclusiva_artistas AS
SELECT 
    art.idArtista,
    p.nombre || ' ' || p.apellidos AS artista_nombre,
    p.alias AS artista_alias,
    c.idComic,
    c.nombre AS comic_nombre,
    cov.esPrincipal AS es_portada_principal,
    cov.fechaCreacion AS fecha_portada
FROM Artista art
JOIN Persona p ON art.idPersona = p.idPersona
JOIN Cover cov ON art.idArtista = cov.idArtista
JOIN Issue i ON cov.idIssue = i.idIssue
JOIN Run r ON i.idRun = r.idRun
JOIN Comic c ON r.idComic = c.idComic;

-- ----------------------------------------------------------------------------
-- Vista 5: Trayectoria y Antigüedad de Artistas
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_trayectoria_artistas AS
SELECT 
    art.idArtista,
    p.nombre || ' ' || p.apellidos AS nombre_artista,
    p.alias,
    p.fechaComienzo,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.fechaComienzo))::INTEGER AS anios_trayectoria,
    MAX(CASE WHEN cov.esPrincipal = FALSE THEN cov.fechaCreacion END) AS ultima_variant_cover
FROM Artista art
JOIN Persona p ON art.idPersona = p.idPersona
LEFT JOIN Cover cov ON art.idArtista = cov.idArtista
GROUP BY art.idArtista, p.nombre, p.apellidos, p.alias, p.fechaComienzo;


-- ============================================================================
-- SECCIÓN 2: RESOLUCIÓN DE LAS 6 CONSULTAS REQUERIDAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Consulta A: Listar los cómics con mayor cantidad de variant covers de un año en particular.
-- (Ejemplo de prueba para el año 2023)
-- ----------------------------------------------------------------------------
SELECT 
    c.idComic,
    c.nombre AS comic_nombre,
    COUNT(cov.idCover) AS cantidad_variant_covers
FROM Comic c
JOIN Run r ON c.idComic = r.idComic
JOIN Issue i ON r.idRun = i.idRun
JOIN Cover cov ON i.idIssue = cov.idIssue
WHERE cov.esPrincipal = FALSE
  AND EXTRACT(YEAR FROM cov.fechaCreacion) = 2023
GROUP BY c.idComic, c.nombre
ORDER BY cantidad_variant_covers DESC, c.nombre ASC;


-- ----------------------------------------------------------------------------
-- Consulta B: Mostrar todas las runs de cómics de Marvel con una puntuación
-- mayor a 4, mostrando además de sus datos la cantidad de issues correspondientes a cada run.
-- ----------------------------------------------------------------------------
SELECT 
    r.idRun,
    c.nombre AS comic_nombre,
    e.nombre AS editorial,
    r.fechaComienzo,
    r.popularidad AS popularidad_run,
    r.ejemplaresVendidos AS ventas_run,
    COUNT(i.idIssue) AS cantidad_issues
FROM Run r
JOIN Comic c ON r.idComic = c.idComic
JOIN Empresa e ON c.idEmpresa = e.idEmpresa
LEFT JOIN Issue i ON r.idRun = i.idRun
WHERE LOWER(e.nombre) LIKE '%marvel%'
  AND r.popularidad > 4.0
GROUP BY r.idRun, c.idComic, c.nombre, e.nombre, r.fechaComienzo, r.popularidad, r.ejemplaresVendidos
ORDER BY r.popularidad DESC, r.idRun ASC;


-- ----------------------------------------------------------------------------
-- Consulta C: Mostrar todos los cómics en los que haya participado un artista
-- en particular, pero solamente haciendo variant covers.
-- (Ejemplo de prueba para idArtista = 4: Todd McFarlane, quien hizo variant covers
-- en The Amazing Spider-Man y Batman sin participar en sus portadas principales
-- ni páginas interiores, mientras que en Spawn sí hizo portada principal e interior).
-- ----------------------------------------------------------------------------
SELECT DISTINCT 
    c.idComic,
    c.nombre AS comic_nombre
FROM Cover cov
JOIN Issue i ON cov.idIssue = i.idIssue
JOIN Run r ON i.idRun = r.idRun
JOIN Comic c ON r.idComic = c.idComic
WHERE cov.idArtista = 4
  AND cov.esPrincipal = FALSE
  -- Excluir cómics donde el artista haya realizado alguna portada principal
  AND NOT EXISTS (
      SELECT 1
      FROM Run r2
      JOIN Issue i2 ON r2.idRun = i2.idRun
      JOIN Cover cov2 ON i2.idIssue = cov2.idIssue
      WHERE r2.idComic = c.idComic
        AND cov2.idArtista = cov.idArtista
        AND cov2.esPrincipal = TRUE
  )
  -- Excluir cómics donde el artista haya participado dibujando páginas internas
  AND NOT EXISTS (
      SELECT 1
      FROM Run r3
      JOIN Issue i3 ON r3.idRun = i3.idRun
      JOIN ParticipacionArtista pa ON i3.idIssue = pa.idIssue
      WHERE r3.idComic = c.idComic
        AND pa.idArtista = cov.idArtista
  )
ORDER BY c.idComic;


-- ----------------------------------------------------------------------------
-- Consulta D: Mostrar los cambios de puntuación y de ejemplares en los registros 
-- de cómics y runs insertando o borrando entradas de issues.
-- ----------------------------------------------------------------------------

-- Limpieza preventiva por si la consulta fue interrumpida previamente
DELETE FROM Issue WHERE idIssue = 1001;

-- Paso 1: Consultar valores iniciales de Run y Comic para idRun = 1
SELECT 
    '1. Estado Inicial' AS etapa,
    c.idComic,
    c.nombre AS comic_nombre,
    ROUND(c.popularidad::NUMERIC, 2) AS pop_comic,
    c.ejemplaresVendidos AS ventas_comic,
    r.idRun,
    r.fechaComienzo,
    ROUND(r.popularidad::NUMERIC, 2) AS pop_run,
    r.ejemplaresVendidos AS ventas_run
FROM Comic c
JOIN Run r ON c.idComic = r.idComic
WHERE r.idRun = 1;

-- Paso 2: Insertar un nuevo Issue en idRun = 1
-- (El trigger trg_actualizar_ventas_run actualiza Run.ejemplaresVendidos automáticamente,
-- y se recalculan las puntuaciones y el acumulado en Comic).
INSERT INTO Issue (idIssue, numero, popularidad, ejemplaresVendidos, idRun)
VALUES (1001, 99, 5.0, 25000, 1);

UPDATE Run r
SET popularidad = COALESCE((SELECT AVG(i.popularidad) FROM Issue i WHERE i.idRun = r.idRun), 0.0)
WHERE r.idRun = 1;

UPDATE Comic c
SET popularidad = COALESCE((SELECT AVG(r.popularidad) FROM Run r WHERE r.idComic = c.idComic), 0.0),
    ejemplaresVendidos = COALESCE((SELECT SUM(r.ejemplaresVendidos) FROM Run r WHERE r.idComic = c.idComic), 0)
WHERE c.idComic = 1;

-- Paso 3: Consultar valores actualizados tras la inserción del Issue
SELECT 
    '2. Tras INSERT Issue' AS etapa,
    c.idComic,
    c.nombre AS comic_nombre,
    ROUND(c.popularidad::NUMERIC, 2) AS pop_comic,
    c.ejemplaresVendidos AS ventas_comic,
    r.idRun,
    r.fechaComienzo,
    ROUND(r.popularidad::NUMERIC, 2) AS pop_run,
    r.ejemplaresVendidos AS ventas_run
FROM Comic c
JOIN Run r ON c.idComic = r.idComic
WHERE r.idRun = 1;

-- Paso 4: Eliminar el Issue insertado
DELETE FROM Issue WHERE idIssue = 1001;

UPDATE Run r
SET popularidad = COALESCE((SELECT AVG(i.popularidad) FROM Issue i WHERE i.idRun = r.idRun), 0.0)
WHERE r.idRun = 1;

UPDATE Comic c
SET popularidad = COALESCE((SELECT AVG(r.popularidad) FROM Run r WHERE r.idComic = c.idComic), 0.0),
    ejemplaresVendidos = COALESCE((SELECT SUM(r.ejemplaresVendidos) FROM Run r WHERE r.idComic = c.idComic), 0)
WHERE c.idComic = 1;

-- Paso 5: Verificar restitución de los valores originales
SELECT 
    '3. Tras DELETE Issue' AS etapa,
    c.idComic,
    c.nombre AS comic_nombre,
    ROUND(c.popularidad::NUMERIC, 2) AS pop_comic,
    c.ejemplaresVendidos AS ventas_comic,
    r.idRun,
    r.fechaComienzo,
    ROUND(r.popularidad::NUMERIC, 2) AS pop_run,
    r.ejemplaresVendidos AS ventas_run
FROM Comic c
JOIN Run r ON c.idComic = r.idComic
WHERE r.idRun = 1;


-- ----------------------------------------------------------------------------
-- Consulta E: Mostrar los 10 artistas y escritores cuyos cómics tengan
-- la mayor puntuación posible.
-- ----------------------------------------------------------------------------
WITH ObrasPorCreador AS (
    -- Cómics creados directamente por un Autor
    SELECT p.idPersona, p.nombre || ' ' || p.apellidos AS nombre_completo, p.alias,
           'Escritor/Autor' AS rol, c.popularidad
    FROM Persona p
    JOIN Autor a ON p.idPersona = a.idPersona
    JOIN Comic c ON a.idAutor = c.idAutor

    UNION ALL

    -- Cómics en cuyos Runs participó un Autor (RunAutor)
    SELECT p.idPersona, p.nombre || ' ' || p.apellidos AS nombre_completo, p.alias,
           'Escritor/Autor' AS rol, c.popularidad
    FROM Persona p
    JOIN Autor a ON p.idPersona = a.idPersona
    JOIN RunAutor ra ON a.idAutor = ra.idAutor
    JOIN Run r ON ra.idRun = r.idRun
    JOIN Comic c ON r.idComic = c.idComic

    UNION ALL

    -- Cómics en cuyos Covers participó un Artista
    SELECT p.idPersona, p.nombre || ' ' || p.apellidos AS nombre_completo, p.alias,
           'Artista' AS rol, c.popularidad
    FROM Persona p
    JOIN Artista art ON p.idPersona = art.idPersona
    JOIN Cover cov ON art.idArtista = cov.idArtista
    JOIN Issue i ON cov.idIssue = i.idIssue
    JOIN Run r ON i.idRun = r.idRun
    JOIN Comic c ON r.idComic = c.idComic

    UNION ALL

    -- Cómics en cuyas páginas interiores participó un Artista (ParticipacionArtista)
    SELECT p.idPersona, p.nombre || ' ' || p.apellidos AS nombre_completo, p.alias,
           'Artista' AS rol, c.popularidad
    FROM Persona p
    JOIN Artista art ON p.idPersona = art.idPersona
    JOIN ParticipacionArtista pa ON art.idArtista = pa.idArtista
    JOIN Issue i ON pa.idIssue = i.idIssue
    JOIN Run r ON i.idRun = r.idRun
    JOIN Comic c ON r.idComic = c.idComic
)
SELECT 
    idPersona,
    nombre_completo,
    alias,
    STRING_AGG(DISTINCT rol, ' / ' ORDER BY rol) AS roles_en_comics,
    MAX(popularidad) AS mayor_puntuacion_comic
FROM ObrasPorCreador
GROUP BY idPersona, nombre_completo, alias
ORDER BY mayor_puntuacion_comic DESC, nombre_completo ASC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- Consulta F: Mostrar los artistas con más de 10 años desde su comienzo
-- en el medio a la fecha actual de consulta, pero solamente si no han trabajado
-- en variant covers en los últimos 6 meses.
-- (Nota: Chip Zdarsky, idArtista = 7, queda excluido por tener una variant cover
-- creada hace 2 meses).
-- ----------------------------------------------------------------------------
SELECT 
    art.idArtista,
    p.nombre || ' ' || p.apellidos AS nombre_artista,
    p.alias,
    p.fechaComienzo,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.fechaComienzo))::INTEGER AS anios_en_el_medio
FROM Artista art
JOIN Persona p ON art.idPersona = p.idPersona
WHERE 
    p.fechaComienzo <= CURRENT_DATE - INTERVAL '10 years'
    AND NOT EXISTS (
        SELECT 1
        FROM Cover cov
        WHERE cov.idArtista = art.idArtista
          AND cov.esPrincipal = FALSE
          AND cov.fechaCreacion >= CURRENT_DATE - INTERVAL '6 months'
    )
ORDER BY anios_en_el_medio DESC;
