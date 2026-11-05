-- ============================================================================
-- SCRIPT DE CARGA DE DATOS INICIALES
-- Proyecto: TP FINAL BD - Propuesta 6 (Comics Archive)
-- Tablas: Persona, Artista, Autor, Empresa, Comic, Run, Issue, Cover,
--         ParticipacionArtista, RunAutor
-- Mínimo de tuplas por tabla: 10
-- ============================================================================

-- Limpieza previa para permitir re-ejecutar el script sin errores de claves duplicadas
TRUNCATE TABLE
    Cover,
    ParticipacionArtista,
    RunAutor,
    Issue,
    Run,
    Comic,
    Empresa,
    Autor,
    Artista,
    Persona
CASCADE;

-- ----------------------------------------------------------------------------
-- 1. Tabla: Persona (10 tuplas)
-- ----------------------------------------------------------------------------
INSERT INTO Persona (idPersona, nombre, apellidos, alias, fechaNacimiento, fechaComienzo) VALUES
(1, 'Stan', 'Lee', 'The Man', '1922-12-28', '1939-11-01'),
(2, 'Jack', 'Kirby', 'The King', '1917-08-28', '1936-01-15'),
(3, 'Steve', 'Ditko', NULL, '1927-11-02', '1953-03-01'),
(4, 'Frank', 'Miller', NULL, '1957-01-27', '1977-04-10'),
(5, 'Alan', 'Moore', 'Original Writer', '1953-11-18', '1974-02-01'),
(6, 'Todd', 'McFarlane', NULL, '1961-03-16', '1980-05-12'),
(7, 'Jim', 'Lee', NULL, '1964-08-11', '1986-09-01'),
(8, 'Brian Michael', 'Bendis', NULL, '1967-08-18', '1991-06-01'),
(9, 'Fiona', 'Staples', NULL, '1984-09-08', '2006-10-15'),
(10, 'Chip', 'Zdarsky', 'Steve Murray', '1975-12-21', '2000-01-10');

-- ----------------------------------------------------------------------------
-- 2. Tabla: Artista (10 tuplas)
-- ----------------------------------------------------------------------------
INSERT INTO Artista (idArtista, idPersona) VALUES
(1, 2),  -- Jack Kirby
(2, 3),  -- Steve Ditko
(3, 4),  -- Frank Miller
(4, 6),  -- Todd McFarlane
(5, 7),  -- Jim Lee
(6, 9),  -- Fiona Staples
(7, 10), -- Chip Zdarsky
(8, 1),  -- Stan Lee
(9, 5),  -- Alan Moore
(10, 8); -- Brian Michael Bendis

-- ----------------------------------------------------------------------------
-- 3. Tabla: Autor (10 tuplas)
-- ----------------------------------------------------------------------------
INSERT INTO Autor (idAutor, idPersona) VALUES
(1, 1),  -- Stan Lee
(2, 4),  -- Frank Miller
(3, 5),  -- Alan Moore
(4, 8),  -- Brian Michael Bendis
(5, 10), -- Chip Zdarsky
(6, 2),  -- Jack Kirby
(7, 3),  -- Steve Ditko
(8, 6),  -- Todd McFarlane
(9, 7),  -- Jim Lee
(10, 9); -- Fiona Staples

-- ----------------------------------------------------------------------------
-- 4. Tabla: Empresa (10 tuplas)
-- ----------------------------------------------------------------------------
INSERT INTO Empresa (idEmpresa, nombre) VALUES
(1, 'Marvel Comics'),
(2, 'DC Comics'),
(3, 'Image Comics'),
(4, 'Dark Horse Comics'),
(5, 'IDW Publishing'),
(6, 'Boom! Studios'),
(7, 'Dynamite Entertainment'),
(8, 'Valiant Comics'),
(9, 'Vertigo'),
(10, 'AfterShock Comics');

