-- ============================================================================
-- SCRIPT DE CARGA DE DATOS (PROPUESTA 6: COMICS ARCHIVE)
-- Descripción: Carga inicial de datos consistente con las reglas de negocio.
-- - Todas las tuplas de Persona se cargan con fechaComienzo en NULL y se
--   actualizan automáticamente al insertar sus Cómics (trg_actualizar_fecha_comienzo_autor).
-- - Comic y Run se inicializan en 0.0 y 0 mediante triggers BEFORE INSERT y se
--   actualizan automáticamente en cascada al insertar los Issues.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Tabla: Persona (10 tuplas)
-- Nota: fechaComienzo se carga en NULL (además forzado por trg_set_fecha_comienzo_null)
-- y se calcula automáticamente a partir del primer cómic registrado de cada autor.
-- ----------------------------------------------------------------------------
INSERT INTO Persona (idPersona, nombre, apellidos, alias, fechaNacimiento, fechaComienzo) VALUES
(1, 'Stan', 'Lee', 'The Man', '1922-12-28', NULL),
(2, 'Jack', 'Kirby', 'The King', '1917-08-28', NULL),
(3, 'Steve', 'Ditko', NULL, '1927-11-02', NULL),
(4, 'Frank', 'Miller', NULL, '1957-01-27', NULL),
(5, 'Alan', 'Moore', 'Original Writer', '1953-11-18', NULL),
(6, 'Todd', 'McFarlane', NULL, '1961-03-16', NULL),
(7, 'Jim', 'Lee', NULL, '1964-08-11', NULL),
(8, 'Brian Michael', 'Bendis', NULL, '1967-08-18', NULL),
(9, 'Fiona', 'Staples', NULL, '1984-09-08', NULL),
(10, 'Chip', 'Zdarsky', 'Steve Murray', '1975-12-21', NULL);

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
-- 5. Tabla: Comic (13 tuplas)
-- Nota: popularidad y ejemplaresVendidos se inicializan en 0.0 y 0 mediante
-- trg_inicializar_metricas_comic, y cada inserción actualiza automáticamente
-- Persona.fechaComienzo mediante trg_actualizar_fecha_comienzo_autor.
-- ----------------------------------------------------------------------------
INSERT INTO Comic (idComic, nombre, descripcion, fechaInicio, popularidad, ejemplaresVendidos, idEmpresa, idAutor) VALUES
(1, 'The Amazing Spider-Man', 'Las aventuras del héroe arácnido Peter Parker', '1963-03-01', 0.0, 0, 1, 1),
(2, 'Batman: Year One', 'El origen definitivo del Caballero de la Noche en Gotham', '1986-02-01', 0.0, 0, 2, 2),
(3, 'Watchmen', 'Deconstrucción del mito del superhéroe', '1986-09-01', 0.0, 0, 2, 3),
(4, 'Spawn', 'Al Simmons regresa del infierno como engendro', '1992-05-01', 0.0, 0, 3, 8),
(5, 'Saga', 'Una épica de ópera espacial y fantasía', '2012-03-14', 0.0, 0, 3, 10),
(6, 'Daredevil', 'El hombre sin miedo combate el crimen en Hells Kitchen', '1964-04-01', 0.0, 0, 1, 1),
(7, 'X-Men', 'Los mutantes luchan por un mundo que los teme', '1963-09-01', 0.0, 0, 1, 1),
(8, 'Hellboy', 'Un demonio investiga lo paranormal para el BPRD', '1993-08-01', 0.0, 0, 4, 2),
(9, 'Powers', 'Detectives de homicidios investigan crímenes de superhéroes', '2000-04-01', 0.0, 0, 3, 4),
(10, 'Howard the Duck', 'Las cómicas aventuras de un pato detective en la Tierra', '2015-03-11', 0.0, 0, 1, 5),
(11, 'Captain America Comics', 'El supersoldado patriótico lucha por la libertad', '1941-03-01', 0.0, 0, 1, 6),
(12, 'Doctor Strange', 'El Hechicero Supremo defiende la Tierra de amenazas místicas', '1963-07-01', 0.0, 0, 1, 7),
(13, 'WildC.A.T.s', 'Equipo encubierto de héroes alienígenas en Image Comics', '1992-08-01', 0.0, 0, 3, 9);

-- ----------------------------------------------------------------------------
-- 6. Tabla: Run (10 tuplas)
-- Nota: popularidad y ejemplaresVendidos se inicializan en 0.0 y 0 mediante
-- trg_inicializar_metricas_run y se recalculan al cargarse los Issues.
-- ----------------------------------------------------------------------------
INSERT INTO Run (idRun, fechaComienzo, popularidad, ejemplaresVendidos, idComic) VALUES
(1, '1963-03-01', 0.0, 0, 1),
(2, '1986-02-01', 0.0, 0, 2),
(3, '1986-09-01', 0.0, 0, 3),
(4, '1992-05-01', 0.0, 0, 4),
(5, '2012-03-14', 0.0, 0, 5),
(6, '1979-05-01', 0.0, 0, 6),
(7, '1991-10-01', 0.0, 0, 7),
(8, '2000-02-01', 0.0, 0, 1),
(9, '2019-02-01', 0.0, 0, 6),
(10, '1994-03-01', 0.0, 0, 8);

-- ----------------------------------------------------------------------------
-- 7. Tabla: Issue (10 tuplas)
-- Nota: Al insertar cada Issue, trg_actualizar_ventas_run recalcula su Run y
-- trg_actualizar_metricas_comic propaga en cascada los totales a Comic.
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
-- 8. Tabla: Cover (15 tuplas: 10 principales + 5 variant covers)
-- ----------------------------------------------------------------------------
INSERT INTO Cover (idCover, nombre, fechaCreacion, esPrincipal, idIssue, idArtista) VALUES
-- Portadas principales
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
-- ----------------------------------------------------------------------------
INSERT INTO RunAutor (idRunAutor, rol, fechaInicio, idRun, idAutor) VALUES
(1, 'Escritor Principal', '1963-03-01', 1, 1),
(2, 'Guionista', '1986-02-01', 2, 2),
(3, 'Escritor', '1986-09-01', 3, 3),
(4, 'Guionista y Co-creador', '1992-05-01', 4, 8),
(5, 'Guionista', '2012-03-14', 5, 10),
(6, 'Escritor Principal', '1979-05-01', 6, 2),
(7, 'Co-guionista', '1991-10-01', 7, 9),
(8, 'Guionista', '2000-02-01', 8, 4),
(9, 'Escritor', '2019-02-01', 9, 5),
(10, 'Guionista', '1994-03-01', 10, 2);
