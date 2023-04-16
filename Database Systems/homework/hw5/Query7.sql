-- artists
-- bilboard           
-- playedonradio      
-- rollingstonetop500
-- song_genre         
-- songs              
-- spotify

SELECT
	DISTINCT a.name AS artistname
FROM 
	artists a,
	rollingstonetop500 rs,
	songs s,	
	bilboard b
WHERE
	a.id = rs.artistid
	and rs.year >= 2003
	and s.artistid = a.id
	and b.songid = s.id
	and b.rank <= 10
	and b.chartdate >= date('2003-01-01')	
ORDER BY
	a.name ASC;