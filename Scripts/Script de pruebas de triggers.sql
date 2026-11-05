-- ============================================================================
-- SCRIPT DE DEFINICIÓN Y PRUEBAS DE TRIGGERS
-- Proyecto: TP FINAL BD - Propuesta 6 (Comics Archive)
-- ============================================================================
-- NOTA:
-- 1. Se aseguran las funciones y triggers definidos en el proyecto.
-- 2. Se limpian los datos de prueba (IDs >= 100) al inicio y al final para que
--    el script sea re-ejecutable infinitas veces sin pisarse ni dar error de PK.
-- 3. Cada caso de error esperado está encapsulado en un bloque DO $$ ... EXCEPTION
--    para capturar su mensaje específico (RAISE NOTICE) sin abortar las pruebas
--    siguientes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. ASEGURAR DEFINICIÓN DE LOS 4 TRIGGERS DEL MODELO
-- ----------------------------------------------------------------------------

-- Trigger 1: Única portada principal por Issue (Tabla Cover)
CREATE OR REPLACE FUNCTION trg_unica_portada_principal_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.esPrincipal = TRUE THEN
        IF EXISTS (
            SELECT 1 FROM Cover
            WHERE idIssue = NEW.idIssue
              AND esPrincipal = TRUE
              AND idCover != NEW.idCover
        ) THEN
            RAISE EXCEPTION 'Ya existe una portada principal para el Issue %', NEW.idIssue;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_unica_portada_principal ON Cover;
CREATE TRIGGER trg_unica_portada_principal
BEFORE INSERT OR UPDATE ON Cover
FOR EACH ROW
EXECUTE FUNCTION trg_unica_portada_principal_func();


-- Trigger 2: Recalcular ejemplaresVendidos en Run (Tabla Issue)
CREATE OR REPLACE FUNCTION trg_actualizar_ventas_run_func()
RETURNS TRIGGER AS $$
DECLARE
    v_idRun INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_idRun := OLD.idRun;
    ELSE
        v_idRun := NEW.idRun;
    END IF;

    UPDATE Run
    SET ejemplaresVendidos = COALESCE((
        SELECT SUM(ejemplaresVendidos)
        FROM Issue
        WHERE idRun = v_idRun
    ), 0)
    WHERE idRun = v_idRun;

    IF TG_OP = 'UPDATE' AND OLD.idRun != NEW.idRun THEN
        UPDATE Run
        SET ejemplaresVendidos = COALESCE((
            SELECT SUM(ejemplaresVendidos)
            FROM Issue
            WHERE idRun = OLD.idRun
        ), 0)
        WHERE idRun = OLD.idRun;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_ventas_run ON Issue;
CREATE TRIGGER trg_actualizar_ventas_run
AFTER INSERT OR UPDATE OR DELETE ON Issue
FOR EACH ROW
EXECUTE FUNCTION trg_actualizar_ventas_run_func();


-- Trigger 3: Validar fechaInicio de RunAutor respecto a fechaComienzo de Run
CREATE OR REPLACE FUNCTION trg_validar_fecha_runautor_func()
RETURNS TRIGGER AS $$
DECLARE
    v_fechaComienzoRun DATE;
BEGIN
    SELECT fechaComienzo INTO v_fechaComienzoRun
    FROM Run
    WHERE idRun = NEW.idRun;

    IF NEW.fechaInicio < v_fechaComienzoRun THEN
        RAISE EXCEPTION 'La fecha de inicio del autor (%) no puede ser anterior al comienzo del run (%)', NEW.fechaInicio, v_fechaComienzoRun;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_fecha_runautor ON RunAutor;
CREATE TRIGGER trg_validar_fecha_runautor
BEFORE INSERT OR UPDATE ON RunAutor
FOR EACH ROW
EXECUTE FUNCTION trg_validar_fecha_runautor_func();


-- Trigger 4: Validar que la suma de páginas asignadas a un Issue sea > 0
CREATE OR REPLACE FUNCTION trg_validar_paginas_func()
RETURNS TRIGGER AS $$
DECLARE
    v_totalPaginas INTEGER;
BEGIN
    SELECT SUM(paginasAsignadas) INTO v_totalPaginas
    FROM ParticipacionArtista
    WHERE idIssue = NEW.idIssue;

    IF v_totalPaginas <= 0 THEN
        RAISE EXCEPTION 'La suma de páginas asignadas para el Issue % debe ser mayor a cero', NEW.idIssue;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_paginas ON ParticipacionArtista;
CREATE TRIGGER trg_validar_paginas
AFTER INSERT OR UPDATE ON ParticipacionArtista
FOR EACH ROW
EXECUTE FUNCTION trg_validar_paginas_func();


-- ----------------------------------------------------------------------------
-- LIMPIEZA PREVIA DE TUPLAS DE PRUEBA (evita colisiones al re-ejecutar)
-- ----------------------------------------------------------------------------
DELETE FROM Cover WHERE idCover >= 100;
DELETE FROM ParticipacionArtista WHERE idParticipacionArtista >= 100;
DELETE FROM RunAutor WHERE idRunAutor >= 100;
DELETE FROM Issue WHERE idIssue >= 100;


-- ============================================================================
-- PRUEBA 1: Trigger trg_unica_portada_principal (Tabla Cover)
-- Regla: Previene que exista más de una portada principal (esPrincipal = TRUE) por Issue.
-- ============================================================================

-- 1.A [Caso Exitoso] Insertar una variante (esPrincipal = FALSE) para el Issue 1:
INSERT INTO Cover (idCover, nombre, fechaCreacion, esPrincipal, idIssue, idArtista)
VALUES (101, 'Spider-Man #1 Second Printing Variant', '1963-02-01', FALSE, 1, 1);

-- 1.B [Caso de Error Esperado en INSERT] Intentar insertar una SEGUNDA portada principal para el Issue 1:
DO $$
BEGIN
    INSERT INTO Cover (idCover, nombre, fechaCreacion, esPrincipal, idIssue, idArtista)
    VALUES (102, 'Spider-Man #1 Alternate Main Cover', '1963-02-05', TRUE, 1, 3);
    RAISE NOTICE '[PRUEBA 1 - INSERT] ERROR: No falló y se esperaba excepción.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PRUEBA 1 - INSERT] OK (Excepción capturada) -> %', SQLERRM;
END $$;

-- 1.C [Caso de Error Esperado en UPDATE] Intentar convertir la variante 101 en portada principal del Issue 1:
DO $$
BEGIN
    UPDATE Cover SET esPrincipal = TRUE WHERE idCover = 101;
    RAISE NOTICE '[PRUEBA 1 - UPDATE] ERROR: No falló y se esperaba excepción.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PRUEBA 1 - UPDATE] OK (Excepción capturada) -> %', SQLERRM;
END $$;


-- ============================================================================
-- PRUEBA 2: Trigger trg_actualizar_ventas_run (Tabla Issue)
-- Regla: Recalcula automáticamente ejemplaresVendidos en Run al insertar/actualizar/eliminar Issues.
-- ============================================================================

DO $$
DECLARE
    v_ventas_inicial INTEGER;
    v_ventas_insert  INTEGER;
    v_ventas_update  INTEGER;
    v_ventas_delete  INTEGER;
BEGIN
    SELECT ejemplaresVendidos INTO v_ventas_inicial FROM Run WHERE idRun = 1;
    RAISE NOTICE '[PRUEBA 2 - Estado Inicial] Run 1 ejemplaresVendidos = % (esperado: 270000)', v_ventas_inicial;

    -- 2.A [Caso Exitoso INSERT] Insertar Issue 101 en Run 1 con 50,000 ejemplares:
    INSERT INTO Issue (idIssue, numero, popularidad, ejemplaresVendidos, idRun)
    VALUES (101, 3, 4.5, 50000, 1);

    SELECT ejemplaresVendidos INTO v_ventas_insert FROM Run WHERE idRun = 1;
    RAISE NOTICE '[PRUEBA 2 - Tras INSERT (+50000)] Run 1 ejemplaresVendidos = % (esperado: 320000)', v_ventas_insert;

    -- 2.B [Caso Exitoso UPDATE] Modificar ejemplaresVendidos del Issue 101 a 80,000:
    UPDATE Issue SET ejemplaresVendidos = 80000 WHERE idIssue = 101;

    SELECT ejemplaresVendidos INTO v_ventas_update FROM Run WHERE idRun = 1;
    RAISE NOTICE '[PRUEBA 2 - Tras UPDATE (a 80000)] Run 1 ejemplaresVendidos = % (esperado: 350000)', v_ventas_update;

    -- 2.C [Caso Exitoso DELETE] Eliminar Issue 101 y verificar restitución a 270,000:
    DELETE FROM Issue WHERE idIssue = 101;

    SELECT ejemplaresVendidos INTO v_ventas_delete FROM Run WHERE idRun = 1;
    RAISE NOTICE '[PRUEBA 2 - Tras DELETE] Run 1 ejemplaresVendidos = % (esperado: 270000)', v_ventas_delete;
END $$;


-- ============================================================================
-- PRUEBA 3: Trigger trg_validar_fecha_runautor (Tabla RunAutor)
-- Regla: La fechaInicio del autor no puede ser anterior a la fechaComienzo del Run.
-- ============================================================================

-- 3.A [Caso Exitoso] Insertar fechaInicio ('1963-04-01') posterior a fechaComienzo de Run 1 ('1963-03-01'):
INSERT INTO RunAutor (idRunAutor, rol, fechaInicio, idRun, idAutor)
VALUES (101, 'Co-Escritor', '1963-04-01', 1, 6);

-- 3.B [Caso de Error Esperado en INSERT] Intentar insertar fechaInicio ('1960-01-01') anterior al Run 1 ('1963-03-01'):
DO $$
BEGIN
    INSERT INTO RunAutor (idRunAutor, rol, fechaInicio, idRun, idAutor)
    VALUES (102, 'Guionista Fantasma', '1960-01-01', 1, 7);
    RAISE NOTICE '[PRUEBA 3 - INSERT] ERROR: No falló y se esperaba excepción.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PRUEBA 3 - INSERT] OK (Excepción capturada) -> %', SQLERRM;
END $$;

-- 3.C [Caso de Error Esperado en UPDATE] Intentar actualizar fechaInicio de RunAutor 101 a una fecha anterior al Run 1:
DO $$
BEGIN
    UPDATE RunAutor SET fechaInicio = '1950-05-01' WHERE idRunAutor = 101;
    RAISE NOTICE '[PRUEBA 3 - UPDATE] ERROR: No falló y se esperaba excepción.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PRUEBA 3 - UPDATE] OK (Excepción capturada) -> %', SQLERRM;
END $$;


-- ============================================================================
-- PRUEBA 4: Trigger trg_validar_paginas (Tabla ParticipacionArtista)
-- Regla: La suma total de páginas asignadas a un Issue debe ser mayor a cero.
-- (Se utiliza el Issue 2, que no posee otras participaciones previas).
-- ============================================================================

-- 4.A [Caso de Error Esperado en INSERT] Intentar insertar participación con 0 páginas en el Issue 2:
DO $$
BEGIN
    INSERT INTO ParticipacionArtista (idParticipacionArtista, rol, paginasAsignadas, idIssue, idArtista)
    VALUES (101, 'Colorista', 0, 2, 6);
    RAISE NOTICE '[PRUEBA 4 - INSERT] ERROR: No falló y se esperaba excepción.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PRUEBA 4 - INSERT] OK (Excepción capturada) -> %', SQLERRM;
END $$;

-- 4.B [Caso Exitoso] Asignar 10 páginas para el Issue 2:
INSERT INTO ParticipacionArtista (idParticipacionArtista, rol, paginasAsignadas, idIssue, idArtista)
VALUES (101, 'Colorista', 10, 2, 6);

-- 4.C [Caso de Error Esperado en UPDATE] Intentar actualizar paginasAsignadas a 0 en el Issue 2:
DO $$
BEGIN
    UPDATE ParticipacionArtista SET paginasAsignadas = 0 WHERE idParticipacionArtista = 101;
    RAISE NOTICE '[PRUEBA 4 - UPDATE] ERROR: No falló y se esperaba excepción.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[PRUEBA 4 - UPDATE] OK (Excepción capturada) -> %', SQLERRM;
END $$;


-- ============================================================================
-- VERIFICACIÓN DE TUPLAS VÁLIDAS INSERTADAS DURANTE LAS PRUEBAS Y LIMPIEZA
-- ============================================================================
SELECT idCover, nombre, esPrincipal, idIssue FROM Cover WHERE idCover = 101;
SELECT idRun, fechaComienzo, ejemplaresVendidos FROM Run WHERE idRun = 1;
SELECT idRunAutor, rol, fechaInicio, idRun, idAutor FROM RunAutor WHERE idRunAutor = 101;
SELECT idParticipacionArtista, rol, paginasAsignadas, idIssue FROM ParticipacionArtista WHERE idParticipacionArtista = 101;

-- Limpieza final para dejar la base de datos en su estado original tras la prueba
DELETE FROM Cover WHERE idCover >= 100;
DELETE FROM ParticipacionArtista WHERE idParticipacionArtista >= 100;
DELETE FROM RunAutor WHERE idRunAutor >= 100;
DELETE FROM Issue WHERE idIssue >= 100;
