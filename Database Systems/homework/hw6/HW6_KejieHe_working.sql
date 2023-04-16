DROP FUNCTION IF EXISTS recommendation(time,time,varchar,int,float,float,float);

DROP TABLE IF EXISTS songsimilarity;

CREATE TABLE songsimilarity(
    songid       int
    , songname   text
    , artistname text
    , songscore  float
) ;    

CREATE OR REPLACE FUNCTION
    recommendation(fromtime time
               , totime time
               , inputstation varchar
               , topk int
	       , w1 float, w2 float, w3 float)
    RETURNS SETOF songsimilarity AS $recommendation$
DECLARE
	myrow songsimilarity%rowtype ;
BEGIN
-- Get the song in range
	DROP TABLE IF EXISTS songsplayed;
	CREATE TEMP TABLE songsplayed AS      
	SELECT 
		s.id as songid
		, s.name as songname
	FROM 
		songs s
		, playedonradio pr
	WHERE 
		s.id = pr.songid
		AND fromtime <= pr.playedtime::time
		AND pr.playedtime::time <= totime;
		
-- Get the song not in range
	DROP TABLE IF EXISTS songsnotplayed;
	CREATE TEMP TABLE songsnotplayed AS      
	SELECT 
		s.id as songid
		, s.name as songname
	FROM 
		songs s
	EXCEPT
	SELECT 
		songid
		, songname
	FROM
		songsplayed sp;
		
-- 	Pre-calculate the genre of the given set, store it into a record
	DROP TABLE IF EXISTS genresimilarity;
	CREATE TEMP TABLE genresimilarity AS   
	SELECT
	sg.genre as genre, count(sg.genre) as genrecount
	FROM
		song_genre sg,
		songsplayed sp
	WHERE
		sg.songid = sp.songid
	GROUP BY
		sg.genre
	ORDER BY
		count(sg.genre) DESC;
-- Pre-calculate the average bilboard ranking
	DROP TABLE IF EXISTS avgbilboardscorebydecade;
	CREATE TEMP TABLE avgbilboardscorebydecade AS   
	SELECT 
	s.decade
	, avg(rank) as avgrank
	FROM 
		bilboard b
		, songs s
		, songsplayed sp
	WHERE
		b.songid = s.id
		AND s.id = sp.songid
	GROUP BY
		s.decade
	ORDER BY
		s.decade;
	INSERT INTO avgbilboardscorebydecade(decade, avgrank) VALUES (NULL, 0);	
	
-- Pre calculate the average tempo, loudness, acousticness
	DROP TABLE IF EXISTS avgproperties;
	CREATE TEMP TABLE avgproperties AS  
	SELECT 
		avg(s.tempo) as tempoavg,
		avg(s.loudness) as loudnessavg,
		avg(s.acousticness) as acousticnessavg
	FROM 
		songs s,
		songsplayed sp
	WHERE
		s.id = sp.songid;
-- Helper Functions
-- 	Auto calculate genre score
	DROP FUNCTION IF EXISTS gsscore(thissongid bigint) ;
	CREATE OR REPLACE FUNCTION 
		gsscore(thissongid bigint)
	RETURNS bigint AS 
	$gsscore$
	DECLARE
	   sumdata bigint;
	   thisgenre varchar;
	BEGIN
		SELECT 0 INTO sumdata;

	   FOR thisgenre in SELECT sg.genre 
			FROM 
				song_genre sg
			WHERE
				sg.songid = thissongid
		LOOP
		sumdata = sumdata + COALESCE(		
			(SELECT  
				genrecount
			FROM
				genresimilarity
			WHERE
				genre = thisgenre
			),0);		
		END LOOP;   
	   RETURN sumdata ;
	END ;
	$gsscore$ LANGUAGE plpgsql ;
-- --------------------------------
-- Rank similarity
DROP FUNCTION IF EXISTS ranksimilarity(thissongid bigint) ;
CREATE OR REPLACE FUNCTION 
	ranksimilarity(thissongid bigint)
RETURNS double precision AS 
$ranksimilarity$
DECLARE
 	thisavgrank double precision;
	thisdecade text;
	decadeavgrank double precision;
	ranksimu double precision;
BEGIN
	SELECT (
	SELECT
		avg(rank)
	FROM 
		bilboard b
	WHERE
		b.songid = thissongid		
	) INTO thisavgrank;
	
	SELECT (
	SELECT 
		s.decade
	FROM 
		bilboard b,
		songs s 
	WHERE
		b.songid = thissongid
		AND thissongid = s.id
	LIMIT 1
	) INTO thisdecade; 
	
	SELECT (
	SELECT
		absd.avgrank	
	FROM
		avgbilboardscorebydecade absd
	WHERE
		absd.decade = thisdecade		
	) INTO decadeavgrank;
	
	SELECT 1.0 / abs(decadeavgrank - thisavgrank ) INTO ranksimu;
	SELECT COALESCE(ranksimu, 0) INTO ranksimu;
  	
   RETURN ranksimu ;
END ;
$ranksimilarity$ LANGUAGE plpgsql ;
-- songsimilarity
DROP FUNCTION IF EXISTS songsimularity(thissongid bigint) ;
CREATE OR REPLACE FUNCTION 
	songsimularity(thissongid bigint)
RETURNS double precision AS 
$songsimularity$
DECLARE
	thisrecord RECORD;
	thisresult double precision;
BEGIN
	SELECT
		s.tempo,
		s.loudness,
		s.acousticness
	INTO thisrecord
	FROM 
		songs s
	WHERE 
		s.id = thissongid;
	
	SELECT abs(thisrecord.tempo - a.tempoavg) + abs(thisrecord.loudness - a.loudnessavg) + abs(thisrecord.acousticness - a.acousticnessavg) 
	INTO thisresult
	FROM avgproperties a;
	SELECT COALESCE(thisresult, 0) INTO thisresult;
	
	RETURN thisresult;

END ;
$songsimularity$ LANGUAGE plpgsql ;
-- --------------------------------
-- Main Body

   FOR myrow IN 
		SELECT 
			DISTINCT s.id as songid
			, s.name as songname
			, a.name as artistname
			, 
			gsscore(s.id) * w1 
			+ ranksimilarity(s.id) * w2
			+ songsimularity(s.id) * w3 
			as songscore
		 FROM 
			songs s
			, artists a
			, songsnotplayed snp
		 WHERE 
			s.artistid = a.id
			AND s.id = snp.songid
	ORDER BY
		songscore ASC
	LIMIT topk
   LOOP
       RETURN NEXT myrow ;
   END LOOP ;
   
   RETURN;
   
--    DROP ALL THE TEMP TABLE CREATED
	DROP TABLE genresimilarity;
   	DROP TABLE songsplayed;
	DROP TABLE songsnotplayed;
	DROP TABLE avgbilboardscorebydecade;
	DROP TABLE avgproperties;
	DROP FUNCTION gsscore(thissongid) ;
	DROP FUNCTION ranksimilarity(thissongid bigint) ;
	DROP FUNCTION songsimularity(thissongid bigint) ;
END ;
$recommendation$ LANGUAGE plpgsql ;

select * from recommendation(time '08:00',time '10:00', 'mai', 10,1,0,0);
