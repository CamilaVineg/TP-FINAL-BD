-- ============================================================================
-- SCRIPT DE PRUEBAS DE TRIGGERS (PROPUESTA 6: COMICS ARCHIVE)
-- Descripción: Casos de prueba exhaustivos para demostrar el correcto
-- funcionamiento de los 11 triggers en operaciones de INSERT, UPDATE y DELETE,
-- validando tanto casos exitosos como captura controlada de excepciones.
-- ============================================================================

-- ============================================================================
-- PRUEBA 1: Triggers trg_set_fecha_comienzo_null y trg_actualizar_fecha_comienzo_autor
-- Reglas:
--   - Al insertar una Persona, fechaComienzo se fuerza en NULL.
--   - Al insertar/actualizar un Comic, se valida Comic.fechaInicio > Persona.fechaNacimiento
--     y se actualiza Persona.fechaComienzo = MIN(Comic.fechaInicio).
-- ============================================================================

-- 1.A [Inicialización en NULL al crear Persona aunque se envíe fecha manual]
INSERT INTO Persona (idPersona, nombre, apellidos, alias, fechaNacimiento, fechaComienzo)
VALUES (99, 'Grant', 'Morrison', NULL, '1960-01-31', '2005-01-01');

INSERT INTO Autor (idAutor, idPersona) VALUES (99, 99);

DO $$
DECLARE
    v_fecha DATE;
BEGIN
    SELECT fechaComienzo INTO v_fecha FROM Persona WHERE idPersona = 99;
    IF v_fecha IS NOT NULL THEN
        RAISE EXCEPTION 'FALLO 1.A: fechaComienzo debía ser NULL y fue %', v_fecha;
    END IF;
    RAISE NOTICE 'ÉXITO 1.A: trg_set_fecha_comienzo_null inicializó Persona.fechaComienzo en NULL.';
END $$;

-- 1.B [Caso de Error Esperado: Comic.fechaInicio <= Persona.fechaNacimiento]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO Comic (idComic, nombre, descripcion, fechaInicio, popularidad, ejemplaresVendidos, idEmpresa, idAutor)
        VALUES (98, 'Cómic Inválido', 'Fecha previa al nacimiento del autor', '1955-05-01', 0.0, 0, 2, 99);
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 1.B (Excepción capturada correctamente): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 1.B: El trigger no rechazó un cómic con fechaInicio anterior al nacimiento del autor.';
    END IF;
END $$;

-- 1.C [Caso Exitoso: Primer cómic actualiza Persona.fechaComienzo]
INSERT INTO Comic (idComic, nombre, descripcion, fechaInicio, popularidad, ejemplaresVendidos, idEmpresa, idAutor)
VALUES (98, 'All-Star Superman', 'Serie limitada del Hombre de Acero', '2005-11-01', 0.0, 0, 2, 99);

-- 1.D [Caso Exitoso: Segundo cómic más antiguo actualiza Persona.fechaComienzo a MIN(fechaInicio)]
INSERT INTO Comic (idComic, nombre, descripcion, fechaInicio, popularidad, ejemplaresVendidos, idEmpresa, idAutor)
VALUES (99, 'Animal Man', 'Etapa metaficcional de Buddy Baker', '1988-09-01', 0.0, 0, 2, 99);

DO $$
DECLARE
    v_fecha DATE;
BEGIN
    SELECT fechaComienzo INTO v_fecha FROM Persona WHERE idPersona = 99;
    IF v_fecha <> DATE '1988-09-01' THEN
        RAISE EXCEPTION 'FALLO 1.D: Se esperaba fechaComienzo = 1988-09-01 y se obtuvo %', v_fecha;
    END IF;
    RAISE NOTICE 'ÉXITO 1.C y 1.D: trg_actualizar_fecha_comienzo_autor actualizó MIN(fechaInicio) = %', v_fecha;
END $$;

-- 1.E [Caso de Error Esperado en UPDATE de fechaInicio del Comic]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE Comic SET fechaInicio = '1950-01-01' WHERE idComic = 99;
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 1.E (Excepción capturada en UPDATE): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 1.E: El trigger no rechazó UPDATE con fechaInicio inválida.';
    END IF;
END $$;

-- Limpieza Prueba 1:
DELETE FROM Comic WHERE idComic IN (98, 99);
DELETE FROM Autor WHERE idAutor = 99;
DELETE FROM Persona WHERE idPersona = 99;


-- ============================================================================
-- PRUEBA 2: Triggers trg_inicializar_metricas_comic y trg_inicializar_metricas_run
-- Regla: Al insertar un Comic o un Run, popularidad y ejemplaresVendidos se
-- fuerzan en 0.0 y 0 sin importar los valores enviados en el INSERT.
-- ============================================================================
INSERT INTO Comic (idComic, nombre, descripcion, fechaInicio, popularidad, ejemplaresVendidos, idEmpresa, idAutor)
VALUES (99, 'Cómic Prueba Inicialización', 'Prueba de inicialización en cero', '2010-01-01', 4.9, 500000, 1, 1);

INSERT INTO Run (idRun, fechaComienzo, popularidad, ejemplaresVendidos, idComic)
VALUES (99, '2010-01-01', 4.5, 250000, 99);

DO $$
DECLARE
    v_pop_comic    FLOAT;
    v_ventas_comic INTEGER;
    v_pop_run      FLOAT;
    v_ventas_run   INTEGER;
BEGIN
    SELECT popularidad, ejemplaresVendidos INTO v_pop_comic, v_ventas_comic FROM Comic WHERE idComic = 99;
    SELECT popularidad, ejemplaresVendidos INTO v_pop_run, v_ventas_run FROM Run WHERE idRun = 99;

    IF v_pop_comic <> 0.0 OR v_ventas_comic <> 0 OR v_pop_run <> 0.0 OR v_ventas_run <> 0 THEN
        RAISE EXCEPTION 'FALLO PRUEBA 2: Métricas no inicializadas en cero (Comic: %/%, Run: %/%)',
            v_pop_comic, v_ventas_comic, v_pop_run, v_ventas_run;
    END IF;

    RAISE NOTICE 'ÉXITO PRUEBA 2: Comic (%/%) y Run (%/%) inicializados automáticamente en 0.0 y 0.',
        v_pop_comic, v_ventas_comic, v_pop_run, v_ventas_run;
END $$;

-- Limpieza Prueba 2:
DELETE FROM Run WHERE idRun = 99;
DELETE FROM Comic WHERE idComic = 99;


-- ============================================================================
-- PRUEBA 3: Triggers trg_proteger_metricas_run y trg_proteger_metricas_comic
-- Regla: Lanzar RAISE EXCEPTION si se intenta modificar manualmente popularidad
-- o ejemplaresVendidos en Run o Comic con valores distintos al cálculo de hijos.
-- ============================================================================

-- 3.A [Caso de Error Esperado en UPDATE manual de Run]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE Run
        SET ejemplaresVendidos = 999999, popularidad = 1.0
        WHERE idRun = 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 3.A (Modificación manual de Run bloqueada): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 3.A: trg_proteger_metricas_run no bloqueó la modificación manual.';
    END IF;
END $$;

-- 3.B [Caso de Error Esperado en UPDATE manual de Comic]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE Comic
        SET ejemplaresVendidos = 888888, popularidad = 2.0
        WHERE idComic = 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 3.B (Modificación manual de Comic bloqueada): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 3.B: trg_proteger_metricas_comic no bloqueó la modificación manual.';
    END IF;
END $$;


-- ============================================================================
-- PRUEBA 4: Triggers en Cascada (Issue -> Run -> Comic)
-- Regla: INSERT, UPDATE y DELETE en Issue recalculan Run y propagan a Comic.
-- ============================================================================

SELECT 'ESTADO PREVIO' AS estado, r.idRun, r.ejemplaresVendidos AS run_ventas, r.popularidad AS run_pop,
       c.idComic, c.ejemplaresVendidos AS comic_ventas, c.popularidad AS comic_pop
FROM Run r JOIN Comic c ON r.idComic = c.idComic
WHERE r.idRun = 1;

-- 4.A [Caso Exitoso en INSERT de Issue]
INSERT INTO Issue (idIssue, numero, popularidad, ejemplaresVendidos, idRun)
VALUES (99, 999, 5.0, 50000, 1);

SELECT 'TRAS INSERT' AS estado, r.idRun, r.ejemplaresVendidos AS run_ventas, r.popularidad AS run_pop,
       c.idComic, c.ejemplaresVendidos AS comic_ventas, c.popularidad AS comic_pop
FROM Run r JOIN Comic c ON r.idComic = c.idComic
WHERE r.idRun = 1;

-- 4.B [Caso Exitoso en UPDATE de Issue]
UPDATE Issue
SET ejemplaresVendidos = 80000, popularidad = 4.0
WHERE idIssue = 99;

SELECT 'TRAS UPDATE' AS estado, r.idRun, r.ejemplaresVendidos AS run_ventas, r.popularidad AS run_pop,
       c.idComic, c.ejemplaresVendidos AS comic_ventas, c.popularidad AS comic_pop
FROM Run r JOIN Comic c ON r.idComic = c.idComic
WHERE r.idRun = 1;

-- 4.C [Caso Exitoso en DELETE de Issue]
DELETE FROM Issue WHERE idIssue = 99;

SELECT 'TRAS DELETE (RESTAURADO)' AS estado, r.idRun, r.ejemplaresVendidos AS run_ventas, r.popularidad AS run_pop,
       c.idComic, c.ejemplaresVendidos AS comic_ventas, c.popularidad AS comic_pop
FROM Run r JOIN Comic c ON r.idComic = c.idComic
WHERE r.idRun = 1;


