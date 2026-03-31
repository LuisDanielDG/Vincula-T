CREATE DATABASE IF NOT EXISTS vincula_t
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE vincula_t;

-- ============================================================
-- 1. CARRERAS
-- ============================================================
CREATE TABLE carreras (
    id_carrera        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(150)  NOT NULL,
    clave             VARCHAR(20)   NOT NULL UNIQUE,
    descripcion       TEXT,
    activa            TINYINT(1)    NOT NULL DEFAULT 1,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT='Carreras técnicas ofertadas por el plantel';

-- ============================================================
-- 2. SEMESTRES
-- ============================================================
CREATE TABLE semestres (
    id_semestre       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero            TINYINT UNSIGNED NOT NULL COMMENT '1 al 6',
    turno             ENUM('Matutino','Vespertino','Mixto') NOT NULL DEFAULT 'Matutino',
    ciclo_escolar     VARCHAR(20)  NOT NULL COMMENT 'Ej: 2025-2026',
    id_carrera        INT UNSIGNED NOT NULL,
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_semestre_carrera FOREIGN KEY (id_carrera)
        REFERENCES carreras(id_carrera) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Grupos por semestre, carrera y ciclo escolar';

-- ============================================================
-- 3. USUARIOS
-- ============================================================
CREATE TABLE usuarios (
    id_usuario        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    matricula         VARCHAR(20)   UNIQUE COMMENT 'Matrícula institucional (estudiantes y docentes)',
    nombre            VARCHAR(80)   NOT NULL,
    apellido_paterno  VARCHAR(60)   NOT NULL,
    apellido_materno  VARCHAR(60),
    correo            VARCHAR(120)  NOT NULL UNIQUE,
    password_hash     VARCHAR(255)  NOT NULL,
    rol               ENUM('estudiante','docente','administrativo','directivo','padre') NOT NULL,
    telefono          VARCHAR(15),
    activo            TINYINT(1)    NOT NULL DEFAULT 1,
    ultimo_acceso     DATETIME,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_rol (rol),
    INDEX idx_correo (correo)
) COMMENT='Tabla unificada de usuarios del sistema con roles diferenciados';

-- ============================================================
-- 4. ESTUDIANTES 
-- ============================================================
CREATE TABLE estudiantes (
    id_estudiante     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT UNSIGNED NOT NULL UNIQUE,
    id_semestre       INT UNSIGNED NOT NULL,
    fecha_nacimiento  DATE,
    sexo              ENUM('M','F','Otro'),
    domicilio         VARCHAR(200),
    curp              VARCHAR(18)  UNIQUE,
    foto_url          VARCHAR(255),
    fecha_inscripcion DATE         NOT NULL,
    status            ENUM('activo','baja_temporal','baja_definitiva','egresado') NOT NULL DEFAULT 'activo',
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_est_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuarios(id_usuario)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_est_semestre  FOREIGN KEY (id_semestre)  REFERENCES semestres(id_semestre) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Perfil extendido del estudiante';

-- ============================================================
-- 5. RELACIÓN PADRE ↔ ESTUDIANTE
-- ============================================================
CREATE TABLE padres_estudiantes (
    id_relacion       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_padre          INT UNSIGNED NOT NULL COMMENT 'usuarios.rol = padre',
    id_estudiante     INT UNSIGNED NOT NULL,
    parentesco        ENUM('Padre','Madre','Tutor','Otro') NOT NULL DEFAULT 'Tutor',
    es_contacto_principal TINYINT(1) NOT NULL DEFAULT 0,
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pe_padre      FOREIGN KEY (id_padre)      REFERENCES usuarios(id_usuario)     ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pe_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_padre_estudiante (id_padre, id_estudiante)
) COMMENT='Relación muchos-a-muchos entre padres/tutores y estudiantes';

-- ============================================================
-- 6. DOCENTES  
-- ============================================================
CREATE TABLE docentes (
    id_docente        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT UNSIGNED NOT NULL UNIQUE,
    especialidad      VARCHAR(100),
    tipo_contrato     ENUM('Tiempo completo','Medio tiempo','Por horas') NOT NULL DEFAULT 'Por horas',
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_doc_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Perfil extendido del docente';

-- ============================================================
-- 7. MATERIAS / MÓDULOS
-- ============================================================
CREATE TABLE materias (
    id_materia        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(150) NOT NULL,
    clave_materia     VARCHAR(20)  NOT NULL UNIQUE,
    creditos          TINYINT UNSIGNED NOT NULL DEFAULT 0,
    id_carrera        INT UNSIGNED NOT NULL,
    semestre_sugerido TINYINT UNSIGNED COMMENT 'Semestre en que se imparte normalmente',
    activa            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mat_carrera FOREIGN KEY (id_carrera) REFERENCES carreras(id_carrera) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Módulos/materias del plan de estudios';

-- ============================================================
-- 8. GRUPOS DE CLASE 
-- ============================================================
CREATE TABLE grupos_clase (
    id_grupo          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_materia        INT UNSIGNED NOT NULL,
    id_semestre       INT UNSIGNED NOT NULL,
    id_docente        INT UNSIGNED NOT NULL,
    ciclo_escolar     VARCHAR(20)  NOT NULL,
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_gc_materia   FOREIGN KEY (id_materia)  REFERENCES materias(id_materia)     ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_gc_semestre  FOREIGN KEY (id_semestre) REFERENCES semestres(id_semestre)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_gc_docente   FOREIGN KEY (id_docente)  REFERENCES docentes(id_docente)     ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_grupo (id_materia, id_semestre, ciclo_escolar)
) COMMENT='Asignación docente-materia-grupo por ciclo';

-- ============================================================
-- 9. PARCIALES
-- ============================================================
CREATE TABLE parciales (
    id_parcial        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero_parcial    TINYINT UNSIGNED NOT NULL COMMENT '1, 2 o 3',
    id_grupo          INT UNSIGNED NOT NULL,
    fecha_inicio      DATE,
    fecha_fin         DATE,
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_par_grupo FOREIGN KEY (id_grupo) REFERENCES grupos_clase(id_grupo) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_parcial_grupo (numero_parcial, id_grupo)
) COMMENT='Periodos de evaluación parcial por grupo';

-- ============================================================
-- 10. CALIFICACIONES
-- ============================================================
CREATE TABLE calificaciones (
    id_calificacion   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_estudiante     INT UNSIGNED NOT NULL,
    id_parcial        INT UNSIGNED NOT NULL,
    calificacion      DECIMAL(5,2) NOT NULL COMMENT '0.00 – 10.00',
    calificacion_tipo ENUM('parcial','extraordinario','recursamiento') NOT NULL DEFAULT 'parcial',
    observacion       VARCHAR(255),
    registrado_por    INT UNSIGNED NOT NULL COMMENT 'id_usuario del docente',
    fecha_registro    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cal_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cal_parcial    FOREIGN KEY (id_parcial)    REFERENCES parciales(id_parcial)       ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cal_docente    FOREIGN KEY (registrado_por) REFERENCES usuarios(id_usuario)       ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_cal (id_estudiante, id_parcial, calificacion_tipo),
    CONSTRAINT chk_calificacion CHECK (calificacion >= 0 AND calificacion <= 10)
) COMMENT='Calificaciones por parcial y estudiante';

-- ============================================================
-- 11. ASISTENCIAS
-- ============================================================
CREATE TABLE asistencias (
    id_asistencia     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_estudiante     INT UNSIGNED NOT NULL,
    id_grupo          INT UNSIGNED NOT NULL,
    fecha             DATE         NOT NULL,
    status            ENUM('presente','ausente','justificada','retardo') NOT NULL DEFAULT 'presente',
    justificacion     VARCHAR(255),
    registrado_por    INT UNSIGNED NOT NULL COMMENT 'id_usuario del docente',
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_asi_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_asi_grupo      FOREIGN KEY (id_grupo)      REFERENCES grupos_clase(id_grupo)     ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_asi_docente    FOREIGN KEY (registrado_por) REFERENCES usuarios(id_usuario)      ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_asistencia (id_estudiante, id_grupo, fecha),
    INDEX idx_fecha (fecha),
    INDEX idx_status (status)
) COMMENT='Registro diario de asistencia por estudiante y grupo';

-- ============================================================
-- 12. OBSERVACIONES DOCENTES
-- ============================================================
CREATE TABLE observaciones (
    id_observacion    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_estudiante     INT UNSIGNED NOT NULL,
    id_docente        INT UNSIGNED NOT NULL,
    id_grupo          INT UNSIGNED,
    tipo              ENUM('conducta','academica','social','asistencia','otro') NOT NULL DEFAULT 'academica',
    descripcion       TEXT         NOT NULL,
    es_positiva       TINYINT(1)   NOT NULL DEFAULT 0,
    fecha             DATE         NOT NULL,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_obs_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_obs_docente    FOREIGN KEY (id_docente)    REFERENCES docentes(id_docente)        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_obs_grupo      FOREIGN KEY (id_grupo)      REFERENCES grupos_clase(id_grupo)      ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_tipo (tipo),
    INDEX idx_fecha_obs (fecha)
) COMMENT='Observaciones y notas del docente sobre el estudiante';

-- ============================================================
-- 13. INDICADORES DE RIESGO 
-- ============================================================
CREATE TABLE indicadores_riesgo (
    id_indicador      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_estudiante     INT UNSIGNED NOT NULL,
    ciclo_escolar     VARCHAR(20)  NOT NULL,
    nivel_riesgo      ENUM('bajo','medio','alto','critico') NOT NULL DEFAULT 'bajo',
    pct_asistencia    DECIMAL(5,2) COMMENT 'Porcentaje de asistencia acumulado',
    promedio_general  DECIMAL(5,2) COMMENT 'Promedio general de calificaciones',
    materias_reprobadas TINYINT UNSIGNED NOT NULL DEFAULT 0,
    faltas_acumuladas INT UNSIGNED NOT NULL DEFAULT 0,
    observaciones_negativas INT UNSIGNED NOT NULL DEFAULT 0,
    calculado_en      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ir_estudiante FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_riesgo (id_estudiante, ciclo_escolar),
    INDEX idx_nivel_riesgo (nivel_riesgo)
) COMMENT='Indicador consolidado de riesgo de deserción por estudiante y ciclo';

-- ============================================================
-- 14. ALERTAS
-- ============================================================
CREATE TABLE alertas (
    id_alerta         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_estudiante     INT UNSIGNED NOT NULL,
    tipo_alerta       ENUM('bajo_rendimiento','inasistencia','conducta','riesgo_desercion','general') NOT NULL,
    descripcion       TEXT         NOT NULL,
    nivel             ENUM('informativa','advertencia','urgente') NOT NULL DEFAULT 'informativa',
    generada_por      ENUM('sistema','docente','administrativo') NOT NULL DEFAULT 'sistema',
    id_usuario_origen INT UNSIGNED COMMENT 'NULL si fue generada automáticamente',
    leida_docente     TINYINT(1)   NOT NULL DEFAULT 0,
    leida_admin       TINYINT(1)   NOT NULL DEFAULT 0,
    leida_padre       TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_alerta      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_al_estudiante FOREIGN KEY (id_estudiante)    REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_al_origen     FOREIGN KEY (id_usuario_origen) REFERENCES usuarios(id_usuario)      ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_tipo_alerta (tipo_alerta),
    INDEX idx_nivel_alerta (nivel),
    INDEX idx_fecha_alerta (fecha_alerta)
) COMMENT='Alertas generadas manual o automáticamente sobre un estudiante';

-- ============================================================
-- 15. NOTIFICACIONES  
-- ============================================================
CREATE TABLE notificaciones (
    id_notificacion   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_alerta         INT UNSIGNED NOT NULL,
    id_usuario_dest   INT UNSIGNED NOT NULL,
    canal             ENUM('app','correo','sms') NOT NULL DEFAULT 'app',
    leida             TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_envio       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_lectura     DATETIME,
    CONSTRAINT fk_noti_alerta   FOREIGN KEY (id_alerta)       REFERENCES alertas(id_alerta)     ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_noti_usuario  FOREIGN KEY (id_usuario_dest) REFERENCES usuarios(id_usuario)   ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_leida (leida),
    INDEX idx_dest (id_usuario_dest)
) COMMENT='Notificaciones enviadas a usuarios derivadas de alertas';

-- ============================================================
-- 16. CANALIZACIONES  
-- ============================================================
CREATE TABLE canalizaciones (
    id_canalizacion   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_estudiante     INT UNSIGNED NOT NULL,
    id_docente_origen INT UNSIGNED NOT NULL,
    id_admin_asignado INT UNSIGNED,
    motivo            TEXT         NOT NULL,
    tipo              ENUM('academico','psicologico','social','economico','otro') NOT NULL DEFAULT 'academico',
    status            ENUM('pendiente','en_proceso','atendida','cerrada') NOT NULL DEFAULT 'pendiente',
    fecha_canaliza    DATE         NOT NULL,
    fecha_atencion    DATE,
    seguimiento       TEXT,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_can_estudiante FOREIGN KEY (id_estudiante)     REFERENCES estudiantes(id_estudiante) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_can_docente    FOREIGN KEY (id_docente_origen) REFERENCES docentes(id_docente)       ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_can_admin      FOREIGN KEY (id_admin_asignado) REFERENCES usuarios(id_usuario)       ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_status_can (status)
) COMMENT='Reportes formales de canalización académica (proceso institucional)';

-- ============================================================
-- 17. AVISOS / COMUNICADOS INSTITUCIONALES
-- ============================================================
CREATE TABLE avisos (
    id_aviso          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    titulo            VARCHAR(200) NOT NULL,
    contenido         TEXT         NOT NULL,
    tipo              ENUM('general','academico','administrativo','evento') NOT NULL DEFAULT 'general',
    dirigido_a        ENUM('todos','estudiantes','padres','docentes','administrativos') NOT NULL DEFAULT 'todos',
    id_semestre       INT UNSIGNED COMMENT 'NULL = aplica a todos los semestres',
    publicado_por     INT UNSIGNED NOT NULL,
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    fecha_publicacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion  DATE,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_av_semestre  FOREIGN KEY (id_semestre)  REFERENCES semestres(id_semestre) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_av_publicado FOREIGN KEY (publicado_por) REFERENCES usuarios(id_usuario)  ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_dirigido (dirigido_a),
    INDEX idx_fecha_pub (fecha_publicacion)
) COMMENT='Avisos y comunicados institucionales';

-- ============================================================
-- 18. AVISOS LEÍDOS
-- ============================================================
CREATE TABLE avisos_leidos (
    id_av_leido       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_aviso          INT UNSIGNED NOT NULL,
    id_usuario        INT UNSIGNED NOT NULL,
    fecha_lectura     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_avl_aviso   FOREIGN KEY (id_aviso)   REFERENCES avisos(id_aviso)       ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_avl_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)   ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uq_aviso_usuario (id_aviso, id_usuario)
) COMMENT='Registro de avisos leídos por cada usuario';

-- ============================================================
-- 19. SESIONES / TOKENS 
-- ============================================================
CREATE TABLE sesiones (
    id_sesion         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT UNSIGNED NOT NULL,
    token_hash        VARCHAR(255) NOT NULL UNIQUE,
    dispositivo       VARCHAR(100),
    ip_address        VARCHAR(45),
    expira_en         DATETIME     NOT NULL,
    activa            TINYINT(1)   NOT NULL DEFAULT 1,
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ses_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_token (token_hash),
    INDEX idx_expira (expira_en)
) COMMENT='Gestión de sesiones y tokens de autenticación';

-- ============================================================
-- 20. AUDIT LOG 
-- ============================================================
CREATE TABLE audit_log (
    id_log            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario        INT UNSIGNED,
    accion            VARCHAR(80)  NOT NULL COMMENT 'Ej: CREATE_CALIFICACION, DELETE_USUARIO',
    tabla_afectada    VARCHAR(60),
    registro_id       INT UNSIGNED COMMENT 'PK del registro modificado',
    detalle           JSON,
    ip_address        VARCHAR(45),
    created_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_accion (accion),
    INDEX idx_tabla (tabla_afectada),
    INDEX idx_fecha_log (created_at)
) COMMENT='Registro de auditoría para acciones sensibles del sistema';

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

-- Vista: resumen de riesgo de estudiantes con datos de contacto
CREATE OR REPLACE VIEW vista_riesgo_estudiantes AS
SELECT
    e.id_estudiante,
    CONCAT(u.nombre, ' ', u.apellido_paterno, ' ', COALESCE(u.apellido_materno,'')) AS nombre_completo,
    u.matricula,
    u.correo,
    u.telefono,
    c.nombre          AS carrera,
    s.numero          AS semestre,
    s.turno,
    ir.nivel_riesgo,
    ir.pct_asistencia,
    ir.promedio_general,
    ir.materias_reprobadas,
    ir.faltas_acumuladas,
    ir.calculado_en
FROM estudiantes e
JOIN usuarios u         ON u.id_usuario   = e.id_usuario
JOIN semestres s        ON s.id_semestre  = e.id_semestre
JOIN carreras  c        ON c.id_carrera   = s.id_carrera
LEFT JOIN indicadores_riesgo ir ON ir.id_estudiante = e.id_estudiante
WHERE e.status = 'activo';

-- Vista: promedio general por estudiante y ciclo
CREATE OR REPLACE VIEW vista_promedios AS
SELECT
    e.id_estudiante,
    CONCAT(u.nombre, ' ', u.apellido_paterno) AS nombre_completo,
    u.matricula,
    par.id_grupo,
    m.nombre          AS materia,
    gc.ciclo_escolar,
    ROUND(AVG(cal.calificacion), 2) AS promedio_materia
FROM calificaciones cal
JOIN estudiantes e  ON e.id_estudiante = cal.id_estudiante
JOIN usuarios    u  ON u.id_usuario    = e.id_usuario
JOIN parciales   par ON par.id_parcial = cal.id_parcial
JOIN grupos_clase gc ON gc.id_grupo   = par.id_grupo
JOIN materias    m  ON m.id_materia   = gc.id_materia
WHERE cal.calificacion_tipo = 'parcial'
GROUP BY e.id_estudiante, par.id_grupo, gc.ciclo_escolar;

-- Vista: porcentaje de asistencia por estudiante y grupo
CREATE OR REPLACE VIEW vista_asistencias_resumen AS
SELECT
    e.id_estudiante,
    CONCAT(u.nombre, ' ', u.apellido_paterno) AS nombre_completo,
    u.matricula,
    a.id_grupo,
    m.nombre          AS materia,
    COUNT(*)          AS total_clases,
    SUM(a.status = 'presente')    AS presentes,
    SUM(a.status = 'ausente')     AS ausentes,
    SUM(a.status = 'justificada') AS justificadas,
    SUM(a.status = 'retardo')     AS retardos,
    ROUND(
        (SUM(a.status = 'presente') + SUM(a.status = 'justificada')) * 100.0 / COUNT(*), 2
    ) AS pct_asistencia
FROM asistencias a
JOIN estudiantes  e  ON e.id_estudiante = a.id_estudiante
JOIN usuarios     u  ON u.id_usuario    = e.id_usuario
JOIN grupos_clase gc ON gc.id_grupo     = a.id_grupo
JOIN materias     m  ON m.id_materia    = gc.id_materia
GROUP BY e.id_estudiante, a.id_grupo;

-- ============================================================
-- DATOS DE EJEMPLO — INSERCIÓN INICIAL
-- ============================================================

-- Carreras
INSERT INTO carreras (nombre, clave) VALUES
('Mantenimiento Automotriz',               'MA'),
('Sistemas de Manufactura Textil',         'SMT'),
('Tecnologías de la Información',          'TI'),
('Técnico en Administración',              'ADM');

-- Semestres (ciclo 2025-2026, Mantenimiento Automotriz)
INSERT INTO semestres (numero, turno, ciclo_escolar, id_carrera) VALUES
(2, 'Matutino', '2025-2026', 1),
(4, 'Matutino', '2025-2026', 1),
(6, 'Matutino', '2025-2026', 1);

-- Usuarios base (contraseñas en texto plano sólo como ejemplo — usar bcrypt en producción)
INSERT INTO usuarios (matricula, nombre, apellido_paterno, apellido_materno, correo, password_hash, rol, telefono) VALUES
-- Administrativo
('ADM001', 'Miriam',   'Lopez',    'Morales',  'miriam.lopez@cecyteh.edu.mx',   '$2b$12$ejemploHash1', 'administrativo', '7751000001'),
-- Docente
('DOC001', 'Martin',   'Vargas',   'Ordoña',   'martin.vargas@cecyteh.edu.mx',  '$2b$12$ejemploHash2', 'docente',        '7751000002'),
-- Padres
(NULL,     'Josefina', 'Rosales',  'Barragan', 'josefina.rosales@correo.com',   '$2b$12$ejemploHash3', 'padre',          '7751000003'),
-- Estudiantes
('S220001','Noel',     'Lopez',    'Ramirez',  'noel.lopez@cecyteh.edu.mx',     '$2b$12$ejemploHash4', 'estudiante',     '7751000004'),
('S220002','Leonardo', 'Reyes',    'Dominguez','leonardo.reyes@cecyteh.edu.mx', '$2b$12$ejemploHash5', 'estudiante',     '7751000005'),
('S220003','Diego',    'Arista',   NULL,       'diego.arista@cecyteh.edu.mx',   '$2b$12$ejemploHash6', 'estudiante',     '7751000006'),
('S220004','Diego',    'Rodriguez','Alvarez',  'diego.rodriguez@cecyteh.edu.mx','$2b$12$ejemploHash7', 'estudiante',     '7751000007'),
('S220005','Kevin',    'Santos',   'Vargas',   'kevin.santos@cecyteh.edu.mx',   '$2b$12$ejemploHash8', 'estudiante',     '7751000008');

-- Perfil extendido docente
INSERT INTO docentes (id_usuario, especialidad, tipo_contrato) VALUES
(2, 'Mantenimiento Automotriz', 'Tiempo completo');

-- Perfil extendido estudiantes
INSERT INTO estudiantes (id_usuario, id_semestre, fecha_inscripcion, status) VALUES
(4, 3, '2025-08-01', 'activo'),   -- Noel  → 6to
(5, 3, '2025-08-01', 'activo'),   -- Leonardo → 6to (SMT, pero asignado al grupo MA por ejemplo)
(6, 1, '2025-08-01', 'activo'),   -- Diego Arista → 2do
(7, 3, '2025-08-01', 'activo'),   -- Diego Rodriguez → 6to
(8, 3, '2025-08-01', 'activo');   -- Kevin → 6to

-- Relación padre ↔ estudiante
INSERT INTO padres_estudiantes (id_padre, id_estudiante, parentesco, es_contacto_principal) VALUES
(3, 4, 'Madre', 1);  -- Josefina → Noel

-- Materia de ejemplo
INSERT INTO materias (nombre, clave_materia, creditos, id_carrera, semestre_sugerido) VALUES
('Motor y Sus Sistemas',             'MA-MOT',  8, 1, 2),
('Sistemas de Frenos',               'MA-FRE',  8, 1, 4),
('Sistemas Electrónicos del Automóvil','MA-ELE',8, 1, 6),
('Diagnóstico Automotriz',           'MA-DIA',  8, 1, 6);

-- Grupo de clase
INSERT INTO grupos_clase (id_materia, id_semestre, id_docente, ciclo_escolar) VALUES
(3, 3, 1, '2025-2026'),   -- Sistemas Electrónicos → 6to → Martín
(4, 3, 1, '2025-2026');   -- Diagnóstico Automotriz → 6to → Martín

-- Parciales
INSERT INTO parciales (numero_parcial, id_grupo, fecha_inicio, fecha_fin) VALUES
(1, 1, '2025-08-25', '2025-10-10'),
(2, 1, '2025-10-13', '2025-11-28'),
(1, 2, '2025-08-25', '2025-10-10');

-- Calificaciones de ejemplo
INSERT INTO calificaciones (id_estudiante, id_parcial, calificacion, registrado_por) VALUES
(1, 1, 8.5, 2),
(1, 2, 7.0, 2),
(3, 1, 9.0, 2),
(4, 1, 6.5, 2),
(5, 1, 5.0, 2);   -- Kevin en riesgo (calificación baja)

-- Asistencias de ejemplo
INSERT INTO asistencias (id_estudiante, id_grupo, fecha, status, registrado_por) VALUES
(1, 1, '2025-09-01', 'presente',  2),
(1, 1, '2025-09-02', 'ausente',   2),
(5, 1, '2025-09-01', 'ausente',   2),
(5, 1, '2025-09-02', 'ausente',   2),
(5, 1, '2025-09-03', 'ausente',   2);

-- Indicador de riesgo inicial (calculado manualmente al momento de sembrar)
INSERT INTO indicadores_riesgo (id_estudiante, ciclo_escolar, nivel_riesgo, pct_asistencia, promedio_general, materias_reprobadas, faltas_acumuladas) VALUES
(5, '2025-2026', 'critico', 0.00, 5.0, 1, 3);

-- Alerta automática de ejemplo
INSERT INTO alertas (id_estudiante, tipo_alerta, descripcion, nivel, generada_por) VALUES
(5, 'riesgo_desercion',
 'El alumno Kevin Santos Vargas presenta calificación menor a 6 y 3 inasistencias consecutivas en el grupo de Sistemas Electrónicos.',
 'urgente', 'sistema');

-- Aviso institucional de ejemplo
INSERT INTO avisos (titulo, contenido, tipo, dirigido_a, publicado_por) VALUES
('Inicio de captura de calificaciones – Parcial 1',
 'Se comunica a los docentes que a partir del 10 de octubre está habilitada la captura de calificaciones del primer parcial en la plataforma.',
 'academico', 'docentes', 1);
