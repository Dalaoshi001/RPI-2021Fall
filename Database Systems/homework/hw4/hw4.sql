-- Question 1

SELECT DISTINCT a.name FROM artists a, songs so, spotify sp 
WHERE a.id = so.artistid and so.id = sp.songid and sp.streams >= 10000000 
ORDER BY a.name ASC;

-- Question2

SELECT DISTINCT a.name FROM artists a, songs s, 
bilboard b, rollingstonetop500 r
WHERE a.id = s.artistid and b.songid = s.id and b.rank = 1
and r.artistid = a.id and r.position <= 50 ORDER by a.name ASC;

-- Question3

(SELECT s.id as songid, s.name as songname, a.name as artistname FROM artists a, bilboard b, songs s
WHERE a.id = s.artistid and b.songid = s.id
and b.weeksonboard >= 25 and
b.chartdate >= date '2020-08-01' and b.chartdate <= date '2020-08-31'

UNION

SELECT s.id as songid, s.name as songname, a.name as artistname FROM artists a, songs s, spotify sp
WHERE a.id = s.artistid and sp.songid = s.id and
sp.streams >= 5000000 and sp.streamdate >= date '2020-08-01' and
sp.streamdate <= date '2020-08-31')

ORDER BY songname ASC, artistname ASC;

-- Question4
SELECT s.id as songid, s.name as songname, a.name as artistname

FROM artists a, songs s, playedonradio p

WHERE a.id = s.artistid and p.songid = s.id and 
CAST(p.playedtime AS TIME) >= time '08:00:00' and 
CAST(p.playedtime AS TIME) <= time '10:00:00'

EXCEPT

SELECT s.id as songid, s.name as songname, a.name as artistname

FROM artists a, songs s, playedonradio p

WHERE a.id = s.artistid and p.songid = s.id and

(CAST(p.playedtime AS TIME) > time '10:00:00'
or CAST(p.playedtime AS TIME) < time '08:00:00')

ORDER BY songname ASC, artistname ASC;

-- Question5

SELECT s.id as songid, s.name as songname, a.name as artistname
FROM artists a, songs s, playedonradio p, spotify sp
WHERE a.id = s.artistid and p.songid = s.id and s.id = sp.songid
and sp.streams >= 4000000

EXCEPT

SELECT s.id as songid, s.name as songname, a.name as artistname
FROM  artists a, songs s, bilboard b
WHERE a.id = s.artistid and b.songid = s.id

ORDER BY songname ASC, artistname ASC;

-- Question6
SELECT a.id, a.name, COUNT(DISTINCT b.songid) as songsonbilboard, MIN(b.rank) as minbilboardrank

FROM artists a, rollingstonetop500 r, bilboard b, songs s

WHERE a.id = s.artistid and r.artistid = a.id and b.songid = s.id
and r.position <= 25

GROUP BY a.id

ORDER BY a.name ASC;

-- Question7
SELECT a.id, a.name

FROM artists a, songs s, rollingstonetop500 r, playedonradio p

WHERE a.id = s.artistid and r.artistid = a.id and p.songid = s.id
and CAST(p.playedtime AS DATE) >= '2020-03-01'
and CAST(p.playedtime AS DATE) <= '2020-03-31'

GROUP BY a.id

HAVING COUNT(DISTINCT p.station) >= 2 and COUNT(DISTINCT p.id) >= 20
ORDER BY a.id;

--Question8
SELECT sg.genre

FROM songs s, song_genre sg, bilboard b

WHERE s.id = sg.songid and b.songid = s.id

GROUP BY sg.genre

HAVING COUNT(DISTINCT b.songid) >= 4 and MIN(b.rank) > 5

ORDER BY sg.genre;