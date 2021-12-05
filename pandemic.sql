
CREATE TABLE Auditoria (ID bool, TABELA varchar(50) NOT NULL, USUARIO varchar(50) NOT NULL, DATA timestamp NOT NULL, OPERACAO varchar(1) NOT NULL, NEWREG text NOT NULL, OLDREG text NOT NULL);
COMMENT ON COLUMN Auditoria.OPERACAO IS 'I – INCLUSÃO, E – EXCLUSÃO, A - ALTERAÇÃO';
CREATE TABLE duvida (duvid SERIAL NOT NULL, duvper varchar(200) NOT NULL, duvres varchar(255) NOT NULL, codques int4, cpfpac int4, idusu int4, PRIMARY KEY (duvid));
CREATE TABLE Empresa (cnpemp SERIAL NOT NULL, nomemp varchar(40), emprua varchar(40) NOT NULL, empnum int4 NOT NULL, empfun int4 NOT NULL, PRIMARY KEY (cnpemp));
COMMENT ON COLUMN Empresa.empfun IS 'data da fundação';
CREATE TABLE Geolocalizacao (geocod int4 NOT NULL, idusu int4 NOT NULL, geoest varchar(25) NOT NULL, geocid varchar(30) NOT NULL, geobai varchar(50) NOT NULL, georua varchar(30) NOT NULL, geonum int4 NOT NULL, PRIMARY KEY (geocod, idusu));
COMMENT ON COLUMN Geolocalizacao.geoest IS 'Estado';
COMMENT ON COLUMN Geolocalizacao.geonum IS 'Numero';
CREATE TABLE Paciente (cpfpac int4 NOT NULL, idusu int4 NOT NULL, nompac varchar(40), naspac date NOT NULL, sexpac char(1) NOT NULL, cnpemp int4 NOT NULL, idapac int4 NOT NULL, PRIMARY KEY (cpfpac, idusu));
COMMENT ON COLUMN Paciente.idapac IS 'idade paciente';
CREATE TABLE Questionario (codques int4 NOT NULL, cpfpac int4 NOT NULL, idusu int4 NOT NULL, quealt int4 NOT NULL, quepes int4 NOT NULL, quecom varchar(255) NOT NULL, quesintmom varchar(100) NOT NULL, PRIMARY KEY (codques, cpfpac, idusu));
COMMENT ON COLUMN Questionario.quealt IS 'altura';
COMMENT ON COLUMN Questionario.quepes IS 'peso';
COMMENT ON COLUMN Questionario.quecom IS 'Historico de Comorbidades';
COMMENT ON COLUMN Questionario.quesintmom IS 'Sintomas do momento';
CREATE TABLE Registro (cpfpac int4 NOT NULL, idusu int4 NOT NULL, regcod int4 NOT NULL, estvoc int2 NOT NULL, regpas SERIAL NOT NULL, regdat date NOT NULL, PRIMARY KEY (regpas));
COMMENT ON TABLE Registro IS 'Tabela que informa se o paciente esta possitivado ou não';
COMMENT ON COLUMN Registro.regcod IS 'Resgistro de codigo do sintoma';
COMMENT ON COLUMN Registro.estvoc IS 'Estado covid (positivo ou não)';
COMMENT ON COLUMN Registro.regpas IS 'Resgistro paciente';
CREATE TABLE Sintoma (sincod SERIAL NOT NULL, cod1 int4, cod2 int4, cod3 int4, cod4 int4, cod5 int4, cod6 int4, cod7 int4, cod8 int4, cod9 int4, cod10 int4, cpfpac int4 NOT NULL, idusu int4 NOT NULL, regpas int4 NOT NULL, PRIMARY KEY (sincod));
COMMENT ON COLUMN Sintoma.cod1 IS 'Febre';
COMMENT ON COLUMN Sintoma.cod2 IS 'Tosse';
COMMENT ON COLUMN Sintoma.cod3 IS 'Falta de ar';
COMMENT ON COLUMN Sintoma.cod4 IS 'Dor no corpo';
COMMENT ON COLUMN Sintoma.cod5 IS 'Dor na garganta';
COMMENT ON COLUMN Sintoma.cod6 IS 'Dor muscular';
COMMENT ON COLUMN Sintoma.cod7 IS 'Calafrios';
COMMENT ON COLUMN Sintoma.cod8 IS 'Congestão nazal';
COMMENT ON COLUMN Sintoma.cod9 IS 'Corriza';
COMMENT ON COLUMN Sintoma.cod10 IS 'Vomito';
CREATE TABLE Usuario (idusu SERIAL NOT NULL, cnpemp int4 NOT NULL, tipusu varchar(20) NOT NULL, PRIMARY KEY (idusu));
COMMENT ON COLUMN Usuario.tipusu IS 'Tipo usuario';
ALTER TABLE Sintoma ADD CONSTRAINT FKSintoma429670 FOREIGN KEY (regpas) REFERENCES Registro (regpas);
ALTER TABLE Registro ADD CONSTRAINT FKRegistro126405 FOREIGN KEY (cpfpac, idusu) REFERENCES Paciente (cpfpac, idusu);
ALTER TABLE duvida ADD CONSTRAINT FKduvida411843 FOREIGN KEY (codques, cpfpac, idusu) REFERENCES Questionario (codques, cpfpac, idusu);
ALTER TABLE Paciente ADD CONSTRAINT FKPaciente771264 FOREIGN KEY (cnpemp) REFERENCES Empresa (cnpemp);
ALTER TABLE Geolocalizacao ADD CONSTRAINT FKGeolocaliz606154 FOREIGN KEY (idusu) REFERENCES Usuario (idusu);
ALTER TABLE Questionario ADD CONSTRAINT FKQuestionar681933 FOREIGN KEY (cpfpac, idusu) REFERENCES Paciente (cpfpac, idusu);
ALTER TABLE Usuario ADD CONSTRAINT FKUsuario753141 FOREIGN KEY (cnpemp) REFERENCES Empresa (cnpemp);
ALTER TABLE Paciente ADD CONSTRAINT FKPaciente239550 FOREIGN KEY (idusu) REFERENCES Usuario (idusu);

--RELATORIOS
--1
select paciente.idusu, paciente.nompac from paciente
inner join sintoma on paciente.idusu = sintoma.idusu 
where paciente.idapac >= 40 and paciente.idapac <= 60 and sintoma.cod10 is not null
order by paciente.idusu ASC -- ordem ascendente 

--2
select paciente.nompac, geolocalizacao.geocid from paciente 
inner join usuario on paciente.idusu = usuario.idusu 
inner join geolocalizacao on usuario.idusu = geolocalizacao.idusu
inner join registro on registro.idusu = paciente.idusu 
inner join sintoma on paciente.idusu = sintoma.idusu 
where geolocalizacao.geocid in ('Maravilha', 'Descanso', 'Pinhalzinho','
Chapecó', 'Itapiranga ') and sexpac = 'F' and registro.estvoc = 2
order by geolocalizacao.geocid desc, paciente.nompac asc

-- 3.
select geolocalizacao.geocod, count(registro.estvoc) from geolocalizacao 
inner join usuario on usuario.idusu = geolocalizacao.idusu 
inner join paciente on paciente.idusu = usuario.idusu 
inner join registro on registro.idusu = paciente.idusu 
group by geolocalizacao.geocod 
order by count(registro.estvoc) ASC;

--4.
select count(paciente.cpfpac), paciente.idapac from paciente 
inner join registro on registro.idusu = paciente.idusu and registro.estvoc = 1 -- positivo se for igual a 1  
where registro.regdat between '2020-07-01' and '2020-02-03'
group by paciente.idapac order by count(paciente.cpfpac) desc;


--Novo BD 2

--criação das procedure
CREATE OR REPLACE FUNCTION ft_auditoria() RETURNS TRIGGER AS
$body$
BEGIN
-- Cria uma linha na tabela AUDITORIA para refletir a operação
 -- realizada na tabela que invoca a trigger. --
 IF (TG_OP = 'DELETE') THEN
 INSERT INTO auditoria(tabela, usuario, data, operacao,oldreg) SELECT
TG_RELNAME, user, current_timestamp, 'E', OLD::text;
 RETURN OLD;
 ELSIF (TG_OP = 'UPDATE') THEN
 INSERT INTO auditoria(tabela, usuario, data, operacao,newreg,oldreg)
SELECT TG_RELNAME, user, current_timestamp, 'A',NEW::text,OLD::text;
 RETURN NEW;
 ELSIF (TG_OP = 'INSERT') THEN
 INSERT INTO auditoria(tabela, usuario, data, operacao,newreg)
SELECT TG_RELNAME, user, current_timestamp, 'I',NEW::text;
 RETURN NEW;
 END IF;
 RETURN NULL; -- o resultado é ignorado uma vez que este é um gatilho AFTER END;
 $body$
 LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ft_createuser(codigo number) RETURNS TRIGGER AS
$body$
BEGIN
 IF (TG_OP = 'DELETE') THEN
 DROP TABLE USUARIO WHERE usuario.idusu = codigo;
 END IF;
 RETURN NULL; 
 $body$
 LANGUAGE plpgsql;


--trigger
CREATE TRIGGER Questionario_audit AFTER INSERT OR UPDATE OR DELETE ON Questionario FOR EACH
ROW EXECUTE PROCEDURE ft_auditoria();

CREATE TRIGGER CREATEuser_trigger AFTER DELETE ON Paciente FOR EACH
ROW EXECUTE PROCEDURE ft_createuser(codigo);

--4
CREATE USER ALUNO WITH PASSWORD '123456';
CREATE GROUP pessoa;
GRANT SELECT, INSERT, DELETE, UPDATE ON pessoa TO ALUNO;

--7
pg_dump pandemic

pg_restore -d pandemic 'Colocar caminho do arquivo';





































