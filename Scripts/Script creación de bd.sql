-- 1. Creación de Dominios personalizados para mantener las reglas de negocio centralizados
CREATE DOMAIN t_id AS INTEGER CHECK (VALUE > 0);
CREATE DOMAIN t_nombre_persona AS VARCHAR(30);
CREATE DOMAIN t_nombre_empresa AS VARCHAR(30);
CREATE DOMAIN t_nombre_obra AS VARCHAR(50);
CREATE DOMAIN t_descripcion AS VARCHAR(255);
CREATE DOMAIN t_rol AS VARCHAR(30);
CREATE DOMAIN t_fecha AS DATE;
CREATE DOMAIN t_popularidad AS FLOAT CHECK (VALUE >= 0.0 AND VALUE <= 5.0);
CREATE DOMAIN t_cantidad AS INTEGER CHECK (VALUE >= 0);
CREATE DOMAIN t_numero_issue AS INTEGER CHECK (VALUE > 0);
CREATE DOMAIN t_booleano AS BOOLEAN;

-- 2. Creación de Tablas (respetando el orden de dependencias)
CREATE TABLE Persona (
    idPersona t_id PRIMARY KEY,
    nombre t_nombre_persona NOT NULL,
    apellidos t_nombre_persona NOT NULL,
    alias t_nombre_persona NULL,
    fechaNacimiento t_fecha NOT NULL,
    fechaComienzo t_fecha NOT NULL
);

CREATE TABLE Artista (
    idArtista t_id PRIMARY KEY,

    idPersona t_id NOT NULL,

    FOREIGN KEY (idPersona) REFERENCES Persona(idPersona)
);




CREATE TABLE Autor (
    idAutor t_id PRIMARY KEY,

    idPersona t_id NOT NULL,

    FOREIGN KEY (idPersona) REFERENCES Persona(idPersona)
);

CREATE TABLE Empresa (
    idEmpresa t_id PRIMARY KEY,
    nombre t_nombre_empresa NOT NULL
);

CREATE TABLE Comic (
    idComic t_id PRIMARY KEY,
    nombre t_nombre_obra NOT NULL,
    descripcion t_descripcion NOT NULL,
    fechaInicio t_fecha NOT NULL,
    popularidad t_popularidad NOT NULL,
    ejemplaresVendidos t_cantidad NOT NULL,

    idEmpresa t_id NOT NULL,
    idAutor t_id NOT NULL,

    FOREIGN KEY (idEmpresa) REFERENCES Empresa(idEmpresa),
    FOREIGN KEY (idAutor) REFERENCES Autor(idAutor)
);

CREATE TABLE Run (
    idRun t_id PRIMARY KEY,
    fechaComienzo t_fecha NOT NULL,
    popularidad t_popularidad NOT NULL,
    ejemplaresVendidos t_cantidad NOT NULL,

    idComic t_id NOT NULL,

    FOREIGN KEY (idComic) REFERENCES Comic(idComic)
);



CREATE TABLE Issue (
    idIssue t_id PRIMARY KEY,
    numero t_numero_issue NOT NULL,
    popularidad t_popularidad NOT NULL,
    ejemplaresVendidos t_cantidad NOT NULL,

    idRun t_id NOT NULL,

    FOREIGN KEY (idRun) REFERENCES Run(idRun)
);

CREATE TABLE Cover (
    idCover t_id PRIMARY KEY,
    nombre t_nombre_obra NOT NULL,
    fechaCreacion t_fecha NOT NULL,
    esPrincipal t_booleano NOT NULL,

    idIssue t_id NOT NULL,
    idArtista t_id NOT NULL,

    FOREIGN KEY (idIssue) REFERENCES Issue(idIssue),
    FOREIGN KEY (idArtista) REFERENCES Artista(idArtista)
);

CREATE TABLE ParticipacionArtista (
    idParticipacionArtista t_id PRIMARY KEY,
    rol t_rol NOT NULL,
    paginasAsignadas t_cantidad NOT NULL,

    idIssue t_id NOT NULL,
    idArtista t_id NOT NULL,

    FOREIGN KEY (idIssue) REFERENCES Issue(idIssue),
    FOREIGN KEY (idArtista) REFERENCES Artista(idArtista)
);


CREATE TABLE RunAutor (
    idRunAutor t_id PRIMARY KEY,
    rol t_rol NOT NULL,
    fechaInicio t_fecha NOT NULL,

    idRun t_id NOT NULL,
    idAutor t_id NOT NULL,

    FOREIGN KEY (idRun) REFERENCES Run(idRun),
    FOREIGN KEY (idAutor) REFERENCES Autor(idAutor)
);
