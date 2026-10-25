-- =============================================================================
-- __NNNN__-scopes-__servicio__.sql
-- Proyecto  : nova-seguridad · permisos del servicio nova-__servicio__ (creado por la skill nuevo-modulo)
-- Qué hace  : da __servicio__.leer y __servicio__.escribir a los roles cliente, operador y admin
--             (qué registros ve cada uno lo decide nova-__servicio__: el cliente, solo los suyos)
-- Ambiente  : cualquiera (el ejecutor elige la base; aquí no hay USE)
-- Respaldo  : no requiere (solo inserta lo que falta)
-- =============================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    PRINT 'Paso 1/1: scopes de __servicio__ por rol';
    INSERT INTO dbo.RolScopes (RolId, Scope)
    SELECT v.RolId, v.Scope
    FROM (VALUES
        (1, N'__servicio__.leer'), (1, N'__servicio__.escribir'),
        (2, N'__servicio__.leer'), (2, N'__servicio__.escribir'),
        (3, N'__servicio__.leer'), (3, N'__servicio__.escribir'))
        AS v (RolId, Scope)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.RolScopes rs WHERE rs.RolId = v.RolId AND rs.Scope = v.Scope);

    -- Validación posterior: los 3 roles tienen los 2 scopes.
    IF (SELECT COUNT(*) FROM dbo.RolScopes WHERE RolId IN (1, 2, 3) AND Scope IN (N'__servicio__.leer', N'__servicio__.escribir')) <> 6
        THROW 50003, 'Validación: faltan scopes de __servicio__ en algún rol.', 1;

    COMMIT;
    PRINT 'OK: scopes de __servicio__ listos.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH
