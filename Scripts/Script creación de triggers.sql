-- ============================================================================
-- SCRIPT DE CREACIÓN DE TRIGGERS (PROPUESTA 6: COMICS ARCHIVE)
-- Descripción: Definición de funciones trigger y triggers para inicialización,
-- cálculo en cascada, protección contra modificación manual y validación de
-- reglas de negocio e integridad temporal.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TRIGGER: trg_set_fecha_comienzo_null (Tabla: Persona)
-- Regla de Negocio: Al dar de alta una Persona, su fechaComienzo debe iniciarse
-- obligatoriamente en NULL hasta que se registre su primer cómic como autor.
-- Tipo: BEFORE INSERT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_set_fecha_comienzo_null_func()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fechaComienzo := NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_fecha_comienzo_null ON Persona;
CREATE TRIGGER trg_set_fecha_comienzo_null
BEFORE INSERT ON Persona
FOR EACH ROW
EXECUTE FUNCTION trg_set_fecha_comienzo_null_func();


-- ----------------------------------------------------------------------------
-- 2. TRIGGER: trg_actualizar_fecha_comienzo_autor (Tabla: Comic)
-- Regla de Negocio: Cada vez que se registra o actualiza un cómic, validar que
-- Comic.fechaInicio > Persona.fechaNacimiento del autor (lanzando excepción en
-- caso contrario) y actualizar automáticamente Persona.fechaComienzo con la
-- mínima fechaInicio entre todos los cómics asociados a dicho autor.
-- Tipo: AFTER INSERT OR DELETE OR UPDATE OF fechaInicio, idAutor
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_actualizar_fecha_comienzo_autor_func()
RETURNS TRIGGER AS $$
DECLARE
    v_idPersona       INTEGER;
    v_fechaNacimiento DATE;
    v_idPersonaOld    INTEGER;
BEGIN
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        SELECT p.idPersona, p.fechaNacimiento
        INTO v_idPersona, v_fechaNacimiento
        FROM Autor a
        JOIN Persona p ON p.idPersona = a.idPersona
        WHERE a.idAutor = NEW.idAutor;

        IF NEW.fechaInicio <= v_fechaNacimiento THEN
            RAISE EXCEPTION 'La fecha de inicio del cómic (%) debe ser posterior a la fecha de nacimiento del autor (%).',
                NEW.fechaInicio, v_fechaNacimiento;
        END IF;

        UPDATE Persona
        SET fechaComienzo = (
            SELECT MIN(c.fechaInicio)
            FROM Comic c
            JOIN Autor a ON a.idAutor = c.idAutor
            WHERE a.idPersona = v_idPersona
        )
        WHERE idPersona = v_idPersona;
    END IF;

    -- Si cambió el autor en un UPDATE o se eliminó un cómic, recalcular también al autor anterior
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.idAutor <> NEW.idAutor) THEN
        SELECT a.idPersona
        INTO v_idPersonaOld
        FROM Autor a
        WHERE a.idAutor = OLD.idAutor;

        IF v_idPersonaOld IS NOT NULL THEN
            UPDATE Persona
            SET fechaComienzo = (
                SELECT MIN(c.fechaInicio)
                FROM Comic c
                JOIN Autor a ON a.idAutor = c.idAutor
                WHERE a.idPersona = v_idPersonaOld
            )
            WHERE idPersona = v_idPersonaOld;
        END IF;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_fecha_comienzo_autor ON Comic;
CREATE TRIGGER trg_actualizar_fecha_comienzo_autor
AFTER INSERT OR DELETE OR UPDATE OF fechaInicio, idAutor ON Comic
FOR EACH ROW
EXECUTE FUNCTION trg_actualizar_fecha_comienzo_autor_func();


-- ----------------------------------------------------------------------------
-- 3. TRIGGER: trg_inicializar_metricas_comic (Tabla: Comic)
-- Regla de Negocio: Al crear un nuevo Cómic, su popularidad y ejemplaresVendidos
-- deben inicializarse automáticamente en 0.0 y 0 respectivamente.
-- Tipo: BEFORE INSERT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_inicializar_metricas_comic_func()
RETURNS TRIGGER AS $$
BEGIN
    NEW.popularidad := 0.0;
    NEW.ejemplaresVendidos := 0;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inicializar_metricas_comic ON Comic;
CREATE TRIGGER trg_inicializar_metricas_comic
BEFORE INSERT ON Comic
FOR EACH ROW
EXECUTE FUNCTION trg_inicializar_metricas_comic_func();


-- ----------------------------------------------------------------------------
-- 4. TRIGGER: trg_inicializar_metricas_run (Tabla: Run)
-- Regla de Negocio: Al crear un nuevo Run, su popularidad y ejemplaresVendidos
-- deben inicializarse automáticamente en 0.0 y 0 respectivamente.
-- Tipo: BEFORE INSERT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_inicializar_metricas_run_func()
RETURNS TRIGGER AS $$
BEGIN
    NEW.popularidad := 0.0;
    NEW.ejemplaresVendidos := 0;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inicializar_metricas_run ON Run;
CREATE TRIGGER trg_inicializar_metricas_run
BEFORE INSERT ON Run
FOR EACH ROW
EXECUTE FUNCTION trg_inicializar_metricas_run_func();


-- ----------------------------------------------------------------------------
-- 5. TRIGGER: trg_proteger_metricas_run (Tabla: Run)
-- Regla de Negocio: Impedir la modificación manual directa de popularidad y
-- ejemplaresVendidos en Run. Si los valores recibidos en el UPDATE no coinciden
-- con el cálculo automático derivado de sus Issues hijos, lanza excepción.
-- Tipo: BEFORE UPDATE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_proteger_metricas_run_func()
RETURNS TRIGGER AS $$
DECLARE
    v_ventasCalculadas INTEGER;
    v_popCalculada     FLOAT;
BEGIN
    SELECT 
        COALESCE(SUM(ejemplaresVendidos), 0),
        COALESCE(ROUND(AVG(popularidad)::numeric, 2)::FLOAT, 0.0)
    INTO v_ventasCalculadas, v_popCalculada
    FROM Issue
    WHERE idRun = NEW.idRun;

    IF NEW.ejemplaresVendidos <> v_ventasCalculadas
       OR NEW.popularidad IS DISTINCT FROM v_popCalculada THEN
        RAISE EXCEPTION 'No se permite modificar manualmente las métricas del Run %. Valores calculados desde sus Issues: ejemplaresVendidos = %, popularidad = %.',
            NEW.idRun, v_ventasCalculadas, v_popCalculada;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_proteger_metricas_run ON Run;
CREATE TRIGGER trg_proteger_metricas_run
BEFORE UPDATE ON Run
FOR EACH ROW
EXECUTE FUNCTION trg_proteger_metricas_run_func();


-- ----------------------------------------------------------------------------
-- 6. TRIGGER: trg_proteger_metricas_comic (Tabla: Comic)
-- Regla de Negocio: Impedir la modificación manual directa de popularidad y
-- ejemplaresVendidos en Comic. Si los valores recibidos en el UPDATE no coinciden
-- con el cálculo automático derivado de sus Runs hijos, lanza excepción.
-- Tipo: BEFORE UPDATE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_proteger_metricas_comic_func()
RETURNS TRIGGER AS $$
DECLARE
    v_ventasCalculadas INTEGER;
    v_popCalculada     FLOAT;
BEGIN
    SELECT 
        COALESCE(SUM(ejemplaresVendidos), 0),
        COALESCE(ROUND(AVG(popularidad)::numeric, 2)::FLOAT, 0.0)
    INTO v_ventasCalculadas, v_popCalculada
    FROM Run
    WHERE idComic = NEW.idComic;

    IF NEW.ejemplaresVendidos <> v_ventasCalculadas
       OR NEW.popularidad IS DISTINCT FROM v_popCalculada THEN
        RAISE EXCEPTION 'No se permite modificar manualmente las métricas del Cómic %. Valores calculados desde sus Runs: ejemplaresVendidos = %, popularidad = %.',
            NEW.idComic, v_ventasCalculadas, v_popCalculada;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_proteger_metricas_comic ON Comic;
CREATE TRIGGER trg_proteger_metricas_comic
BEFORE UPDATE ON Comic
FOR EACH ROW
EXECUTE FUNCTION trg_proteger_metricas_comic_func();


-- ----------------------------------------------------------------------------
-- 7. TRIGGER: trg_actualizar_ventas_run (Tabla: Issue)
-- Regla de Negocio: Al insertar, modificar o eliminar un Issue, recalcular y
-- propagar automáticamente la suma de ventas y promedio de popularidad a su Run.
-- Tipo: AFTER INSERT OR UPDATE OR DELETE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_actualizar_ventas_run_func()
RETURNS TRIGGER AS $$
DECLARE
    v_idRun               INTEGER;
    v_totalVentas         INTEGER;
    v_promedioPopularidad FLOAT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_idRun := OLD.idRun;
    ELSE
        v_idRun := NEW.idRun;
    END IF;

    SELECT 
        COALESCE(SUM(ejemplaresVendidos), 0),
        COALESCE(ROUND(AVG(popularidad)::numeric, 2)::FLOAT, 0.0)
    INTO v_totalVentas, v_promedioPopularidad
    FROM Issue
    WHERE idRun = v_idRun;

    UPDATE Run
    SET ejemplaresVendidos = v_totalVentas,
        popularidad = v_promedioPopularidad
    WHERE idRun = v_idRun;

    -- Si se actualizó el idRun de un Issue, actualizar también el Run anterior
    IF TG_OP = 'UPDATE' AND OLD.idRun <> NEW.idRun THEN
        SELECT 
            COALESCE(SUM(ejemplaresVendidos), 0),
            COALESCE(ROUND(AVG(popularidad)::numeric, 2)::FLOAT, 0.0)
        INTO v_totalVentas, v_promedioPopularidad
        FROM Issue
        WHERE idRun = OLD.idRun;

        UPDATE Run
        SET ejemplaresVendidos = v_totalVentas,
            popularidad = v_promedioPopularidad
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


-- ----------------------------------------------------------------------------
-- 8. TRIGGER: trg_actualizar_metricas_comic (Tabla: Run)
-- Regla de Negocio: Al insertarse, actualizarse o eliminarse un Run, propagar
-- automáticamente las ventas acumuladas y el promedio de popularidad a Comic.
-- Tipo: AFTER INSERT OR UPDATE OR DELETE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_actualizar_metricas_comic_func()
RETURNS TRIGGER AS $$
DECLARE
    v_idComic             INTEGER;
    v_totalVentas         INTEGER;
    v_promedioPopularidad FLOAT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_idComic := OLD.idComic;
    ELSE
        v_idComic := NEW.idComic;
    END IF;

    SELECT 
        COALESCE(SUM(ejemplaresVendidos), 0),
        COALESCE(ROUND(AVG(popularidad)::numeric, 2)::FLOAT, 0.0)
    INTO v_totalVentas, v_promedioPopularidad
    FROM Run
    WHERE idComic = v_idComic;

    UPDATE Comic
    SET ejemplaresVendidos = v_totalVentas,
        popularidad = v_promedioPopularidad
    WHERE idComic = v_idComic;

    IF TG_OP = 'UPDATE' AND OLD.idComic <> NEW.idComic THEN
        SELECT 
            COALESCE(SUM(ejemplaresVendidos), 0),
            COALESCE(ROUND(AVG(popularidad)::numeric, 2)::FLOAT, 0.0)
        INTO v_totalVentas, v_promedioPopularidad
        FROM Run
        WHERE idComic = OLD.idComic;

        UPDATE Comic
        SET ejemplaresVendidos = v_totalVentas,
            popularidad = v_promedioPopularidad
        WHERE idComic = OLD.idComic;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_metricas_comic ON Run;
CREATE TRIGGER trg_actualizar_metricas_comic
AFTER INSERT OR UPDATE OR DELETE ON Run
FOR EACH ROW
EXECUTE FUNCTION trg_actualizar_metricas_comic_func();


-- ----------------------------------------------------------------------------
-- 9. TRIGGER: trg_unica_portada_principal (Tabla: Cover)
-- Regla de Negocio: Cada número (Issue) puede tener múltiples variant covers,
-- pero únicamente UNA portada principal (esPrincipal = TRUE).
-- Tipo: BEFORE INSERT OR UPDATE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_unica_portada_principal_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.esPrincipal = TRUE THEN
        IF EXISTS (
            SELECT 1 
            FROM Cover 
            WHERE idIssue = NEW.idIssue 
              AND esPrincipal = TRUE 
              AND idCover <> COALESCE(NEW.idCover, 0)
        ) THEN
            RAISE EXCEPTION 'El Issue % ya posee una portada principal asignada.', NEW.idIssue;
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


-- ----------------------------------------------------------------------------
-- 10. TRIGGER: trg_validar_fecha_runautor (Tabla: RunAutor)
-- Regla de Negocio: La fecha de incorporación de un autor a un Run no puede
-- ser anterior a la fecha de inicio del Run mismo.
-- Tipo: BEFORE INSERT OR UPDATE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_validar_fecha_runautor_func()
RETURNS TRIGGER AS $$
DECLARE
    v_fechaComienzoRun DATE;
BEGIN
    SELECT fechaComienzo INTO v_fechaComienzoRun
    FROM Run
    WHERE idRun = NEW.idRun;

    IF NEW.fechaInicio < v_fechaComienzoRun THEN
        RAISE EXCEPTION 'La fecha de inicio del autor (%) no puede ser anterior al inicio del Run (%).', 
            NEW.fechaInicio, v_fechaComienzoRun;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_fecha_runautor ON RunAutor;
CREATE TRIGGER trg_validar_fecha_runautor
BEFORE INSERT OR UPDATE ON RunAutor
FOR EACH ROW
EXECUTE FUNCTION trg_validar_fecha_runautor_func();


-- ----------------------------------------------------------------------------
-- 11. TRIGGER: trg_validar_paginas (Tabla: ParticipacionArtista)
-- Regla de Negocio: La cantidad de páginas interiores asignadas a un artista
-- en un Issue debe ser estrictamente mayor a cero (paginasAsignadas > 0).
-- Tipo: BEFORE INSERT OR UPDATE
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_validar_paginas_func()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.paginasAsignadas IS NULL OR NEW.paginasAsignadas <= 0 THEN
        RAISE EXCEPTION 'La cantidad de páginas asignadas (%) en el Issue % debe ser estrictamente mayor a cero.',
            NEW.paginasAsignadas, NEW.idIssue;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_paginas ON ParticipacionArtista;
CREATE TRIGGER trg_validar_paginas
BEFORE INSERT OR UPDATE ON ParticipacionArtista
FOR EACH ROW
EXECUTE FUNCTION trg_validar_paginas_func();
