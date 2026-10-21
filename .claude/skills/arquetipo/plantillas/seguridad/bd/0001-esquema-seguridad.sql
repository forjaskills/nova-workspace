-- =============================================================================
-- 0001-esquema-seguridad.sql
-- Proyecto  : nova-__nombre__ (creado por la skill arquetipo)
-- Qué hace  : tablas de usuarios, roles y scopes
-- Ambiente  : cualquiera (el ejecutor elige la base; aquí no hay USE)
-- Respaldo  : no requiere (solo crea tablas que no existen)
-- =============================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRAN;

    PRINT 'Paso 1/4: tabla Roles';
    IF OBJECT_ID('dbo.Roles') IS NULL
        CREATE TABLE dbo.Roles (
            Id     INT          NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
            Nombre NVARCHAR(50) NOT NULL CONSTRAINT UQ_Roles_Nombre UNIQUE);

    PRINT 'Paso 2/4: tabla RolScopes';
    IF OBJECT_ID('dbo.RolScopes') IS NULL
        CREATE TABLE dbo.RolScopes (
            RolId INT           NOT NULL CONSTRAINT FK_RolScopes_Roles REFERENCES dbo.Roles (Id),
            Scope NVARCHAR(100) NOT NULL,
            CONSTRAINT PK_RolScopes PRIMARY KEY (RolId, Scope));

    PRINT 'Paso 3/4: tabla Usuarios';
    IF OBJECT_ID('dbo.Usuarios') IS NULL
        CREATE TABLE dbo.Usuarios (
            Id            UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Usuarios PRIMARY KEY,
            NombreUsuario NVARCHAR(50)     NOT NULL CONSTRAINT UQ_Usuarios_NombreUsuario UNIQUE,
            HashClave     NVARCHAR(200)    NOT NULL,
            Activo        BIT              NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT 1);

    PRINT 'Paso 4/4: tabla UsuarioRoles';
    IF OBJECT_ID('dbo.UsuarioRoles') IS NULL
        CREATE TABLE dbo.UsuarioRoles (
            UsuarioId UNIQUEIDENTIFIER NOT NULL CONSTRAINT FK_UsuarioRoles_Usuarios REFERENCES dbo.Usuarios (Id),
            RolId     INT              NOT NULL CONSTRAINT FK_UsuarioRoles_Roles REFERENCES dbo.Roles (Id),
            CONSTRAINT PK_UsuarioRoles PRIMARY KEY (UsuarioId, RolId));

    -- Validación posterior: las cuatro tablas existen.
    IF OBJECT_ID('dbo.Roles') IS NULL OR OBJECT_ID('dbo.RolScopes') IS NULL
       OR OBJECT_ID('dbo.Usuarios') IS NULL OR OBJECT_ID('dbo.UsuarioRoles') IS NULL
        THROW 50001, 'Validación: falta alguna tabla de seguridad.', 1;

    COMMIT;
    PRINT 'OK: esquema de seguridad listo.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH
