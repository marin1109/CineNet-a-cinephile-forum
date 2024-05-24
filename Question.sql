\! echo \\nRequete 1 : Selectionne les publications et les événements de chaque utilisateur.
SELECT
    u.u_login,
    p.contenu AS contenu_publication,
    p.p_date AS date_publication,
    e.ev_nom AS nom_evenement,
    e.ev_date AS date_evenement
FROM
    utilisateurs u
    LEFT JOIN publie pub ON u.u_id = pub.u_id
    LEFT JOIN publication p ON pub.p_id = p.p_id
    LEFT JOIN evenement e ON p.ev_fk = e.ev_id
ORDER BY
    u.u_login, p.p_date DESC;


\! echo \\nRequete 2 : récupérer une liste de paires d amis où les noms de connexion des deux utilisateurs sont affichés
SELECT
    U1.u_login AS utilisateur1,
    U2.u_login AS utilisateur2
FROM
    amitie A
    INNER JOIN utilisateurs U1 ON A.u_id1 = U1.u_id
    INNER JOIN utilisateurs U2 ON A.u_id2 = U2.u_id
WHERE
    A.ami = TRUE;

\! echo \\nRequete 3 : trouver les utilisateurs qui ont publié le plus sur chaque film

SELECT u.u_login, f.titre, COUNT(p.p_id) AS nb_publications
FROM publication p
    JOIN publie pb ON p.p_id = pb.p_id
    JOIN utilisateurs u ON pb.u_id = u.u_id
    JOIN film f ON p.film_fk = f.film_id
GROUP BY
    u.u_id, f.film_id
HAVING
    COUNT(p.p_id) = (
        SELECT MAX(pub_count)
        FROM (
            SELECT COUNT(p2.p_id) AS pub_count
            FROM publication p2
            WHERE p2.film_fk = f.film_id
            GROUP BY p2.p_id
        ) AS subquery
    )
ORDER BY
    f.titre, nb_publications DESC;


\! echo \\nRequete 4 : films ayant reçu le plus grand nombre de publications

SELECT
    f.titre,
    f.date_sortie,
    f.note,
    publication_count.nb_publications
FROM
    film f
    INNER JOIN (
        SELECT
            film_fk,
            COUNT(p_id) AS nb_publications
        FROM
            publication
        WHERE
            film_fk IS NOT NULL
        GROUP BY
            film_fk
        HAVING
            COUNT(p_id) > 0
    ) AS publication_count ON f.film_id = publication_count.film_fk
ORDER BY
    publication_count.nb_publications DESC;

\! echo \\nRequete 5 : identifier les films ayant reçu une note supérieure à la moyenne des notes de tous les films

SELECT
    f.titre,
    f.date_sortie,
    f.note
FROM
    film f
WHERE
    f.note > (
        SELECT AVG(note)
        FROM film
        WHERE note IS NOT NULL
    )
ORDER BY
    f.note DESC;


\! echo \\nRequete 6 : Les événements de l année à venir

PREPARE upcoming_events_year AS
SELECT
    ev_nom,
    ev_date,
    ville,
    pays
FROM
    evenement e
    JOIN lieu l ON e.lieu_fk = l.l_id
WHERE
    ev_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '1 year')
ORDER BY
    ev_date;

-- Exécuter la requête préparée
EXECUTE upcoming_events_year;


\! echo \\nRequete 7 : Afficher les événements par nombre de participants et moyenne de participation.

SELECT
    e.ev_nom,
    ep.nb_participant,
    AVG(ep.nb_participant) OVER () AS moyenne_participation
FROM
    evenement e
    JOIN evenement_passe ep ON e.ev_id = ep.ev_fk
ORDER BY
    ep.nb_participant DESC;


\! echo \\nRequete 8 : examiner les organisateurs dévénements futurs, en identifiant ceux qui ont organisé le plus d événements et dont le prix moyen des billets est supérieur à 15.

SELECT
    o.o_nom,
    COUNT(evf_id) AS nombre_evenements,
    AVG(prix) AS prix_moyen
