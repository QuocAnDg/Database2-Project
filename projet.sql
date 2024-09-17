DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

CREATE TABLE projet.cours (
    code_cours CHARACTER(8) PRIMARY KEY CHECK (code_cours SIMILAR TO('BINV[0-9]{4}')),
    nom VARCHAR(100) NOT NULL CHECK (nom <> ''),
    bloc INTEGER NOT NULL CHECK (bloc <= 3 AND bloc >= 1),
    nb_credits INTEGER NOT NULL CHECK (nb_credits > 0 AND nb_credits <= 60)
);

CREATE TABLE projet.etudiants(
    id_etudiant SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL CHECK (nom <> ''),
    prenom VARCHAR(100) NOT NULL CHECK (prenom <> ''),
    email VARCHAR(100) UNIQUE NOT NULL CHECK (email LIKE '%@student.vinci.be'),
    mot_de_passe VARCHAR(255) NOT NULL CHECK (mot_de_passe <> '') DEFAULT '$2a$10$NgNECjd5YF1JpPYoYuXb9OMPdm3gYXU1Ej0mFYK3SXY9loS4AepMm' /*mdp temporaire = a*/
);

CREATE TABLE projet.projets(
    id_projet VARCHAR(100) PRIMARY KEY CHECK (id_projet <> ''),
    nom VARCHAR(255) NOT NULL CHECK (nom <> ''),
    code_cours CHARACTER(8) REFERENCES projet.cours(code_cours),
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL CHECK (date_fin > date_debut)
);

CREATE TABLE projet.groupes(
    id_projet VARCHAR(100) REFERENCES projet.projets(id_projet),
    numero_groupe SERIAL CHECK (numero_groupe > 0),
    PRIMARY KEY (id_projet, numero_groupe),
    nb_places INTEGER NOT NULL CHECK (nb_places > 0),
    nb_etudiants_inscrits INTEGER NOT NULL CHECK (nb_etudiants_inscrits >= 0 AND nb_etudiants_inscrits <= groupes.nb_places) DEFAULT 0,
    valide BOOL NOT NULL DEFAULT false
);

CREATE TABLE projet.inscriptions_cours(
    code_cours CHARACTER(8) REFERENCES projet.cours(code_cours),
    id_etudiant INTEGER REFERENCES projet.etudiants(id_etudiant),
    PRIMARY KEY (code_cours, id_etudiant)
);

CREATE TABLE projet.inscriptions_groupes(
    id_etudiant INTEGER REFERENCES projet.etudiants(id_etudiant),
    id_projet VARCHAR(100),
    PRIMARY KEY (id_etudiant, id_projet),
    numero_groupe INTEGER,
    FOREIGN KEY (id_projet, numero_groupe) REFERENCES projet.groupes (id_projet, numero_groupe)
);
/*******************************************************APPLICATION CENTRALE******************************************************/
/*1*/
CREATE OR REPLACE FUNCTION projet.ajouter_cours(_code_cours VARCHAR(100), _nom VARCHAR(100), _bloc INTEGER, _nb_credits INTEGER) RETURNS VOID AS $$
    BEGIN
        INSERT INTO projet.cours(code_cours, nom, bloc, nb_credits)
        VALUES (_code_cours, _nom, _bloc, _nb_credits);
    END;
$$ LANGUAGE plpgsql;

/*2*/
CREATE OR REPLACE FUNCTION projet.ajouter_etudiant(_nom VARCHAR(100), _prenom VARCHAR(100), _email VARCHAR(100), _mot_de_passe VARCHAR(255)) RETURNS VOID AS $$
    BEGIN
        INSERT INTO projet.etudiants
            VALUES (DEFAULT, _nom, _prenom, _email, _mot_de_passe);
    END;
$$ LANGUAGE plpgsql;
/*4*/
CREATE OR REPLACE FUNCTION projet.creer_projet(_id_projet VARCHAR(100), _nom VARCHAR(100), _code_cours VARCHAR(100), _date_debut DATE, _date_fin DATE) RETURNS VOID AS $$
    BEGIN
        INSERT INTO projet.projets(id_projet, nom, code_cours, date_debut, date_fin)
        VALUES (_id_projet, _nom, _code_cours, _date_debut, _date_fin);
    END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION projet.determination_numero_groupe() RETURNS TRIGGER AS $$
    DECLARE
        nouveau_numero_groupe INTEGER;
    BEGIN
        SELECT COUNT(*) FROM projet.groupes WHERE id_projet = NEW.id_projet
            INTO nouveau_numero_groupe;
        UPDATE projet.groupes SET numero_groupe = nouveau_numero_groupe
            WHERE numero_groupe = NEW.numero_groupe AND id_projet = NEW.id_projet;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER numero_groupe_trigger AFTER INSERT ON projet.groupes FOR EACH ROW
    EXECUTE PROCEDURE projet.determination_numero_groupe();

CREATE OR REPLACE FUNCTION projet.groupe_validable() RETURNS TRIGGER AS $$
    BEGIN
        IF NOT OLD.valide AND NEW.valide THEN
            IF NEW.nb_etudiants_inscrits < NEW.nb_places THEN
                RAISE 'Le groupe n''est pas complet.';
            END IF;
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER groupe_validable_trigger BEFORE UPDATE ON projet.groupes FOR EACH ROW
    EXECUTE PROCEDURE projet.groupe_validable();


CREATE OR REPLACE FUNCTION projet.incrementer_nombre_inscrits_groupe() RETURNS TRIGGER AS $$
    BEGIN
        UPDATE projet.groupes SET nb_etudiants_inscrits = nb_etudiants_inscrits + 1
            WHERE numero_groupe = NEW.numero_groupe AND id_projet = NEW.id_projet;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER incrementer_nombre_inscrits_groupe_trigger AFTER INSERT ON projet.inscriptions_groupes FOR EACH ROW
    EXECUTE PROCEDURE projet.incrementer_nombre_inscrits_groupe();

/*3*/
CREATE OR REPLACE FUNCTION projet.verification_inscription_cours() RETURNS TRIGGER AS $$
    BEGIN
        IF (SELECT COUNT(*) FROM projet.projets WHERE code_cours = NEW.code_cours) > 0 THEN
            RAISE 'Les inscriptions pour ce cours sont fermées.';
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verification_inscription_groupe BEFORE INSERT ON projet.inscriptions_cours FOR EACH ROW
    EXECUTE PROCEDURE projet.verification_inscription_cours();

CREATE OR REPLACE FUNCTION projet.inscrire_etudiant_au_cours(email_etudiant VARCHAR(100), code_cours_a_inscrire CHARACTER(8)) RETURNS VOID AS $$
    DECLARE
        id_etudiant_a_inscrire INTEGER;
    BEGIN
        SELECT id_etudiant FROM projet.etudiants WHERE email = email_etudiant
             INTO id_etudiant_a_inscrire;
        INSERT INTO projet.inscriptions_cours VALUES (code_cours_a_inscrire, id_etudiant_a_inscrire);
    END;
$$ LANGUAGE plpgsql;

/*5*/
CREATE OR REPLACE FUNCTION verification_nb_etudiants_inscrits() RETURNS TRIGGER AS $$
    DECLARE
        nombre_etudiants_dans_groupe INTEGER;
        nombre_total_etudiants_inscrits INTEGER;
    BEGIN
        SELECT SUM(nb_places) FROM projet.groupes WHERE id_projet = NEW.id_projet
            INTO nombre_etudiants_dans_groupe;

        SELECT COUNT(*) FROM projet.inscriptions_cours ic, projet.projets p
            WHERE p.id_projet = NEW.id_projet
            AND p.code_cours = ic.code_cours
            GROUP BY p.code_cours
            INTO nombre_total_etudiants_inscrits;

        IF (NEW.nb_places > nombre_total_etudiants_inscrits - nombre_etudiants_dans_groupe) THEN
            RAISE 'Trop de places attribuées.';
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER creer_groupe_trigger BEFORE INSERT ON projet.groupes FOR EACH ROW
    EXECUTE PROCEDURE verification_nb_etudiants_inscrits();

CREATE OR REPLACE FUNCTION projet.creer_groupe(id_projet_assigne VARCHAR(100), nombre_groupes_a_creer INTEGER, nombre_places_a_creer INTEGER) RETURNS VOID AS $$
    BEGIN
        IF nombre_groupes_a_creer < 1 THEN
            RAISE 'Le nombre de groupes à créer doit être strictement positif.';
        END IF;

        FOR i IN 1..nombre_groupes_a_creer LOOP
            INSERT INTO projet.groupes(id_projet, nb_places) VALUES (id_projet_assigne, nombre_places_a_creer);
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

/*procedure pour 6*/
CREATE OR REPLACE FUNCTION projet.liste_projets_as_string(id_cours CHARACTER(8)) RETURNS VARCHAR(255) AS $$
    DECLARE
    string VARCHAR(255);
    projet_iteration RECORD;
    BEGIN
        IF (SELECT COUNT(*) FROM projet.projets p WHERE p.code_cours = id_cours) > 0 THEN
            string := '';
            FOR projet_iteration IN (SELECT * FROM projet.projets p WHERE p.code_cours = id_cours) LOOP
                string := CONCAT(string, projet_iteration.id_projet, ', ');
            END LOOP;
            string := "left"(string, "length"(string) - 2);
        END IF;
        RETURN COALESCE(string, 'Pas encore de projet');
    END;
$$ LANGUAGE plpgsql;

/*6*/
CREATE VIEW projet.visualiser_cours AS
    SELECT c.code_cours AS code_du_cours, c.nom AS nom_du_cours, projet.liste_projets_as_string(c.code_cours) AS identifiants_des_projets
    FROM projet.cours c;

/*7*/
CREATE VIEW projet.visualiser_projets AS
    SELECT p.id_projet, p.nom, p.code_cours, COUNT(g1.numero_groupe) AS "Nombre de groupes",
           COUNT(g2.numero_groupe) AS "Nombre de groupes complets",
           COUNT(g3.numero_groupe) AS "Nombre de groupes validés"
    FROM projet.projets p LEFT OUTER JOIN projet.groupes g1 on p.id_projet = g1.id_projet
        LEFT OUTER JOIN projet.groupes g2 on p.id_projet = g2.id_projet AND g1.numero_groupe = g2.numero_groupe AND g2.nb_etudiants_inscrits = g2.nb_places
        LEFT OUTER JOIN projet.groupes g3 on p.id_projet = g3.id_projet AND g2.numero_groupe = g3.numero_groupe AND g3.valide = true
    GROUP BY p.id_projet, p.nom, p.code_cours;

/*8*/
CREATE OR REPLACE FUNCTION projet.visualiser_composition_groupes(identifiant_projet VARCHAR(100))
    RETURNS TABLE(
                  "Numéro du groupe" INTEGER,
                  "Nom" VARCHAR(100),
                  "Prénom" VARCHAR(100),
                  "Complet ?" BOOLEAN,
                  "Validé ?" BOOLEAN
                 ) AS $$
    BEGIN
        RETURN QUERY
            SELECT g.numero_groupe, COALESCE(e.nom, 'null'), COALESCE(e.prenom, 'null'), (g.nb_places = g.nb_etudiants_inscrits), g.valide
            FROM projet.groupes g LEFT OUTER JOIN projet.inscriptions_groupes eg ON g.id_projet = eg.id_projet AND g.numero_groupe = eg.numero_groupe
                LEFT OUTER JOIN projet.etudiants e ON e.id_etudiant = eg.id_etudiant
            WHERE g.id_projet = identifiant_projet
            ORDER BY g.numero_groupe;
    END;
$$ LANGUAGE plpgsql;

/*9*/
CREATE OR REPLACE FUNCTION projet.valider_groupe(identifiant_projet VARCHAR(100), identifiant_groupe INTEGER) RETURNS VOID AS $$
    BEGIN
        IF (SELECT COUNT(*) FROM projet.groupes WHERE id_projet = identifiant_projet AND numero_groupe = identifiant_groupe) = 0 THEN
            RAISE 'Ce groupe n''existe pas.';
        END IF;

        UPDATE projet.groupes g SET valide = true
            WHERE identifiant_projet = id_projet AND identifiant_groupe = numero_groupe;
    END;
$$ LANGUAGE plpgsql;

/*10*/
CREATE OR REPLACE FUNCTION projet.valider_tous_groupes(identifiant_projet VARCHAR(100)) RETURNS VOID AS $$
    DECLARE
        groupe RECORD;
        void RECORD;
    BEGIN
        FOR groupe IN (SELECT * FROM projet.groupes WHERE id_projet = identifiant_projet) LOOP
            SELECT projet.valider_groupe(groupe.id_projet, groupe.numero_groupe)
                INTO void;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

/*******************************************************APPLICATION ETUDIANTE******************************************************/

/*1*/
CREATE VIEW projet.visualiser_cours_etudiant AS
    SELECT ic.id_etudiant, vc.code_du_cours, vc.nom_du_cours, vc.identifiants_des_projets
    FROM projet.inscriptions_cours ic LEFT OUTER JOIN projet.visualiser_cours vc ON vc.code_du_cours = ic.code_cours;
/*2*/
CREATE OR REPLACE FUNCTION projet.verification_ajout_etudiant_groupe() RETURNS TRIGGER AS $$
    DECLARE
        groupe RECORD;
    BEGIN
     SELECT * FROM projet.groupes
            WHERE id_projet = NEW.id_projet AND numero_groupe = NEW.numero_groupe
            INTO groupe;
        IF (NEW.id_etudiant NOT IN
            (SELECT ic.id_etudiant
            FROM projet.inscriptions_cours ic, projet.projets pr
            WHERE ic.code_cours = pr.code_cours AND NEW.id_projet = pr.id_projet)) THEN
                RAISE 'L''étudiant n''est pas inscrit au cours.';
        END IF;
        IF EXISTS(SELECT * FROM projet.inscriptions_groupes WHERE NEW.id_etudiant = id_etudiant AND NEW.id_projet = id_projet)
        THEN
            RAISE 'L''étudiant ne peut rejoindre qu''un seul groupe par projet.';
        END IF;

        IF groupe.nb_etudiants_inscrits = groupe.nb_places THEN
            RAISE 'Le groupe est complet';
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ajouter_etudiant_groupe_trigger BEFORE INSERT ON projet.inscriptions_groupes FOR EACH ROW
    EXECUTE PROCEDURE projet.verification_ajout_etudiant_groupe();

CREATE OR REPLACE FUNCTION projet.rajouter_etudiant_groupe(_id_etudiant INTEGER, _id_projet VARCHAR(100), _numero_groupe INTEGER) RETURNS VOID AS $$
    BEGIN
        INSERT INTO projet.inscriptions_groupes (id_etudiant, id_projet, numero_groupe) VALUES (_id_etudiant, _id_projet, _numero_groupe);
    END;
$$ LANGUAGE plpgsql;

/*3*/
CREATE OR REPLACE FUNCTION projet.retirer_etudiant_groupe() RETURNS TRIGGER AS $$
    BEGIN
        IF (SELECT gp.valide
            FROM projet.inscriptions_groupes ic, projet.groupes gp
            WHERE OLD.id_etudiant = ic.id_etudiant AND
                  ic.numero_groupe = gp.numero_groupe AND
                  gp.id_projet = OLD.id_projet)
                THEN RAISE 'Groupe déjà validé';
        END IF;

        UPDATE projet.groupes SET nb_etudiants_inscrits = nb_etudiants_inscrits - 1
            WHERE numero_groupe = OLD.numero_groupe AND id_projet = OLD.id_projet;

        RETURN OLD;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER retirer_etudiant_groupe_trigger BEFORE DELETE ON projet.inscriptions_groupes
    FOR EACH ROW EXECUTE PROCEDURE projet.retirer_etudiant_groupe();

CREATE OR REPLACE FUNCTION projet.retirer_etudiant_du_groupe(_id_etudiant INTEGER, _id_projet VARCHAR(100)) RETURNS VOID AS $$
    BEGIN
        IF NOT EXISTS(SELECT * FROM projet.inscriptions_groupes WHERE id_etudiant = _id_etudiant AND id_projet = _id_projet)
            THEN RAISE 'L''étudiant n''a pas encore de groupe pour ce projet.';
        END IF;
        DELETE FROM projet.inscriptions_groupes WHERE id_etudiant = _id_etudiant AND id_projet = _id_projet;
    END;
$$ LANGUAGE plpgsql;

/*4*/

CREATE OR REPLACE VIEW projet.visualiser_projets_etudiant AS
    SELECT pr.id_projet, pr.nom, pr.code_cours, ig.numero_groupe, ic.id_etudiant
    FROM projet.projets pr LEFT OUTER JOIN projet.inscriptions_cours ic ON pr.code_cours = ic.code_cours
        LEFT OUTER JOIN projet.inscriptions_groupes ig ON ig.id_etudiant = ic.id_etudiant AND pr.id_projet = ig.id_projet;

/*5*/
CREATE OR REPLACE VIEW projet.visualiser_projets_etudiant_sans_groupe AS
    SELECT pr.id_projet, pr.nom, pr.code_cours, pr.date_debut, pr.date_fin, ic.id_etudiant
    FROM projet.projets pr, projet.inscriptions_cours ic
    WHERE ic.code_cours = pr.code_cours AND
          ic.id_etudiant NOT IN (SELECT ig.id_etudiant FROM projet.inscriptions_groupes ig WHERE ig.id_projet = pr.id_projet);
/*6*/
CREATE OR REPLACE FUNCTION projet.visualiser_composition_groupes_incomplets(identifiant_projet VARCHAR)
    RETURNS TABLE(
                  "Numéro du groupe" INTEGER,
                  "Nom" VARCHAR(100),
                  "Prénom" VARCHAR(100),
                  "Nombre de places restantes" INTEGER
                 ) AS $$
    BEGIN
        RETURN QUERY
            SELECT g.numero_groupe, COALESCE(e.nom, 'null'), COALESCE(e.prenom, 'null'), (g.nb_places - g.nb_etudiants_inscrits) AS "Nombre de places restantes"
            FROM projet.groupes g LEFT OUTER JOIN projet.inscriptions_groupes eg on g.id_projet = eg.id_projet and g.numero_groupe = eg.numero_groupe
                LEFT OUTER JOIN projet.etudiants e on e.id_etudiant = eg.id_etudiant
            WHERE g.id_projet = identifiant_projet
            AND g.nb_etudiants_inscrits < g.nb_places
            ORDER BY g.numero_groupe;
    END;
$$ LANGUAGE plpgsql;

GRANT CONNECT ON DATABASE dbyounesbenbouchta TO quocduong;
GRANT USAGE ON SCHEMA projet TO quocduong;
GRANT USAGE ON SEQUENCE projet.groupes_numero_groupe_seq TO quocduong;

GRANT SELECT ON projet.visualiser_cours_etudiant, projet.visualiser_projets_etudiant, projet.visualiser_projets_etudiant_sans_groupe,
    projet.groupes, projet.inscriptions_cours, projet.inscriptions_groupes, projet.projets, projet.etudiants
    TO quocduong;

GRANT INSERT ON projet.inscriptions_groupes
    TO quocduong;

GRANT DELETE ON projet.inscriptions_groupes
    TO quocduong;

INSERT INTO projet.cours VALUES ('BINV2040', 'BD2', 2, 6);
INSERT INTO projet.cours VALUES ('BINV1020', 'APOO', 1, 6);
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Damas', 'Christophe', 'cd@student.vinci.be', DEFAULT);
INSERT INTO projet.etudiants VALUES (DEFAULT, 'Ferneeuw', 'Stéphanie', 'sf@student.vinci.be', DEFAULT);
SELECT projet.inscrire_etudiant_au_cours('cd@student.vinci.be', 'BINV2040');
SELECT projet.inscrire_etudiant_au_cours('sf@student.vinci.be', 'BINV2040');
SELECT projet.creer_projet('projSQL', 'projet SQL', 'BINV2040', '2023-09-10', '2023-12-15');
SELECT projet.creer_projet('dsd', 'DSD', 'BINV2040', '2023-09-30', '2023-12-01');
SELECT projet.creer_groupe('projSQL', 1, 2);