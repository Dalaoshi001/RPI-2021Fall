-- Question1
SELECT a.name as artistname, COUNT(DISTINCT b.songid) as numsongs FROM artists a 
INNER JOIN rollingstonetop500 r ON r.artistid = a.id and r.position <= 20
INNER JOIN songs s ON a.id = s.artistid
LEFT OUTER JOIN bilboard b ON b.songid = s.id
GROUP BY a.id
ORDER BY numsongs DESC, artistname ASC;

-- Question2  some question about group and distinct p.id
SELECT s.name as songname, a.name as artistname, 
COUNT(DISTINCT p.id) as numplayed
FROM
songs s INNER JOIN bilboard b 
ON s.id = b.songid and b.rank <= 10
and s.danceability >= 0.9

LEFT OUTER JOIN artists a
ON a.id = s.artistid

LEFT OUTER JOIN playedonradio p
ON p.songid = s.id

GROUP BY s.id, a.id
ORDER BY numplayed DESC, songname ASC, artistname ASC;

-- Question3
SELECT s.name as songname, a.name as artistname, MIN(b.rank) as minrank FROM 
songs s 
INNER JOIN bilboard b ON s.id = b.songid 
LEFT JOIN playedonradio p ON p.songid = s.id
LEFT JOIN artists a ON a.id = s.artistid
GROUP BY s.id, a.id
HAVING COUNT(DISTINCT p.id) = 0 and MAX(b.weeksonboard) >= 25
ORDER BY minrank ASC, songname ASC, artistname ASC;

-- Question4
SELECT s.name as songname, a.name as artistname, MIN(b.rank) as minrank FROM 
songs s, bilboard b, artists a
WHERE s.id = b.songid
and a.id = s.artistid
and NOT EXISTS(SELECT * FROM playedonradio p WHERE p.songid = s.id)
GROUP BY s.id, a.id
HAVING MAX(b.weeksonboard) >= 25
ORDER BY minrank ASC, songname ASC, artistname ASC;


-- Question5
SELECT s.name as songname, a.name as artistname, s.decade as decade,
CAST(s.duration_ms / 60000 AS INTEGER) as duration
FROM songs s, artists a
WHERE a.id = s.artistid and
CAST(s.duration_ms / 60000 AS INTEGER) =
(SELECT MIN(CAST(s1.duration_ms / 60000 AS INTEGER))
FROM songs s1)
ORDER BY songname, artistname;

-- Question6
SELECT s.name as songname, a.name as artistname, to_char(SUM(sp.streams),'999,999,999,999')  as totalstreams
FROM songs s, spotify sp, artists a
WHERE s.id = sp.songid and s.artistid = a.id
GROUP BY s.id, a.id
HAVING SUM(sp.streams) >= 0.5 * (SELECT MAX(x.sum) FROM
(SELECT SUM(sp.streams) as sum
FROM songs s, spotify sp, artists a
WHERE s.id = sp.songid and s.artistid = a.id
GROUP BY s.id, a.id) AS x) 
ORDER BY songname, artistname;


-- Question7
SELECT a.name as artistname
FROM artists a,
rollingstonetop500 r,
(SELECT a.id AS artistid, MIN(bilminYear.mindate) AS minartdate
FROM artists a,
(SELECT songid, MIN(EXTRACT(YEAR FROM chartdate)) AS mindate
FROM bilboard
WHERE rank <= 10
GROUP BY songid) AS bilminYear, songs s

WHERE a.id = s.artistid and s.id = bilminYear.songid

GROUP BY a.id) AS artminYear

WHERE a.id = r.artistid
and a.id = artminYear.artistid and artminYear.minartdate >= 
2003

ORDER BY artistname;


-- Question8
SELECT station, COUNT(DISTINCT uniquesongs.songid) AS numsongs
FROM playedonradio p,
(SELECT p.songid AS songid, COUNT(DISTINCT p.station) AS numstations
FROM playedonradio p
GROUP BY p.songid) AS uniquesongs

WHERE p.songid = uniquesongs.songid and uniquesongs.numstations = 1
and lower(p.station) LIKE 'm%'
GROUP BY station
ORDER BY station;