FROM
    organisateur o
    JOIN evenement_futur ef ON o.o_id = ef.organisateur_fk
GROUP BY
    o.o_nom
HAVING
    COUNT(evf_id) > 0 AND AVG(prix) > 15.00
ORDER BY
    nombre_evenements DESC;



\! echo \\nRequete 9 : les utilisateurs qui sont intéressés par au moins un événement :
SELECT
    u.u_login,
    e.ev_nom,
    i.participe
FROM
    utilisateurs u
    INNER JOIN interesse i ON u.u_id = i.u_id
    INNER JOIN evenement e ON i.ev_fk = e.ev_id
ORDER BY
    u.u_login, e.ev_nom;

\! echo \\nRequete 10 : les utilisateurs qui sont ne sont interessé par aucun evenement
SELECT
    u.u_login
FROM
    utilisateurs u
    LEFT JOIN interesse i ON u.u_id = i.u_id
WHERE
    i.u_id IS NULL
ORDER BY
    u.u_login;

\! echo \\nRequete 11 : les films qui n ont aucune publication associée
--s ous-requête corrélées
SELECT
    f.titre
FROM
    film f
WHERE
    NOT EXISTS (
        SELECT 1
        FROM publication p
        WHERE p.film_fk = f.film_id
    )
ORDER BY
    f.titre;
-- avec agrégation
SELECT
    f.titre
FROM
    film f
LEFT JOIN
    publication p ON f.film_id = p.film_fk
GROUP BY
    f.titre
HAVING
    COUNT(p.p_id) = 0
ORDER BY
    f.titre;


\! echo \\nRequete 12 :  Lister les genres de films et les titres des films associés, excluant les films avec des genres non définis
-- Requête initiale : 40 rows

SELECT
    g.g_nom,
    f.titre
FROM
    genre g
    JOIN film f ON g.g_id = f.genre_fk
ORDER BY
    g.g_nom, f.titre;


-- resultat différent : 64 rows
SELECT
    g.g_nom,
    f.titre
FROM
    genre g
    LEFT JOIN film f ON g.g_id = f.genre_fk
ORDER BY
    g.g_nom, f.titre;


-- version modifiée 40 rows
SELECT
    g.g_nom,
    f.titre
FROM
    genre g
    LEFT JOIN film f ON g.g_id = f.genre_fk
WHERE
    f.genre_fk IS NOT NULL
ORDER BY
    g.g_nom, f.titre;



\! echo \\nRequete 13 : le prochain jour sans événement pour tous les lieux.

WITH RECURSIVE next_free_day AS (
    -- CTE initiale : commence à partir de la date actuelle
    SELECT CURRENT_DATE::timestamp AS potential_free_day
    UNION ALL
    -- CTE récursive : incrémente la date et vérifie si elle est libre
    SELECT potential_free_day + INTERVAL '1 day'
    FROM next_free_day
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM evenement e
            WHERE e.ev_date = potential_free_day::date
        )
)
SELECT potential_free_day::date
FROM next_free_day
WHERE
    NOT EXISTS (
        SELECT 1
        FROM evenement e
        WHERE e.ev_date = potential_free_day::date
    )
ORDER BY
    potential_free_day
LIMIT 1;


\! echo \\nRequete 14 :  Trouver les cinémas les plus fréquentés chaque mois.

WITH monthly_frequentation AS (
    SELECT
        l.l_id,
        l.l_nom,
        DATE_TRUNC('month', e.ev_date) AS month,
        SUM(ep.nb_participant) AS total_participants
    FROM
        lieu l
        JOIN evenement e ON l.l_id = e.lieu_fk
        JOIN evenement_passe ep ON e.ev_id = ep.ev_fk
    GROUP BY
        l.l_id,
        l.l_nom,
        DATE_TRUNC('month', e.ev_date)
),
ranked_frequentation AS (
    SELECT
        l_id,
        l_nom,
        month,
        total_participants,
        RANK() OVER (PARTITION BY month ORDER BY total_participants DESC) AS rank
    FROM
        monthly_frequentation
)
SELECT
    l_id,
    l_nom,
    month,
    total_participants
FROM
    ranked_frequentation
WHERE
    rank = 1
ORDER BY
    month, total_participants DESC;


\! echo \\nRequete 15 : Identifier les utilisateurs qui n ont publié aucune publication liée à un film.

SELECT
    u.u_login
FROM
    utilisateurs u
WHERE
    NOT EXISTS (
        SELECT 1
        FROM publie pb
        JOIN publication p ON pb.p_id = p.p_id
        WHERE pb.u_id = u.u_id
          AND p.film_fk IS NOT NULL
    )
ORDER BY
    u.u_login;

\! echo \\nRequete 16 : rouver les pairs d utilisateurs qui sont amis entre eux

SELECT
    u1.u_login AS user1,
    u2.u_login AS user2
FROM
    amitie a1
    JOIN amitie a2 ON a1.u_id2 = a2.u_id1
    JOIN utilisateurs u1 ON a1.u_id1 = u1.u_id
    JOIN utilisateurs u2 ON a2.u_id2 = u2.u_id
WHERE
    a1.ami = TRUE
    AND a2.ami = TRUE
ORDER BY
    user1, user2;


\! echo \\nRequete 17 : Trouver les genres avec la moyenne des notes des films.

SELECT
    g.g_nom,
    AVG(films_avg.avg_note) AS avg_note
FROM
    genre g
    JOIN (
        SELECT
            f.genre_fk,
            AVG(f.note) AS avg_note
        FROM
            film f
        GROUP BY
            f.genre_fk
    ) AS films_avg ON g.g_id = films_avg.genre_fk
GROUP BY
    g.g_nom
ORDER BY
    avg_note DESC;

\! echo \\nRequete 18 : Lister les noms de tous les genres distincts présents dans les films.
SELECT DISTINCT
    g.g_nom
FROM
    genre g
    JOIN film f ON g.g_id = f.genre_fk
ORDER BY
    g.g_nom;

\! echo \\nRequete 19 : Lister les villes distinctes où des événements ont été organisés.

SELECT DISTINCT
    l.ville
FROM
    lieu l
    JOIN evenement e ON l.l_id = e.lieu_fk
ORDER BY
    l.ville;

\! echo \\nRequete 20 : Trouver tous les genres et sous-genres en hiérarchie.

WITH RECURSIVE genre_hierarchy AS (
    SELECT
        g.g_id,
        g.g_nom,
        g.genre_parent,
        1 AS level
    FROM
        genre g
    WHERE
        g.genre_parent IS NULL
    UNION ALL
    SELECT
        g.g_id,
        g.g_nom,
        g.genre_parent,
        gh.level + 1 AS level
    FROM
        genre g
        JOIN genre_hierarchy gh ON g.genre_parent = gh.g_id
)
SELECT
    g_id,
    g_nom,
    genre_parent,
    level
FROM
    genre_hierarchy
ORDER BY
    level, g_id;





\! echo \\nRequete 21 : Pour chaque film, classer les publications par date et numéroter les publications.

SELECT
    p.film_fk,
    p.p_id,
    p.p_date,
    ROW_NUMBER() OVER (PARTITION BY p.film_fk ORDER BY p.p_date) AS publication_number
FROM
    publication p
WHERE
    p.film_fk IS NOT NULL
ORDER BY
    p.film_fk, p.p_date;


\! echo \\nRequete 22 : Pour chaque organisateur, calculer la moyenne et le total des participants aux événements qu ils ont organisés.

SELECT
    o.o_nom,
    AVG(ef.nb_place) AS avg_participants,
    SUM(ef.nb_place) AS total_participants
FROM
    organisateur o
    JOIN evenement_futur ef ON o.o_id = ef.organisateur_fk
GROUP BY
    o.o_nom
ORDER BY
    total_participants DESC;