-- ============================================================================
-- PRUEBA 5: Trigger trg_unica_portada_principal (Tabla: Cover)
-- Regla: Un Issue solo puede tener una portada principal (esPrincipal = TRUE).
-- ============================================================================

-- 5.A [Caso de Error Esperado en INSERT]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO Cover (idCover, nombre, fechaCreacion, esPrincipal, idIssue, idArtista)
        VALUES (99, 'Spider-Man #1 Duplicate Main Cover', '1963-02-01', TRUE, 1, 3);
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 5.A (Portada principal duplicada en INSERT rechazada): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 5.A: El trigger no impidió la inserción de portada principal duplicada.';
    END IF;
END $$;

-- 5.B [Caso Exitoso en INSERT de Variant Cover]
INSERT INTO Cover (idCover, nombre, fechaCreacion, esPrincipal, idIssue, idArtista)
VALUES (99, 'Spider-Man #1 Variant de Prueba', '1963-02-01', FALSE, 1, 3);

-- 5.C [Caso de Error Esperado en UPDATE a principal duplicada]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE Cover SET esPrincipal = TRUE WHERE idCover = 99;
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 5.C (Portada principal duplicada en UPDATE rechazada): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 5.C: El trigger no impidió la actualización a portada principal duplicada.';
    END IF;
END $$;

DELETE FROM Cover WHERE idCover = 99;


-- ============================================================================
-- PRUEBA 6: Trigger trg_validar_fecha_runautor (Tabla: RunAutor)
-- Regla: fechaInicio del autor no puede ser anterior a fechaComienzo del Run.
-- ============================================================================

-- 6.A [Caso de Error Esperado en INSERT]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO RunAutor (idRunAutor, rol, fechaInicio, idRun, idAutor)
        VALUES (99, 'Guionista Histórico', '1960-01-01', 1, 2);
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 6.A (Fecha anterior al Run en INSERT rechazada): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 6.A: El trigger no impidió asignar fecha previa al inicio del Run.';
    END IF;
END $$;

-- 6.B [Caso Exitoso en INSERT]
INSERT INTO RunAutor (idRunAutor, rol, fechaInicio, idRun, idAutor)
VALUES (99, 'Guionista Co-creador', '1965-06-01', 1, 2);

-- 6.C [Caso de Error Esperado en UPDATE]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE RunAutor SET fechaInicio = '1959-01-01' WHERE idRunAutor = 99;
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 6.C (Fecha anterior al Run en UPDATE rechazada): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 6.C: El trigger no impidió actualizar a una fecha previa al inicio del Run.';
    END IF;
END $$;

DELETE FROM RunAutor WHERE idRunAutor = 99;


-- ============================================================================
-- PRUEBA 7: Trigger trg_validar_paginas (Tabla: ParticipacionArtista)
-- Regla: paginasAsignadas debe ser estrictamente mayor a cero (> 0).
-- ============================================================================

-- 7.A [Caso de Error Esperado en INSERT con 0 páginas]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO ParticipacionArtista (idParticipacionArtista, rol, paginasAsignadas, idIssue, idArtista)
        VALUES (99, 'Colorista', 0, 2, 6);
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 7.A (0 páginas en INSERT rechazadas por trg_validar_paginas): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 7.A: trg_validar_paginas no rechazó paginasAsignadas = 0.';
    END IF;
END $$;

-- 7.B [Caso de Error Esperado en INSERT con páginas negativas]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        INSERT INTO ParticipacionArtista (idParticipacionArtista, rol, paginasAsignadas, idIssue, idArtista)
        VALUES (99, 'Colorista', -4, 2, 6);
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 7.B (Páginas negativas en INSERT rechazadas por trg_validar_paginas): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 7.B: trg_validar_paginas no rechazó paginasAsignadas < 0.';
    END IF;
END $$;

-- 7.C [Caso Exitoso en INSERT con páginas > 0]
INSERT INTO ParticipacionArtista (idParticipacionArtista, rol, paginasAsignadas, idIssue, idArtista)
VALUES (99, 'Colorista', 12, 2, 6);

-- 7.D [Caso de Error Esperado en UPDATE con 0 páginas]
DO $$
DECLARE
    v_capturada BOOLEAN := FALSE;
BEGIN
    BEGIN
        UPDATE ParticipacionArtista SET paginasAsignadas = 0 WHERE idParticipacionArtista = 99;
    EXCEPTION
        WHEN OTHERS THEN
            v_capturada := TRUE;
            RAISE NOTICE 'ÉXITO 7.D (0 páginas en UPDATE rechazadas por trg_validar_paginas): %', SQLERRM;
    END;

    IF NOT v_capturada THEN
        RAISE EXCEPTION 'FALLO 7.D: trg_validar_paginas no rechazó UPDATE a paginasAsignadas = 0.';
    END IF;
END $$;

DELETE FROM ParticipacionArtista WHERE idParticipacionArtista = 99;
