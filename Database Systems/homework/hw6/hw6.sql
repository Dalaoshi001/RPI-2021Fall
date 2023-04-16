DROP FUNCTION IF EXISTS recommendation(time,time,varchar,int,float,float,float);
DROP FUNCTION IF EXISTS recommendation_helper(time,time,varchar,int,float,float,float);

CREATE OR REPLACE FUNCTION
    recommendation_helper(fromtime time
               , totime time
               , inputstation varchar
               , topk int
	       , w1 float, w2 float, w3 float) RETURNS VARCHAR AS $$
BEGIN
   RETURN 'Inputs: '||fromtime::varchar(5)||' '||totime::varchar(5)||' / '||inputstation||' / '||topk::varchar||' / '||w1::varchar||' '||w2::varchar||' '||w3::varchar ;
END ;
$$ LANGUAGE plpgsql ;

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

    --  The function to get the corresponding songid within the time period and in that station
    DROP TABLE IF EXISTS songsplayed;
    CREATE TABLE songsplayed AS
    SELECT DISTINCT p.songid as songid
    FROM playedonradio p
    WHERE p.station = inputstation and p.playedtime::TIME >= fromtime AND p.playedtime::TIME <= totime;


    -- Write to the table get all songs except previous ones
    DROP TABLE IF EXISTS songsnosuchtime;
    CREATE TABLE songsnosuchtime AS
    SELECT DISTINCT s.id as songid FROM songs s
    EXCEPT SELECT DISTINCT ss.songid FROM songsplayed ss;


    -- The function which is to calcualte the gs score

   CREATE OR REPLACE FUNCTION gs(realid BIGINT)
    RETURNS FLOAT AS $gs$
    DECLARE
        score float;
    BEGIN
        score = (SELECT SUM(songnum)::float FROM (SELECT COUNT(ss.songid) AS songnum FROM song_genre, songsplayed ss WHERE
        ss.songid = song_genre.songid AND
        genre IN 
                    (SELECT genre FROM song_genre sg WHERE sg.songid = realid)) AS x);
        RETURN score;
    END;
    $gs$ LANGUAGE plpgsql;

    -- The function which is to calculate rs score

    CREATE OR REPLACE FUNCTION rs(realid BIGINT)
    RETURNS float AS $rs$
    DECLARE
        score float;
        samedecade text;
        avgrank float;
        avgrankplayed float;
    BEGIN
        SELECT s.decade into samedecade FROM songs s WHERE s.id = realid;
        IF samedecade IS NULL THEN
            score = 0;
            RETURN score;
        ElSE
            DROP TABLE IF EXISTS songsrank;
            CREATE TABLE songsrank AS 
            SELECT b.songid as songid, s.decade as decade, avg(b.rank) as rank FROM bilboard b, songsplayed sp, songs s
            WHERE sp.songid = b.songid AND s.id = sp.songid
            GROUP BY b.songid, s.decade;

            DROP TABLE IF EXISTS decadesrank;
            
             
            SELECT COALESCE(avg(rank), 0) into avgrank FROM bilboard b WHERE b.songid = realid;
            IF avgrank = 0 THEN
                score = 0;
            RETURN score;
            ElSE
                SELECT COALESCE(avg(rank), 0) into avgrankplayed FROM songsrank WHERE decade = samedecade;

                IF avgrankplayed = 0 THEN
                    score = 0;
                RETURN score;
                ELSE
                    IF avgrank - avgrankplayed = 0 THEN
                        score = 0;
                    RETURN score;
                    END IF;
                    score = 1.0 / abs(avgrank -avgrankplayed);
                    RETURN score;
                END IF;
            END IF;
        END IF;
    
    END;
    $rs$ LANGUAGE plpgsql;

    -- The function which is to calculate ss score

    CREATE OR REPLACE FUNCTION ss(realid BIGINT)
    RETURNS FLOAT AS $ss$
    DECLARE
        score float;
        realenergy float;
        realliveness float;
        realacoustincness float;

        avgenergy float;
        avgliveness float;
        avgacoustincness float;

        denominator float;
    BEGIN
        SELECT s.energy, s.liveness, s.acousticness INTO realenergy, realliveness, realacoustincness FROM songs s WHERE id = realid; 
        IF realenergy IS NULL OR realliveness IS NULL OR realacoustincness IS NULL THEN
            score = 0;
        RETURN score;
        END IF;

        SELECT avg(energy), avg(liveness), avg(acousticness) INTO avgenergy, avgliveness, avgacoustincness FROM songs s, songsplayed sp
        WHERE s.id = sp.songid;

        IF avgenergy IS NULL OR avgliveness IS NULL OR avgacoustincness IS NULL THEN
            score = 0;
        RETURN score;
        END IF;

        denominator = abs(realenergy - avgenergy) + abs(realliveness - avgliveness) + abs(realacoustincness - avgacoustincness);
        IF denominator = 0 THEN
            score = 0;
        RETURN score;
        END IF;

        score = 1 / denominator;
        RETURN score;
    END;
    $ss$ LANGUAGE plpgsql;

   FOR myrow IN SELECT s.id as songid
                       , s.name as songname
		       , a.name as artistname
		       , (w1 * gs(s.id)) + (w2 * rs(s.id)) + (w3 * ss(s.id)) as songscore
         FROM songs s, artists a, songsnosuchtime snp
         WHERE s.artistid = a.id AND snp.songid = s.id
         ORDER BY songscore DESC, songname ASC
	 LIMIT topk
   LOOP
       RETURN NEXT myrow ;
   END LOOP ;
   DROP TABLE IF EXISTS songsplayed;
   DROP TABLE IF EXISTS songsnosuchtime;
   DROP TABLE IF EXISTS songsrank;
   DROP TABLE IF EXISTS decadesrank;
   DROP FUNCTION IF EXISTS gs(BIGINT);
   DROP FUNCTION IF EXISTS rs(BIGINT);
   DROP FUNCTION IF EXISTS ss(BIGINT);
   RETURN ;

END ;
$recommendation$ LANGUAGE plpgsql;