-- ----------------------------------------------------------------------------
-- 5. Tabla: Comic (10 tuplas)
-- Nota: ejemplaresVendidos y popularidad consolidan los valores de sus Runs.
-- ----------------------------------------------------------------------------
INSERT INTO Comic (idComic, nombre, descripcion, fechaInicio, popularidad, ejemplaresVendidos, idEmpresa, idAutor) VALUES
(1, 'The Amazing Spider-Man', 'Las aventuras del héroe arácnido Peter Parker', '1963-03-01', 4.8, 410000, 1, 1),
(2, 'Batman', 'El Caballero de la Noche protege Gotham City', '1940-04-25', 5.0, 200000, 2, 2),
(3, 'Watchmen', 'Deconstrucción del mito del superhéroe', '1986-09-01', 5.0, 180000, 2, 3),
(4, 'Spawn', 'Al Simmons regresa del infierno como engendro', '1992-05-01', 4.3, 160000, 3, 8),
(5, 'Saga', 'Una épica de ópera espacial y fantasía', '2012-03-14', 4.8, 95000, 3, 4),
(6, 'Daredevil', 'El hombre sin miedo combate el crimen en Hells Kitchen', '1964-04-01', 4.75, 215000, 1, 2),
(7, 'X-Men', 'Los mutantes luchan por un mundo que los teme', '1963-09-01', 5.0, 800000, 1, 1),
(8, 'Hellboy', 'Un demonio investiga lo paranormal para el BPRD', '1993-08-01', 4.5, 0, 4, 2),
(9, 'Teenage Mutant Ninja Turtles', 'Cuatro tortugas mutantes ninja entrenadas por Splinter', '1984-05-05', 4.4, 0, 5, 4),
(10, 'Howard the Duck', 'Las cómicas aventuras de un pato detective en la Tierra', '2015-03-11', 4.1, 0, 1, 5);

-- ----------------------------------------------------------------------------
-- 6. Tabla: Run (10 tuplas)
-- Nota: Si el trigger trg_actualizar_ventas_run ya está activo, recalculará
-- automáticamente ejemplaresVendidos al insertar los Issues; también se
-- especifican los totales iniciales para que quede consistente en cualquier orden.
-- ----------------------------------------------------------------------------
INSERT INTO Run (idRun, fechaComienzo, popularidad, ejemplaresVendidos, idComic) VALUES
(1, '1963-03-01', 4.8, 270000, 1),
(2, '1986-02-01', 5.0, 200000, 2),
(3, '1986-09-01', 5.0, 180000, 3),
(4, '1992-05-01', 4.3, 160000, 4),
(5, '2012-03-14', 4.8, 95000, 5),
(6, '1979-05-01', 4.9, 110000, 6),
(7, '1991-10-01', 5.0, 800000, 7),
(8, '2000-02-01', 4.8, 140000, 1),
(9, '2019-02-01', 4.6, 105000, 6),
(10, '1994-03-01', 4.5, 0, 8);

-- ----------------------------------------------------------------------------
-- 7. Tabla: Issue (10 tuplas)
-- Nota: Al insertar en Issue se ejecuta el trigger trg_actualizar_ventas_run
-- que recalcula automáticamente ejemplaresVendidos en la tabla Run.
-- ----------------------------------------------------------------------------
INSERT INTO Issue (idIssue, numero, popularidad, ejemplaresVendidos, idRun) VALUES
(1, 1, 4.9, 150000, 1),
(2, 2, 4.7, 120000, 1),
(3, 404, 5.0, 200000, 2),
(4, 1, 5.0, 180000, 3),
(5, 1, 4.3, 160000, 4),
(6, 1, 4.8, 95000, 5),
(7, 168, 4.9, 110000, 6),
(8, 1, 5.0, 800000, 7),
(9, 1, 4.8, 140000, 8),
(10, 1, 4.6, 105000, 9);

-- ----------------------------------------------------------------------------
-- 8. Tabla: Cover (15 tuplas: 10 portadas principales + 5 variant covers)
-- Nota:
-- - Cada Issue (1 al 10) tiene exactamente 1 portada principal (esPrincipal = TRUE).
-- - Se incluyen variant covers (esPrincipal = FALSE) en 2023 para la Consulta A,
--   variant covers exclusivas de idArtista = 4 (en cómics donde no hizo portada
--   principal ni interiores) para la Consulta C, y una variant cover reciente
--   (últimos 6 meses) de idArtista = 7 para verificar la exclusión en Consulta F.
-- ----------------------------------------------------------------------------
INSERT INTO Cover (idCover, nombre, fechaCreacion, esPrincipal, idIssue, idArtista) VALUES
-- Portadas principales (1 por cada Issue)
(1, 'Spider-Man #1 Regular Cover', '1963-01-15', TRUE, 1, 2),
(2, 'Spider-Man #2 Regular Cover', '1963-02-15', TRUE, 2, 2),
(3, 'Batman Year One Cover A', '1985-12-10', TRUE, 3, 3),
(4, 'Watchmen #1 Clock Cover', '1986-06-01', TRUE, 4, 3),
(5, 'Spawn #1 Classic Cover', '1992-03-15', TRUE, 5, 4),
(6, 'Saga #1 First Edition', '2012-01-10', TRUE, 6, 6),
(7, 'Daredevil #168 Elektra Cover', '1979-03-01', TRUE, 7, 3),
(8, 'X-Men #1 Gatefold Cover A', '1991-08-01', TRUE, 8, 5),
(9, 'Ultimate Spider-Man #1 Regular', '2000-01-05', TRUE, 9, 5),
(10, 'Daredevil #1 Regular Cover', '2019-01-02', TRUE, 10, 7),
-- Variant Covers (esPrincipal = FALSE)
(11, 'Spider-Man #1 McFarlane 2023 Variant', '2023-05-10', FALSE, 1, 4),
(12, 'Ultimate Spider-Man #1 McFarlane 2023 Variant', '2023-08-15', FALSE, 9, 4),
(13, 'Batman #404 McFarlane Anniversary Variant', '2023-10-01', FALSE, 3, 4),
(14, 'X-Men #1 Kirby Tribute 2023 Variant', '2023-11-20', FALSE, 8, 1),
(15, 'Saga #1 Zdarsky Recent Variant', CURRENT_DATE - INTERVAL '2 months', FALSE, 6, 7);

-- ----------------------------------------------------------------------------
-- 9. Tabla: ParticipacionArtista (10 tuplas)
-- Nota: Todas las participaciones tienen paginasAsignadas > 0 (cumple trg_validar_paginas).
-- El Issue 2 queda libre de participaciones iniciales para probar trg_validar_paginas.
-- ----------------------------------------------------------------------------
INSERT INTO ParticipacionArtista (idParticipacionArtista, rol, paginasAsignadas, idIssue, idArtista) VALUES
(1, 'Dibujante de interiores', 22, 1, 2),
(2, 'Entintador', 22, 1, 1),
(3, 'Dibujante y Entintador', 24, 3, 3),
(4, 'Dibujante', 28, 4, 3),
(5, 'Lápices y Tintas', 22, 5, 4),
(6, 'Arte Interior Completo', 32, 6, 6),
(7, 'Dibujante', 22, 7, 3),
(8, 'Dibujante Principal', 24, 8, 5),
(9, 'Dibujante de Interiores', 22, 9, 5),
(10, 'Dibujante y Colorista', 22, 10, 7);

-- ----------------------------------------------------------------------------
-- 10. Tabla: RunAutor (10 tuplas)
-- Nota: Todas las fechaInicio son >= fechaComienzo del Run (cumple trg_validar_fecha_runautor).
-- ----------------------------------------------------------------------------
INSERT INTO RunAutor (idRunAutor, rol, fechaInicio, idRun, idAutor) VALUES
(1, 'Escritor Principal', '1963-03-01', 1, 1),
(2, 'Guionista', '1986-02-01', 2, 2),
(3, 'Escritor', '1986-09-01', 3, 3),
(4, 'Guionista y Co-creador', '1992-05-01', 4, 8),
(5, 'Guionista', '2012-03-14', 5, 4),
(6, 'Escritor Principal', '1979-05-01', 6, 2),
(7, 'Co-guionista', '1991-10-01', 7, 9),
(8, 'Guionista', '2000-02-01', 8, 4),
(9, 'Escritor', '2019-02-01', 9, 5),
(10, 'Guionista', '1994-03-01', 10, 2);
