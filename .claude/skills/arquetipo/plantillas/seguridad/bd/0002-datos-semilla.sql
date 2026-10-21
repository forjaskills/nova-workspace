-- =============================================================================
-- 0002-datos-semilla.sql
-- Proyecto  : nova-__nombre__ (creado por la skill arquetipo)
-- Qué hace  : roles base y usuarios de DEMO (clave NovaDemo#1, solo para el proyecto de ejemplo)
-- Ambiente  : DEV y QA. En una empresa, PROD no lleva usuarios demo.
-- Respaldo  : no requiere (solo inserta lo que falta)
-- =============================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    PRINT 'Paso 1/3: roles cliente, operador y admin';
    INSERT INTO dbo.Roles (Id, Nombre)
    SELECT v.Id, v.Nombre
    FROM (VALUES (1, N'cliente'), (2, N'operador'), (3, N'admin')) AS v (Id, Nombre)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles r WHERE r.Id = v.Id);

    -- Cada servicio nuevo agrega sus scopes (pedidos.leer, pedidos.escribir...) en su propio script.
    INSERT INTO dbo.RolScopes (RolId, Scope)
    SELECT 3, N'seguridad.admin'
    WHERE NOT EXISTS (SELECT 1 FROM dbo.RolScopes WHERE RolId = 3 AND Scope = N'seguridad.admin');

    PRINT 'Paso 2/3: usuarios demo';
    INSERT INTO dbo.Usuarios (Id, NombreUsuario, HashClave)
    SELECT v.Id, v.NombreUsuario, v.HashClave
    FROM (VALUES
        ('6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e01', N'cliente.demo',  N'AQAAAAIAAYagAAAAEPvhHIvt9Lf0654n+fud8lMOryOrAhMPC/qx3K2+6nZts1h24Tkp4vmMCeN0FV/JWQ=='),
        ('6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e02', N'operador.demo', N'AQAAAAIAAYagAAAAEN2tOaJOOaE4SIkQcQ07gLdqp70V/3c8eqJwA4wMW6IPid2m6dzbofuX1Q5+A94/uA=='),
        ('6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e03', N'admin.demo',    N'AQAAAAIAAYagAAAAEOMu/uefJicX1SExnhoeGVf740OYhrmNA3ER3XOBAVUNU53U3A9AUHa89YtX1dY0Hg=='))
        AS v (Id, NombreUsuario, HashClave)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Usuarios u WHERE u.NombreUsuario = v.NombreUsuario);

    PRINT 'Paso 3/3: roles de cada usuario';
    INSERT INTO dbo.UsuarioRoles (UsuarioId, RolId)
    SELECT v.UsuarioId, v.RolId
    FROM (VALUES
        ('6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e01', 1),
        ('6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e02', 2),
        ('6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e03', 3))
        AS v (UsuarioId, RolId)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.UsuarioRoles ur WHERE ur.UsuarioId = v.UsuarioId AND ur.RolId = v.RolId);

    -- Validación posterior: 3 roles y los 3 usuarios demo con su rol.
    IF (SELECT COUNT(*) FROM dbo.Roles WHERE Id IN (1, 2, 3)) <> 3
       OR (SELECT COUNT(*) FROM dbo.UsuarioRoles WHERE UsuarioId IN (
            '6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e01', '6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e02', '6f1c3a52-6a0e-4c8e-9a51-1a2b3c4d5e03')) <> 3
        THROW 50002, 'Validación: faltan roles o usuarios demo.', 1;

    COMMIT;
    PRINT 'OK: datos semilla listos.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH
