-- Supprimer les tables de liaison et les tables dépendantes en premier
DROP TABLE IF EXISTS publie CASCADE;
DROP TABLE IF EXISTS hashtag_genre CASCADE;
DROP TABLE IF EXISTS hashtag_serie CASCADE;
DROP TABLE IF EXISTS hashtag_film CASCADE;
DROP TABLE IF EXISTS hashtag_lieu CASCADE;
DROP TABLE IF EXISTS hashtag_evenement CASCADE;
DROP TABLE IF EXISTS hashtag_publication CASCADE;  
DROP TABLE IF EXISTS retour CASCADE;
DROP TABLE IF EXISTS evenement_futur CASCADE;
DROP TABLE IF EXISTS evenement_passe CASCADE;
DROP TABLE IF EXISTS publication CASCADE;
DROP TABLE IF EXISTS interesse CASCADE;  
DROP TABLE IF EXISTS evenement CASCADE;
DROP TABLE IF EXISTS serie CASCADE;
DROP TABLE IF EXISTS film CASCADE;
DROP TABLE IF EXISTS organisateur CASCADE;
DROP TABLE IF EXISTS artiste CASCADE;
DROP TABLE IF EXISTS personne CASCADE;
DROP TABLE IF EXISTS amitie CASCADE;
DROP TABLE IF EXISTS genre CASCADE;
DROP TABLE IF EXISTS hashtag CASCADE;
DROP TABLE IF EXISTS conversation CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;
DROP TABLE IF EXISTS utilisateurs CASCADE;


-- Table principale pour tous les utilisateurs
CREATE TABLE utilisateurs (
    u_id INT PRIMARY KEY,
    u_login VARCHAR(255) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    role_forum VARCHAR(50)
);

-- Table d'amitié (relation entre utilisateurs)
CREATE TABLE amitie (
    u_id1 INT,
    u_id2 INT,
    ami BOOLEAN NOT NULL, -- FALSE -> follow, TRUE -> ami
    PRIMARY KEY (u_id1, u_id2),
    FOREIGN KEY (u_id1) REFERENCES utilisateurs(u_id) ON DELETE CASCADE,
    FOREIGN KEY (u_id2) REFERENCES utilisateurs(u_id) ON DELETE CASCADE
);

-- Table pour les personnes qui est une spécialisation de utilisateurs
CREATE TABLE personne (
    p_id SERIAL PRIMARY KEY,
    u_id INT NOT NULL UNIQUE, -- Lien vers utilisateurs
    type VARCHAR(255),
    FOREIGN KEY (u_id) REFERENCES utilisateurs(u_id) ON DELETE CASCADE
);

-- Table pour les artistes qui est une spécialisation de utilisateurs
CREATE TABLE artiste (
    a_id SERIAL PRIMARY KEY,
    u_id INT NOT NULL UNIQUE, -- Lien vers utilisateurs
    type_artiste VARCHAR(255),
    FOREIGN KEY (u_id) REFERENCES utilisateurs(u_id) ON DELETE CASCADE
);

-- Table pour les organisateurs qui est une spécialisation de utilisateurs
CREATE TABLE organisateur (
    o_id SERIAL PRIMARY KEY,
    u_id INT NOT NULL UNIQUE, -- Lien vers utilisateurs
    o_nom VARCHAR(255),
    FOREIGN KEY (u_id) REFERENCES utilisateurs(u_id) ON DELETE CASCADE
);

-- Table pour les lieux des événements
CREATE TABLE lieu (
    l_id SERIAL PRIMARY KEY,
    l_nom VARCHAR(255) NOT NULL,
    ville VARCHAR(255),
    pays VARCHAR(255),
    capacite INT CHECK (capacite > 0)
);

-- Table pour les événements générale
CREATE TABLE evenement (
    ev_id SERIAL PRIMARY KEY,
    ev_nom VARCHAR(255) NOT NULL,
    ev_date DATE,
    lieu_fk INT,
    FOREIGN KEY (lieu_fk) REFERENCES lieu(l_id) ON DELETE SET NULL
);

-- Table pour la relation entre utilisateurs et événements
CREATE TABLE interesse (
    u_id INT,
    ev_fk INT,
    participe BOOLEAN NOT NULL, -- TRUE -> participe, FALSE -> intéressé
    PRIMARY KEY (u_id, ev_fk),
    FOREIGN KEY (u_id) REFERENCES utilisateurs(u_id) ON DELETE CASCADE,
    FOREIGN KEY (ev_fk) REFERENCES evenement(ev_id) ON DELETE CASCADE
);

-- Table pour les événements passés qui est une spécialisation de evenement
CREATE TABLE evenement_passe (
    evp_id INT PRIMARY KEY,
    nb_participant INT,
    programme TEXT,
    lien VARCHAR(255),
    ev_fk INT,
    FOREIGN KEY (ev_fk) REFERENCES evenement(ev_id) ON DELETE CASCADE
);

-- Table pour les retours sur un événement
CREATE TABLE retour (
    r_id INT PRIMARY KEY,
    evp_fk INT,
    contenu TEXT,
    auteur_fk INT,
    date_rep DATE,
    FOREIGN KEY (evp_fk) REFERENCES evenement_passe(evp_id) ON DELETE CASCADE,
    FOREIGN KEY (auteur_fk) REFERENCES utilisateurs(u_id) ON DELETE CASCADE
);

-- Table pour les événements futurs qui est une spécialisation de evenement
CREATE TABLE evenement_futur (
    evf_id INT PRIMARY KEY,
    prix DECIMAL(10, 2),
    nb_place INT,
    programme TEXT,
    organisateur_fk INT,
    ev_fk INT,
    FOREIGN KEY (ev_fk) REFERENCES evenement(ev_id) ON DELETE CASCADE,
    FOREIGN KEY (organisateur_fk) REFERENCES organisateur(o_id) ON DELETE CASCADE
);


-- Table pour les conversations
CREATE TABLE conversation (
    conv_id INT PRIMARY KEY,
    categorie VARCHAR(255)
);

-- Table pour les publications
CREATE TABLE publication (
    p_id INT PRIMARY KEY,
    contenu TEXT,
    p_date TIMESTAMP,
    sujet TEXT,
    emoji VARCHAR(30),
    conv_fk INT,
    ev_fk INT,
    film_fk INT,
    serie_fk INT,
    parent_id INT,
    FOREIGN KEY (conv_fk) REFERENCES conversation(conv_id) ON DELETE CASCADE,
    FOREIGN KEY (ev_fk) REFERENCES evenement(ev_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES publication(p_id) ON DELETE CASCADE
);

-- Table publie pour lier publications et utilisateurs
CREATE TABLE publie (
    p_id INT,
    u_id INT,
    PRIMARY KEY (p_id, u_id),
    FOREIGN KEY (p_id) REFERENCES publication(p_id) ON DELETE CASCADE,
    FOREIGN KEY (u_id) REFERENCES utilisateurs(u_id) ON DELETE CASCADE
);

-- Table des films
CREATE TABLE film (
    film_id SERIAL PRIMARY KEY,
    titre VARCHAR(255) NOT NULL,
    artiste_fk INT,
    date_sortie DATE,
    genre_fk INT,
    synopsis TEXT,
    duree INT,
    note INT CHECK (note BETWEEN 0 AND 5),
    FOREIGN KEY (artiste_fk) REFERENCES artiste(a_id) ON DELETE SET NULL
);

-- Table des séries
CREATE TABLE serie (
    serie_id SERIAL PRIMARY KEY,
    r_nom VARCHAR(255) NOT NULL,
    genre_fk INT,
    artiste_fk INT,
    FOREIGN KEY (artiste_fk) REFERENCES artiste(a_id) ON DELETE SET NULL
);

-- Ajout de clés étrangères pour les films et les séries après leur création
-- Cela permet de s'assurer que toutes les tables référencées sont déjà en place
ALTER TABLE publication ADD FOREIGN KEY (film_fk) REFERENCES film(film_id);
ALTER TABLE publication ADD FOREIGN KEY (serie_fk) REFERENCES serie(serie_id);

-- Table des genres
CREATE TABLE genre (
    g_id INT PRIMARY KEY,
    g_nom VARCHAR(255),
    genre_parent INT
);

-- Ajouter une clé étrangère pour les genres parents après la création de la table
-- Permet d'établir une hiérarchie entre genres après que tous les genres soient créés
ALTER TABLE genre ADD FOREIGN KEY (genre_parent) REFERENCES genre(g_id);
ALTER TABLE film ADD FOREIGN KEY (genre_fk) REFERENCES genre(g_id);
ALTER TABLE serie ADD FOREIGN KEY (genre_fk) REFERENCES genre(g_id);

-- Table des hashtags
CREATE TABLE hashtag (
    h_id INT PRIMARY KEY,
    h_nom VARCHAR(255)
);

-- Les tables de liaison pour hashtags avec événements, lieux, films, séries et genres
CREATE TABLE hashtag_evenement (
    h_id INT,
    ev_id INT,
    FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
    FOREIGN KEY (ev_id) REFERENCES evenement(ev_id) ON DELETE CASCADE,
    PRIMARY KEY (h_id, ev_id)
);

CREATE TABLE hashtag_publication (
    h_id INT,
    p_id INT,
    FOREIGN KEY (p_id) REFERENCES publication(p_id) ON DELETE CASCADE,
    FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
    PRIMARY KEY (p_id, h_id)
);

CREATE TABLE hashtag_lieu (
    h_id INT,
    l_id INT,
    FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
    FOREIGN KEY (l_id) REFERENCES lieu(l_id) ON DELETE CASCADE,
    PRIMARY KEY (h_id, l_id)
);

CREATE TABLE hashtag_film (
    h_id INT,
    film_id INT,
    FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
    FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE CASCADE,
    PRIMARY KEY (h_id, film_id)
);

CREATE TABLE hashtag_serie (
    h_id INT,
    serie_id INT,
    FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
    FOREIGN KEY (serie_id) REFERENCES serie(serie_id) ON DELETE CASCADE,
    PRIMARY KEY (h_id, serie_id)
);

CREATE TABLE hashtag_genre (
    h_id INT,
    g_id INT,
    FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
    FOREIGN KEY (g_id) REFERENCES genre(g_id) ON DELETE CASCADE,
    PRIMARY KEY (h_id, g_id)
);

ALTER TABLE hashtag_evenement
ADD CONSTRAINT fk_hashtag_evenement_h_id FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_hashtag_evenement_ev_id FOREIGN KEY (ev_id) REFERENCES evenement(ev_id) ON DELETE CASCADE;

ALTER TABLE hashtag_publication
ADD CONSTRAINT fk_hashtag_publication_h_id FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_hashtag_publication_p_id FOREIGN KEY (p_id) REFERENCES publication(p_id) ON DELETE CASCADE;

ALTER TABLE hashtag_lieu
ADD CONSTRAINT fk_hashtag_lieu_h_id FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_hashtag_lieu_l_id FOREIGN KEY (l_id) REFERENCES lieu(l_id) ON DELETE CASCADE;

ALTER TABLE hashtag_film
ADD CONSTRAINT fk_hashtag_film_h_id FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_hashtag_film_film_id FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE CASCADE;

ALTER TABLE hashtag_serie
ADD CONSTRAINT fk_hashtag_serie_h_id FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_hashtag_serie_serie_id FOREIGN KEY (serie_id) REFERENCES serie(serie_id) ON DELETE CASCADE;

ALTER TABLE hashtag_genre
ADD CONSTRAINT fk_hashtag_genre_h_id FOREIGN KEY (h_id) REFERENCES hashtag(h_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_hashtag_genre_g_id FOREIGN KEY (g_id) REFERENCES genre(g_id) ON DELETE CASCADE;

-- Remplir les tables avec les données des fichiers CSV
\copy utilisateurs FROM 'CSV/utilisateurs.csv' DELIMITER ',' CSV HEADER;
\copy amitie FROM 'CSV/amitie.csv' DELIMITER ',' CSV HEADER;
\copy personne FROM 'CSV/personne.csv' DELIMITER ',' CSV HEADER;
\copy artiste FROM 'CSV/artiste.csv' DELIMITER ',' CSV HEADER;
\copy organisateur FROM 'CSV/organisateur.csv' DELIMITER ',' CSV HEADER;
\copy lieu FROM 'CSV/lieu.csv' DELIMITER ',' CSV HEADER;
\copy evenement FROM 'CSV/evenement.csv' DELIMITER ',' CSV HEADER;
\copy interesse FROM 'CSV/interesse.csv' DELIMITER ',' CSV HEADER;
\copy evenement_passe FROM 'CSV/evenement_passe.csv' DELIMITER ',' CSV HEADER;
\copy retour FROM 'CSV/retour.csv' DELIMITER ',' CSV HEADER;
\copy evenement_futur FROM 'CSV/evenement_futur.csv' DELIMITER ',' CSV HEADER;
\copy conversation FROM 'CSV/conversation.csv' DELIMITER ',' CSV HEADER;
\copy genre FROM 'CSV/genre.csv' DELIMITER ',' CSV HEADER;
\copy film FROM 'CSV/film.csv' DELIMITER ',' CSV HEADER;
\copy serie FROM 'CSV/serie.csv' DELIMITER ',' CSV HEADER;
\copy publication FROM 'CSV/publication.csv' DELIMITER ',' CSV HEADER;
\copy publie FROM 'CSV/publie.csv' DELIMITER ',' CSV HEADER;
\copy hashtag FROM 'CSV/hashtag.csv' DELIMITER ',' CSV HEADER;
\copy hashtag_evenement FROM 'CSV/hashtag_evenement.csv' DELIMITER ',' CSV HEADER;
\copy hashtag_publication FROM 'CSV/hashtag_publication.csv' DELIMITER ',' CSV HEADER;
\copy hashtag_lieu FROM 'CSV/hashtag_lieu.csv' DELIMITER ',' CSV HEADER;
\copy hashtag_film FROM 'CSV/hashtag_film.csv' DELIMITER ',' CSV HEADER;
\copy hashtag_serie FROM 'CSV/hashtag_serie.csv' DELIMITER ',' CSV HEADER;
\copy hashtag_genre FROM 'CSV/hashtag_genre.csv' DELIMITER ',' CSV HEADER;
